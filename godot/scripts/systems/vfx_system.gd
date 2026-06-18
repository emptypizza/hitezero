extends RefCounted
# Particle/juice subsystem extracted from game_root.gd (refactor Slice 3).
#
# Owns the pure draw-call particle systems: impact bursts, vfx particles
# (sparks/rings/starbursts/bubbles/streaks), ambient background motes, fireflies,
# and the coin-shard loot. game_root drives spawn/update explicitly and calls the
# draw_*_into(ci) helpers from its own _draw() in the unchanged order, so the
# single-canvas layering is preserved.
#
# NOTE: screen/camera/time effects (shake, zoom, flash, vignette, hit-stop) stay
# in game_root — they manage CanvasLayer nodes and the world transform, a
# different structural layer, and are deliberately NOT part of this cut.
#
# Coupling is light: only _game.level (bg hue), _game.paddle_x/paddle_y (coin
# magnet target), and _game.hud (score punch on collect). Behaviour is identical
# to the former in-game_root version. The golden trace covers the coin path
# (coin_shards_count is serialized); the other particles are draw-only and are
# verified by the windowed visual smoke (tools/smoke_item_draw.gd pattern).

const GameConstants = preload("res://scripts/game_constants.gd")

const BUBBLE_COLOR_CORE := Color(0.45, 0.93, 1.0)
const BUBBLE_COLOR_EDGE := Color(0.78, 0.99, 1.0)
const _BG_PARTICLE_MAX := 45
const _BG_SPAWN_INTERVAL := 0.07
const _FIREFLY_MAX := 12
const _FIREFLY_SPAWN_INTERVAL := 0.9

var _game  # game_root (untyped to avoid a circular preload)

var impact_bursts: Array[Dictionary] = []
var vfx_particles: Array[Dictionary] = []
var bg_particles: Array[Dictionary] = []
var _bg_spawn_acc: float = 0.0
var firefly_particles: Array[Dictionary] = []
var _firefly_spawn_acc: float = 0.0
var coin_shards: Array[Dictionary] = []  # kill-chain loot: scatter → magnet
var _coin_streak: int = 0                # rising collect-tick pitch


func _init(game) -> void:
	_game = game


func reset() -> void:
	# Matches the exact set game_root._start_new_run() used to clear, so the
	# extraction stays behaviour-neutral (fireflies + accumulators were ambient
	# and intentionally persisted across runs).
	impact_bursts.clear()
	vfx_particles.clear()
	bg_particles.clear()
	coin_shards.clear()
	_coin_streak = 0


# ─── Impact bursts ───────────────────────────────────────────────────────────

func burst_feedback(at: Vector2, color: Color, radius: float, life: float) -> void:
	impact_bursts.append({
		"position": at,
		"color": color,
		"radius": radius,
		"life": life,
		"max_life": life,
	})


func update_bursts(delta: float) -> void:
	for index in range(impact_bursts.size() - 1, -1, -1):
		var burst: Dictionary = impact_bursts[index]
		burst["life"] = float(burst["life"]) - delta
		if float(burst["life"]) <= 0.0:
			impact_bursts.remove_at(index)
		else:
			impact_bursts[index] = burst


func draw_bursts_into(ci: CanvasItem) -> void:
	for burst in impact_bursts:
		var life := float(burst["life"])
		var max_life := float(burst["max_life"])
		var t := life / max_life
		var radius := lerpf(float(burst["radius"]), float(burst["radius"]) + 12.0, 1.0 - t)
		var color: Color = burst["color"]
		color.a = 0.6 * t
		ci.draw_circle(burst["position"], radius, color)


# ─── VFX particles (sparks / rings / starbursts / bubbles / streaks) ─────────

func spawn_destroy_vfx(pos: Vector2, block_type: String) -> void:
	match block_type:
		GameConstants.BLOCK_NORMAL:
			vfx_sparks(pos, 10, Color(0.25, 0.72, 1.0), Color(0.75, 0.96, 1.0), 80.0, 160.0, 0.36)
		GameConstants.BLOCK_POW:
			vfx_ring(pos, Color(1.0, 0.08, 1.0, 0.88), 0.46)
			vfx_ring(pos, Color(1.0, 1.0, 1.0, 0.52), 0.30)
			vfx_sparks(pos, 14, Color(1.0, 0.28, 1.0), Color(1.0, 0.88, 1.0), 100.0, 220.0, 0.40)
		GameConstants.BLOCK_STAR:
			vfx_sparks(pos, 12, Color(1.0, 0.72, 0.0), Color(1.0, 0.98, 0.55), 60.0, 130.0, 0.50)
			vfx_starburst(pos, Color(1.0, 0.95, 0.42, 0.92), 0.38)
		GameConstants.BLOCK_RED_ENEMY:
			vfx_ring(pos, Color(0.92, 0.12, 0.20, 0.72), 0.36)
			vfx_sparks(pos, 10, Color(0.92, 0.18, 0.18), Color(1.0, 0.68, 0.38), 90.0, 180.0, 0.38)


func spawn_hit_vfx(pos: Vector2, color: Color) -> void:
	vfx_sparks(pos, 4, color, color.lerp(Color.WHITE, 0.4), 36.0, 76.0, 0.18)


# VX-03: cyan bubble-pop on elite/boss kills (duckflock ph.4). Elite (RED_ENEMY)
# and boss deaths get a burst of buoyant cyan bubbles on top of the regular
# destroy VFX, marking them as a tier above normal block kills.
func spawn_bubble_pop(pos: Vector2, big: bool = false) -> void:
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
	vfx_ring(pos, ring_color, 0.42 if big else 0.30)


func vfx_sparks(pos: Vector2, count: int, color_a: Color, color_b: Color,
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


func spawn_impact_sparks(pos: Vector2, dir: Vector2, color: Color) -> void:
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


func vfx_ring(pos: Vector2, color: Color, life: float) -> void:
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


func vfx_starburst(pos: Vector2, color: Color, life: float) -> void:
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


func update_particles(delta: float) -> void:
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


func draw_particles_into(ci: CanvasItem) -> void:
	for p in vfx_particles:
		var life := float(p["life"])
		var max_life := float(p["max_life"])
		var t := clampf(life / max_life, 0.0, 1.0)
		var pos := Vector2(float(p["x"]), float(p["y"]))
		var color: Color = p["color"]
		color.a *= t
		match p.get("shape", "circle"):
			"circle":
				ci.draw_circle(pos, maxf(0.5, float(p["radius"]) * (0.55 + 0.45 * t)), color)
			"ring":
				var r := float(p["radius"])
				if r > 0.5:
					ci.draw_arc(pos, r, 0.0, TAU, 24, color, maxf(1.0, 3.2 * t))
			"star":
				var sz := float(p["radius"]) * t
				ci.draw_line(pos - Vector2(sz, 0.0), pos + Vector2(sz, 0.0), color, 2.0)
				ci.draw_line(pos - Vector2(0.0, sz), pos + Vector2(0.0, sz), color, 2.0)
				var d := sz * 0.68
				ci.draw_line(pos - Vector2(d, d), pos + Vector2(d, d), color, 1.5)
				ci.draw_line(pos + Vector2(-d, d), pos - Vector2(-d, d), color, 1.5)
				continue
			"streak":
				var vel := Vector2(float(p["vx"]), float(p["vy"]))
				var dir := vel.normalized() if vel.length_squared() > 0.001 else Vector2.RIGHT
				var sl := float(p["radius"]) * (0.6 + 0.8 * t)
				var tip := pos + dir * sl
				ci.draw_line(pos, tip, color, maxf(1.0, 2.6 * t))
			"bubble":
				# Thin shell that swells as it dies — reads as a pop, not a fade.
				var br := float(p["radius"]) * (1.0 + (1.0 - t) * 0.45)
				ci.draw_arc(pos, br, 0.0, TAU, 14, color, 1.4)
				var hl := color
				hl.a = color.a * 0.9
				ci.draw_circle(pos + Vector2(-br * 0.35, -br * 0.35), maxf(0.6, br * 0.22), hl)


# ─── Background particles ────────────────────────────────────────────────────

func bg_particle_color() -> Color:
	match (_game.level - 1) % 4:
		0: return Color(0.0, 0.85, 1.0)
		1: return Color(0.65, 0.25, 1.0)
		2: return Color(1.0, 0.55, 0.15)
		_: return Color(1.0, 0.25, 0.85)


func spawn_bg_particle() -> void:
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
		"color": bg_particle_color(),
	})


func update_bg(delta: float) -> void:
	_bg_spawn_acc += delta
	while _bg_spawn_acc >= _BG_SPAWN_INTERVAL:
		_bg_spawn_acc -= _BG_SPAWN_INTERVAL
		spawn_bg_particle()
	for i in range(bg_particles.size() - 1, -1, -1):
		var p: Dictionary = bg_particles[i]
		p["y"] = float(p["y"]) + float(p["vy"]) * delta
		p["x"] = float(p["x"]) + float(p["vx"]) * delta
		p["life"] = float(p["life"]) - delta
		if float(p["y"]) > GameConstants.CANVAS_HEIGHT + 10.0 or float(p["life"]) <= 0.0:
			bg_particles.remove_at(i)
		else:
			bg_particles[i] = p


func draw_bg_into(ci: CanvasItem) -> void:
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
		ci.draw_circle(Vector2(float(p["x"]), float(p["y"])), float(p["radius"]), color)


# ─── Coin shards: every destroy is a loot moment (scatter → magnet → tick) ──

func spawn_coin_shards(at: Vector2, block_type: String) -> void:
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


func update_coins(delta: float) -> void:
	if coin_shards.is_empty():
		if _coin_streak != 0:
			_coin_streak = 0
		return
	var target := Vector2(_game.paddle_x, _game.paddle_y - GameConstants.PADDLE_Y_OFFSET * 0.5)
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
				on_coin_collected(pos)
			continue
		coin_shards[i] = s


func on_coin_collected(at: Vector2) -> void:
	_coin_streak += 1
	# Rising tick pitch per pickup — the reference's gem-vacuum sparkle.
	AudioManager.play("ui_click", 1.0 + 0.06 * float(mini(_coin_streak, 10)), -4.0)
	burst_feedback(at, GameConstants.GLOW_REWARD, 7.0, 0.10)
	_game.hud.punch_score()


func draw_coins_into(ci: CanvasItem) -> void:
	for s in coin_shards:
		var pos := Vector2(float(s["x"]), float(s["y"]))
		var r := float(s["radius"])
		var spin := float(s["spin"]) + float(s["age"]) * 9.0
		# Spinning diamond: width oscillates to fake a coin flip.
		var w := absf(cos(spin)) * r + 0.6
		var glow := Color(GameConstants.GLOW_REWARD.r, GameConstants.GLOW_REWARD.g, GameConstants.GLOW_REWARD.b, 0.22)
		ci.draw_circle(pos, r + 2.4, glow)
		var pts := PackedVector2Array([
			pos + Vector2(0.0, -r), pos + Vector2(w, 0.0),
			pos + Vector2(0.0, r), pos + Vector2(-w, 0.0),
		])
		ci.draw_colored_polygon(pts, GameConstants.GLOW_REWARD)
		ci.draw_circle(pos + Vector2(-w * 0.25, -r * 0.3), r * 0.3, Color(1.0, 1.0, 1.0, 0.85))


# ─── Fireflies (reference night-stage ambience) ──────────────────────────────

func spawn_firefly() -> void:
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


func update_fireflies(delta: float) -> void:
	_firefly_spawn_acc += delta
	while _firefly_spawn_acc >= _FIREFLY_SPAWN_INTERVAL:
		_firefly_spawn_acc -= _FIREFLY_SPAWN_INTERVAL
		spawn_firefly()
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


func draw_fireflies_into(ci: CanvasItem) -> void:
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
		ci.draw_circle(pos, r + 2.0, halo)
		ci.draw_circle(pos, r, color)
