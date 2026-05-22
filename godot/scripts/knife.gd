extends Node2D
class_name Knife

const GameConstants = preload("res://scripts/game_constants.gd")
const TEX_KNIFE: Texture2D = preload("res://assets/textures/knife/knife.png")
const TRAIL_MAX_POINTS := 8
const TRAIL_OUTLINE_COLOR := Color(0.03, 0.04, 0.08, 0.58)
const TRAIL_CORE_COLOR := Color(1.0, 0.88, 0.36, 0.78)
const TRAIL_MINI_CORE_COLOR := Color(0.35, 0.92, 1.0, 0.68)

var velocity := Vector2.ZERO
var radius: float = GameConstants.KNIFE_RADIUS
var is_small: bool = false
var active: bool = true
var trail_points: Array[Vector2] = []

@onready var blade: Sprite2D = $Blade


func _ready() -> void:
	blade.texture = TEX_KNIFE
	blade.centered = true
	blade.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _draw() -> void:
	_draw_trail()


func configure(start_pos: Vector2, new_velocity: Vector2, small: bool = false) -> void:
	position = start_pos
	velocity = new_velocity
	is_small = small
	active = true
	visible = true
	trail_points.clear()
	trail_points.append(global_position)
	var s := 0.68 if is_small else 1.0
	blade.scale = Vector2(s, s)
	_sync_rotation()
	queue_redraw()


func step(delta: float) -> void:
	if not active:
		return
	trail_points.append(global_position)
	position += velocity * delta
	trail_points.append(global_position)
	_trim_trail_points()
	_sync_rotation()
	queue_redraw()


func set_velocity(new_velocity: Vector2) -> void:
	velocity = new_velocity
	_sync_rotation()


func deactivate() -> void:
	active = false
	visible = false
	velocity = Vector2.ZERO
	trail_points.clear()
	queue_redraw()


func speed() -> float:
	return velocity.length()


func _sync_rotation() -> void:
	rotation = velocity.angle() + PI * 0.5


func _trim_trail_points() -> void:
	var max_points := TRAIL_MAX_POINTS - 1 if is_small else TRAIL_MAX_POINTS
	while trail_points.size() > max_points:
		trail_points.remove_at(0)


func _draw_trail() -> void:
	if not active or trail_points.size() < 2:
		return
	var base_core := TRAIL_MINI_CORE_COLOR if is_small else TRAIL_CORE_COLOR
	for index in range(1, trail_points.size()):
		var fade := float(index) / float(maxi(1, trail_points.size() - 1))
		var width_mul := 0.72 if is_small else 1.0
		var alpha_mul := 0.52 if is_small else 1.0
		var p0 := to_local(trail_points[index - 1])
		var p1 := to_local(trail_points[index])
		var outline := TRAIL_OUTLINE_COLOR
		outline.a *= fade * alpha_mul
		var core := base_core
		core.a *= fade * alpha_mul
		var glow := Color(core.r, core.g, core.b, core.a * 0.28)
		draw_line(p0, p1, glow, 9.0 * width_mul)
		draw_line(p0, p1, outline, 5.2 * width_mul)
		draw_line(p0, p1, core, 2.2 * width_mul)
