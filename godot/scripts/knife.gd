extends Node2D
class_name Knife

const GameConstants = preload("res://scripts/game_constants.gd")

var velocity := Vector2.ZERO
var radius: float = GameConstants.KNIFE_RADIUS
var is_small: bool = false
var active: bool = true


func configure(start_pos: Vector2, new_velocity: Vector2, small: bool = false) -> void:
    position = start_pos
    velocity = new_velocity
    is_small = small
    active = true
    visible = true
    _sync_rotation()
    queue_redraw()


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


func _draw() -> void:
    var scale_factor := 0.68 if is_small else 1.0
    var blade := PackedVector2Array([
        Vector2(0.0, -12.0) * scale_factor,
        Vector2(4.0, 1.0) * scale_factor,
        Vector2(-4.0, 1.0) * scale_factor,
    ])
    draw_colored_polygon(blade, Color(0.88, 0.90, 0.94, 1.0))
    draw_line(Vector2(0.0, -10.0) * scale_factor, Vector2(0.0, 0.0) * scale_factor, Color(1.0, 1.0, 1.0, 0.55), 1.5)
    draw_rect(Rect2(Vector2(-5.0, 1.0) * scale_factor, Vector2(10.0, 2.0) * scale_factor), Color(0.30, 0.34, 0.42, 1.0), true)
    draw_rect(Rect2(Vector2(-2.0, 3.0) * scale_factor, Vector2(4.0, 7.0) * scale_factor), Color(0.57, 0.25, 0.05, 1.0), true)


func _sync_rotation() -> void:
    rotation = velocity.angle() + PI * 0.5
