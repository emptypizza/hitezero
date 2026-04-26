extends Node2D
class_name Knife

const GameConstants = preload("res://scripts/game_constants.gd")
const TEX_KNIFE: Texture2D = preload("res://assets/textures/knife/knife.png")

var velocity := Vector2.ZERO
var radius: float = GameConstants.KNIFE_RADIUS
var is_small: bool = false
var active: bool = true

@onready var blade: Sprite2D = $Blade


func _ready() -> void:
	blade.texture = TEX_KNIFE
	blade.centered = true
	blade.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func configure(start_pos: Vector2, new_velocity: Vector2, small: bool = false) -> void:
	position = start_pos
	velocity = new_velocity
	is_small = small
	active = true
	visible = true
	var s := 0.68 if is_small else 1.0
	blade.scale = Vector2(s, s)
	_sync_rotation()


func step(delta: float) -> void:
	if not active:
		return
	position += velocity * delta
	_sync_rotation()


func set_velocity(new_velocity: Vector2) -> void:
	velocity = new_velocity
	_sync_rotation()


func deactivate() -> void:
	active = false
	visible = false
	velocity = Vector2.ZERO


func speed() -> float:
	return velocity.length()


func _sync_rotation() -> void:
	rotation = velocity.angle() + PI * 0.5
