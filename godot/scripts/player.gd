extends Node2D
class_name Player

const GameConstants = preload("res://scripts/game_constants.gd")
const TEX_TRAY: Texture2D = preload("res://assets/textures/player/tray.png")
const TEX_KNIFE: Texture2D = preload("res://assets/textures/knife/knife.png")

const TEX_IDLE_FRAMES = [
	preload("res://assets/textures/player/maid/idle_0.png"),
	preload("res://assets/textures/player/maid/idle_1.png"),
	preload("res://assets/textures/player/maid/idle_2.png"),
	preload("res://assets/textures/player/maid/idle_3.png"),
	preload("res://assets/textures/player/maid/idle_4.png"),
]
const TEX_ATTACK_FRAMES = [
	preload("res://assets/textures/player/maid/attack_0.png"),
	preload("res://assets/textures/player/maid/attack_1.png"),
	preload("res://assets/textures/player/maid/attack_2.png"),
	preload("res://assets/textures/player/maid/attack_3.png"),
	preload("res://assets/textures/player/maid/attack_4.png"),
]
const TEX_COMBAT_IDLE: Texture2D = preload("res://assets/textures/player/maid/combat_idle.png")
const TEX_GAMEOVER_DOWN: Texture2D = preload("res://assets/textures/player/maid/gameover_down.png")

# CEL-04: shared cel+rim material so the maid reads in the same render language
# as the blocks (banded shade + ink rim + stage rim light). Alpha-keyed in the
# shader, so the hand-drawn silhouette is untouched.
const CHARACTER_CEL_SHADER: Shader = preload("res://assets/shaders/character_cel.gdshader")
static var _character_material: ShaderMaterial = null

const IDLE_FRAME_ORDER = [0, 1, 2, 3, 4, 3, 2, 1]
const BASE_BODY_POSITION := Vector2(0.0, -33.0)
const BASE_TRAY_POSITION := Vector2(0.0, -78.0)
const MAID_TARGET_HEIGHT := 124.0
const OUTPUT_DURATION := 0.52
# Hot-flash window follows the duck-flock reference spec (GameConstants.FLASH_LIFE):
# muzzle glow lives 1–2 frames, the blade trail/particles carry the follow-through.
const OUTPUT_FLASH_TIME := 0.13
const OUTPUT_PARTICLE_COUNT := 18

# ─── Procedural anim rig (ANIM-01, 2026-06-13) ───────────────────────────────
# Layered ON TOP of the discrete maid frames so even the static combat-idle
# reads as alive and dimensional: ~0.55 Hz breathing bob + volume-preserving
# scale, throw squash→stretch (anticipation then release), an aim lean, and
# opposite-phase tray/secondary motion. Pure cosmetic transforms — the
# NemoInput-style aim/fire contract and collision are never touched.
const BREATH_HZ := 0.55
const BREATH_BOB_PX := 1.6
const BREATH_SCALE := 0.022      # peak +Y / -X breathing scale (volume-ish)
const THROW_SQUASH := 0.13       # anticipation compression
const THROW_STRETCH := 0.17      # release elongation
const AIM_LEAN_MAX := 0.16       # rad — lean toward the shot direction
const RIG_SMOOTH := 16.0         # transform follow speed (higher = snappier)

@onready var tray: Sprite2D = $Tray
@onready var body: Sprite2D = $Body
@onready var wait_root: Node2D = $WaitKnives
@onready var output_vfx: Node2D = $OutputVfx

var visual_state := "idle"
var waiting_knives: int = 3
var show_waiting_knives: bool = true
var show_tray: bool = true
var idle_time: float = 0.0
var output_elapsed: float = OUTPUT_DURATION
var output_angle: float = -PI * 0.5
var output_particles: Array[Dictionary] = []

# ANIM-01 smoothed rig state (eased toward targets every frame for buttery
# motion even though the underlying sprite frames are discrete).
var _rig_squash := Vector2.ONE
var _rig_lean: float = 0.0


func _ready() -> void:
	tray.texture = TEX_TRAY
	tray.centered = true
	tray.position = BASE_TRAY_POSITION
	tray.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.centered = true
	body.position = BASE_BODY_POSITION
	# CEL-04: apply the shared cel+rim material once; it persists across the
	# per-frame texture swaps in _refresh_visual().
	body.material = _get_character_material()
	if output_vfx != null and output_vfx.has_method("bind_player"):
		output_vfx.bind_player(self)
	_refresh_visual()
	_rebuild_wait_knives()


func _process(delta: float) -> void:
	idle_time += delta
	if _is_output_active():
		output_elapsed = minf(OUTPUT_DURATION, output_elapsed + delta)
	_update_output_particles(delta)
	_update_anim_rig(delta)
	_refresh_visual()
	_queue_output_vfx_redraw()


func _update_anim_rig(delta: float) -> void:
	# Resolve transform targets for this frame, then ease toward them so state
	# changes (e.g. a throw firing) ramp in instead of popping.
	var target_squash := Vector2.ONE
	var target_lean: float = 0.0
	if visual_state == "gameover":
		target_squash = Vector2(1.06, 0.94)   # settle, slumped
	elif _is_output_active():
		var st := clampf(output_elapsed / OUTPUT_DURATION, 0.0, 1.0)
		target_lean = clampf((output_angle + PI * 0.5) * 0.6, -AIM_LEAN_MAX, AIM_LEAN_MAX)
		if st < 0.22:
			var a := st / 0.22                 # anticipation → squash down
			target_squash = Vector2(1.0 + THROW_SQUASH * a, 1.0 - THROW_SQUASH * a)
		else:
			var rel := (st - 0.22) / 0.78
			var s := (1.0 - rel) * (1.0 - rel) # ease-out release → stretch up
			target_squash = Vector2(1.0 - THROW_STRETCH * s, 1.0 + THROW_STRETCH * s)
	var k := clampf(delta * RIG_SMOOTH, 0.0, 1.0)
	_rig_squash = _rig_squash.lerp(target_squash, k)
	_rig_lean = lerpf(_rig_lean, target_lean, k)


func set_state(new_state: String) -> void:
	visual_state = new_state
	_refresh_visual()


func set_waiting_knives(count: int, visible_now: bool) -> void:
	waiting_knives = count
	show_waiting_knives = visible_now
	_rebuild_wait_knives()


func play_output(shot_angle: float) -> void:
	output_angle = shot_angle
	output_elapsed = 0.0
	_spawn_output_particles()
	_refresh_visual()
	_queue_output_vfx_redraw()


static func _get_character_material() -> ShaderMaterial:
	if _character_material == null:
		_character_material = ShaderMaterial.new()
		_character_material.shader = CHARACTER_CEL_SHADER
	return _character_material


func _is_output_active() -> bool:
	return output_elapsed < OUTPUT_DURATION


func _select_body_texture():
	if visual_state == "gameover":
		return TEX_GAMEOVER_DOWN
	if _is_output_active():
		var attack_t := clampf(output_elapsed / OUTPUT_DURATION, 0.0, 0.999)
		var attack_index := mini(TEX_ATTACK_FRAMES.size() - 1, int(floor(attack_t * float(TEX_ATTACK_FRAMES.size()))))
		return TEX_ATTACK_FRAMES[attack_index]
	match visual_state:
		"throw", "hit":
			return TEX_COMBAT_IDLE
		_:
			var order_index := int(floor(idle_time * 7.0)) % IDLE_FRAME_ORDER.size()
			var idle_index: int = IDLE_FRAME_ORDER[order_index]
			return TEX_IDLE_FRAMES[idle_index]


func _fit_body_scale() -> void:
	if body.texture == null:
		return
	var ts := body.texture.get_size()
	if ts.y < 1.0 or ts.x < 1.0:
		return
	var raw_scale: float
	if ts.y > 120.0:
		raw_scale = MAID_TARGET_HEIGHT / ts.y
	else:
		raw_scale = 56.0 / ts.x
	body.scale = Vector2(raw_scale, raw_scale)


func _sync_body_texture_filter() -> void:
	if body.texture == null:
		return
	var ts := body.texture.get_size()
	body.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if ts.y > 120.0 else CanvasItem.TEXTURE_FILTER_NEAREST


func _refresh_visual() -> void:
	if body == null:
		return
	body.texture = _select_body_texture()
	_fit_body_scale()
	_sync_body_texture_filter()
	body.flip_h = (visual_state == "throw" or _is_output_active()) and output_angle < -PI * 0.5

	# ANIM-01: breathing (continuous) × throw squash (eased) on top of the
	# fitted scale; lean rotation; bob + opposite-phase tray secondary motion.
	var breath := sin(idle_time * TAU * BREATH_HZ)
	var breath_scale := Vector2(1.0 - breath * BREATH_SCALE * 0.5, 1.0 + breath * BREATH_SCALE)
	body.scale *= _rig_squash * breath_scale
	body.rotation = _rig_lean
	var bob := Vector2(0.0, -absf(breath) * BREATH_BOB_PX)   # rise on the inhale
	body.position = BASE_BODY_POSITION + _output_recoil_offset() + bob
	tray.position = BASE_TRAY_POSITION + Vector2(0.0, absf(breath) * BREATH_BOB_PX * 0.55)
	tray.rotation = -_rig_lean * 0.4

	var base_body_color := Color.WHITE
	var base_tray_color := Color.WHITE
	match visual_state:
		"gameover":
			base_body_color = Color(0.62, 0.64, 0.70, 1.0)
			base_tray_color = Color(0.75, 0.75, 0.80, 0.55)
		"hit":
			base_body_color = Color(1.0, 0.52, 0.52, 1.0)
		"clear":
			base_body_color = Color(0.72, 1.0, 0.82, 1.0)
		"throw":
			base_body_color = Color(0.97, 0.97, 1.0, 1.0)
		_:
			base_body_color = Color.WHITE

	if _is_output_active():
		var flash := maxf(0.0, 1.0 - output_elapsed / OUTPUT_FLASH_TIME)
		base_body_color = base_body_color.lerp(Color(1.0, 0.94, 0.98, 1.0), flash * 0.48)
		base_tray_color = base_tray_color.lerp(Color(1.0, 0.96, 0.72, 1.0), flash * 0.55)
	body.modulate = base_body_color
	tray.modulate = base_tray_color
	tray.visible = show_tray and visual_state != "gameover"


func _output_recoil_offset() -> Vector2:
	if not _is_output_active():
		return Vector2.ZERO
	var t := clampf(output_elapsed / OUTPUT_DURATION, 0.0, 1.0)
	var dir := Vector2(cos(output_angle), sin(output_angle))
	var recoil := pow(1.0 - t, 2.0) * 6.0
	return -dir * recoil


func _get_muzzle_origin() -> Vector2:
	# Match GameRoot._spawn_knife(): knife starts at player local Y = -PADDLE_Y_OFFSET.
	# Keeping the VFX origin on this exact point makes the flash read as coming
	# from the maid/tray instead of floating separately above her.
	var dir := Vector2(cos(output_angle), sin(output_angle))
	return Vector2(0.0, -GameConstants.PADDLE_Y_OFFSET) + dir * 2.0


func _spawn_output_particles() -> void:
	output_particles.clear()
	var dir := Vector2(cos(output_angle), sin(output_angle))
	var side := Vector2(-dir.y, dir.x)
	var muzzle := _get_muzzle_origin()
	for i in range(OUTPUT_PARTICLE_COUNT):
		var denom := maxi(1, OUTPUT_PARTICLE_COUNT - 1)
		var spread := -1.0 + 2.0 * float(i) / float(denom)
		var max_life := randf_range(0.12, 0.26)
		var sparkle_color := Color(1.0, 0.83, 0.30, 1.0) if i % 3 == 0 else Color(1.0, 0.66, 0.82, 1.0)
		output_particles.append({
			"pos": muzzle + side * spread * randf_range(2.0, 8.0) - dir * randf_range(0.0, 5.0),
			"vel": dir * randf_range(52.0, 104.0) + side * spread * randf_range(18.0, 48.0),
			"life": max_life,
			"max_life": max_life,
			"radius": randf_range(1.2, 2.8),
			"color": sparkle_color,
		})


func _update_output_particles(delta: float) -> void:
	for index in range(output_particles.size() - 1, -1, -1):
		var particle: Dictionary = output_particles[index]
		particle["life"] = float(particle["life"]) - delta
		if float(particle["life"]) <= 0.0:
			output_particles.remove_at(index)
		else:
			particle["pos"] = particle["pos"] + particle["vel"] * delta
			particle["vel"] = particle["vel"] * 0.82
			output_particles[index] = particle


func _queue_output_vfx_redraw() -> void:
	if output_vfx != null:
		output_vfx.queue_redraw()


func _draw_output_vfx(canvas: CanvasItem) -> void:
	if not _is_output_active() and output_particles.is_empty():
		return
	var dir := Vector2(cos(output_angle), sin(output_angle))
	var side := Vector2(-dir.y, dir.x)
	var muzzle := _get_muzzle_origin()
	if _is_output_active():
		var t := clampf(output_elapsed / OUTPUT_DURATION, 0.0, 1.0)
		var flash := maxf(0.0, 1.0 - output_elapsed / OUTPUT_FLASH_TIME)
		var trail_alpha := maxf(0.0, 1.0 - t * 0.82)
		var blade_tip := muzzle + dir * lerpf(38.0, 72.0, 1.0 - trail_alpha)
		var blade_tail := muzzle - dir * lerpf(6.0, 18.0, t)
		canvas.draw_line(blade_tail, blade_tip, Color(1.0, 1.0, 1.0, 0.92 * trail_alpha), 7.0)
		canvas.draw_line(blade_tail - side * 4.0, blade_tip - side * 4.0, Color(1.0, 0.58, 0.88, 0.54 * trail_alpha), 3.0)
		canvas.draw_line(blade_tail + side * 4.0, blade_tip + side * 4.0, Color(1.0, 0.91, 0.30, 0.62 * trail_alpha), 3.0)
		canvas.draw_circle(muzzle, 15.0 + 12.0 * flash, Color(1.0, 0.70, 0.18, 0.34 * flash))
		canvas.draw_circle(muzzle, 7.0 + 7.0 * flash, Color(1.0, 0.98, 0.80, 0.78 * flash))
		if flash > 0.0:
			_draw_star(canvas, muzzle + dir * 5.0, dir, side, 16.0 * flash, Color(1.0, 0.98, 0.82, 0.9 * flash))

	for particle in output_particles:
		var life := float(particle["life"])
		var max_life := float(particle["max_life"])
		var a := clampf(life / max_life, 0.0, 1.0)
		var color: Color = particle["color"]
		color.a *= a
		canvas.draw_circle(particle["pos"], float(particle["radius"]) * a, color)


func _draw_star(canvas: CanvasItem, center: Vector2, axis: Vector2, side: Vector2, size: float, color: Color) -> void:
	canvas.draw_line(center - axis * size, center + axis * size, color, 2.0 + size * 0.05)
	canvas.draw_line(center - side * size * 0.64, center + side * size * 0.64, color, 1.6 + size * 0.04)
	canvas.draw_line(center - (axis + side).normalized() * size * 0.45, center + (axis + side).normalized() * size * 0.45, color, 1.2)
	canvas.draw_line(center - (axis - side).normalized() * size * 0.45, center + (axis - side).normalized() * size * 0.45, color, 1.2)


func _rebuild_wait_knives() -> void:
	if wait_root == null:
		return
	for c in wait_root.get_children():
		c.queue_free()
	if not show_waiting_knives:
		return
	var count := mini(waiting_knives, 12)
	if count <= 0:
		return
	var spacing := 6.0
	var offset_x := -((float(count - 1) * spacing) * 0.5)
	for i in range(count):
		var ks := Sprite2D.new()
		ks.texture = TEX_KNIFE
		ks.centered = true
		ks.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ks.modulate = Color(1.0, 0.92, 0.64, 1.0)
		ks.scale = Vector2(0.35, 0.35)
		ks.position = Vector2(offset_x + float(i) * spacing, 0.0)
		wait_root.add_child(ks)
