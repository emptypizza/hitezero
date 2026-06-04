extends Node2D
class_name Block

const GameConstants = preload("res://scripts/game_constants.gd")
const TEX_BRICK: Texture2D = preload("res://assets/textures/blocks/brick.png")
const TEX_RED_ENEMY: Texture2D = preload("res://assets/textures/blocks/E1.webp")
const TEX_STAR_BLOCK: Texture2D = preload("res://assets/textures/blocks/S1.webp")
const TEX_POW_BLOCK: Texture2D = preload("res://assets/textures/blocks/P1.webp")
const TEX_STAR_OVERLAY: Texture2D = preload("res://assets/textures/ui/star.png")

@onready var block_sprite: Sprite2D = $BlockSprite
@onready var overlay_star: Sprite2D = $OverlayStar
@onready var pow_label: Label = $PowLabel

var label: Label

var block_type: String = GameConstants.BLOCK_NORMAL
var hp: int = 1
var max_hp: int = 1
var block_size := Vector2(GameConstants.BLOCK_WIDTH - 4.0, GameConstants.BLOCK_HEIGHT - 4.0)
var enemy_speed: float = 0.0
var enemy_active: bool = false
var flash_amount: float = 0.0

# ─── Squash & stretch (visual only — never touches collision AABB) ───────────
# Applied to the child Sprite2D so global_position / block_size stay intact and
# gameplay/collision remain deterministic. Decays to rest over SQUASH_TIME.
const SQUASH_TIME := 0.12        # seconds to recover
const SQUASH_STRENGTH := 0.34    # compression along impact axis at full hit
const SQUASH_STRETCH := 0.55     # how much of the squash goes into the cross axis
const KNOCKBACK_DIST := 4.0      # px the sprite recoils along impact dir
var _squash_t: float = 0.0       # 1 → 0 over the recovery window
var _impact_dir := Vector2.ZERO  # unit impact direction in local space

var _base_modulate: Color = Color.WHITE


func _ready() -> void:
	_ensure_label()
	z_index = 3
	block_sprite.centered = true
	block_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	overlay_star.texture = TEX_STAR_OVERLAY
	overlay_star.centered = true
	overlay_star.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	overlay_star.visible = false
	_setup_pow_label()
	_sync_label()
	_sync_overlays()
	_apply_block_visual()


func _draw() -> void:
	pass



func _process(delta: float) -> void:
	if flash_amount > 0.0:
		flash_amount = maxf(0.0, flash_amount - delta * 4.0)
	if _squash_t > 0.0:
		_squash_t = maxf(0.0, _squash_t - delta / SQUASH_TIME)
	_update_sprite_modulate()
	_update_sprite_scale()


func configure(new_type: String, new_hp: int, new_max_hp: int, new_size: Vector2) -> void:
	block_type = new_type
	hp = new_hp
	max_hp = new_max_hp
	block_size = new_size
	enemy_speed = 30.0 + float(hp) * 2.0 if block_type == GameConstants.BLOCK_RED_ENEMY else 0.0
	enemy_active = false
	_sync_label()
	_sync_overlays()
	_apply_block_visual()
	queue_redraw()


func activate_enemy_motion() -> void:
	if block_type == GameConstants.BLOCK_RED_ENEMY:
		enemy_active = true


func advance_enemy(delta: float) -> void:
	if enemy_active and block_type == GameConstants.BLOCK_RED_ENEMY:
		position.y += enemy_speed * delta


func take_hit(impact_dir: Vector2 = Vector2.ZERO) -> int:
	hp = maxi(0, hp - 1)
	flash_amount = 1.0
	# Kick off a directional squash & stretch. Blocks aren't rotated, so the
	# local impact direction equals the world direction we're handed.
	if impact_dir.length_squared() > 0.0001:
		_impact_dir = impact_dir.normalized()
		_squash_t = 1.0
	_sync_label()
	queue_redraw()
	return hp


func is_destroyed() -> bool:
	return hp <= 0


func get_aabb() -> Rect2:
	return Rect2(global_position - block_size * 0.5, block_size)


# World-local AABB (relative to the parent layer, which sits at the world
# origin). Collision compares this against knife.position — also world-local —
# so a shaking/rotating/zooming `world` node never shifts the hit boxes.
func get_local_aabb() -> Rect2:
	return Rect2(position - block_size * 0.5, block_size)


func get_hit_color() -> Color:
	match block_type:
		GameConstants.BLOCK_NORMAL:
			return Color(0.30, 0.78, 1.0, 1.0)
		GameConstants.BLOCK_STAR:
			return Color(1.0, 0.80, 0.24, 1.0)
		GameConstants.BLOCK_POW:
			return Color(1.0, 0.0, 1.0, 1.0)
		GameConstants.BLOCK_RED_ENEMY:
			return Color(0.94, 0.27, 0.27, 1.0)
		_:
			return Color(1.0, 1.0, 1.0, 1.0)


func _setup_pow_label() -> void:
	pow_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pow_label.text = "POW"
	pow_label.add_theme_font_size_override("font_size", 11)
	pow_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.95, 1.0))
	pow_label.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08, 1.0))
	pow_label.add_theme_constant_override("outline_size", 6)


func _sync_label() -> void:
	_ensure_label()
	if label == null:
		return
	label.position = Vector2(-block_size.x * 0.5, -12.0)
	label.size = Vector2(block_size.x, 24.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.visible = block_type == GameConstants.BLOCK_NORMAL
	label.text = str(hp)
	label.modulate = Color(0.08, 0.08, 0.08, 1.0)
	label.z_index = 4


func _sync_overlays() -> void:
	if overlay_star != null:
		overlay_star.visible = false
	if pow_label != null:
		pow_label.visible = false


func _ensure_label() -> void:
	if label == null:
		label = get_node_or_null("Label") as Label


func _apply_block_visual() -> void:
	if block_sprite == null:
		return
	match block_type:
		GameConstants.BLOCK_RED_ENEMY:
			block_sprite.texture = TEX_RED_ENEMY
			_base_modulate = Color.WHITE
		GameConstants.BLOCK_STAR:
			block_sprite.texture = TEX_STAR_BLOCK
			_base_modulate = Color.WHITE
		GameConstants.BLOCK_POW:
			block_sprite.texture = TEX_POW_BLOCK
			_base_modulate = Color.WHITE
		_:
			block_sprite.texture = TEX_BRICK
			_base_modulate = Color.WHITE
	_update_sprite_modulate()
	_update_sprite_scale()
	queue_redraw()


func _update_sprite_scale() -> void:
	if block_sprite == null or block_sprite.texture == null:
		return
	var ts := block_sprite.texture.get_size()
	if ts.x < 1.0 or ts.y < 1.0:
		return
	var base_scale := Vector2(block_size.x / ts.x, block_size.y / ts.y)
	if block_type == GameConstants.BLOCK_RED_ENEMY and enemy_active:
		# Subtle breathing keeps the falling blob alive without adding non-red pixels.
		var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.008) * 0.035
		base_scale *= pulse
	block_sprite.scale = base_scale * _squash_scale()
	block_sprite.position = _impact_dir * (KNOCKBACK_DIST * _squash_t)


func _squash_scale() -> Vector2:
	# Eased squash: compress along the impact axis, bulge the cross axis.
	if _squash_t <= 0.0:
		return Vector2.ONE
	var e := _squash_t * _squash_t  # ease-out so recovery snaps then settles
	var k := SQUASH_STRENGTH * e
	if absf(_impact_dir.x) >= absf(_impact_dir.y):
		return Vector2(1.0 - k, 1.0 + k * SQUASH_STRETCH)
	return Vector2(1.0 + k * SQUASH_STRETCH, 1.0 - k)


func _update_sprite_modulate() -> void:
	if block_sprite == null:
		return
	if flash_amount > 0.0:
		var w := minf(0.65, flash_amount * 0.55)
		block_sprite.modulate = _base_modulate.lerp(_flash_target_color(), w)
	else:
		block_sprite.modulate = _base_modulate


func _flash_target_color() -> Color:
	if block_type == GameConstants.BLOCK_RED_ENEMY:
		# Hit feedback stays red-hued; never flash the enemy to white/pink.
		return Color(1.35, 0.0, 0.0, 1.0)
	return Color(1.0, 1.0, 1.0, 1.0)
