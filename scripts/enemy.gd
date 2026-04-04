extends CharacterBody2D
## Basic enemy: chases the player, deals contact damage.

signal enemy_killed(points: int)

const SPEED := 120.0
const DAMAGE := 1
const POINT_VALUE := 100
const KNOCKBACK_FORCE := 300.0
const FLASH_TIME := 0.1

var hp := 2
var target: Node2D = null
var is_dying := false
var knockback_velocity := Vector2.ZERO

@onready var sprite: Polygon2D = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape
@onready var hitbox: Area2D = $Hitbox


func _ready() -> void:
	hitbox.body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if is_dying:
		return

	# Decay knockback over time.
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 800.0 * delta)

	if target and is_instance_valid(target):
		var direction := (target.global_position - global_position).normalized()
		velocity = direction * SPEED + knockback_velocity

		# Face the player -- flip sprite horizontally.
		if direction.x < 0:
			sprite.scale.x = -1.0
		elif direction.x > 0:
			sprite.scale.x = 1.0
	else:
		velocity = knockback_velocity

	move_and_slide()


func set_target(new_target: Node2D) -> void:
	target = new_target


func take_damage(amount: int, source_pos: Vector2 = Vector2.ZERO) -> void:
	if is_dying:
		return
	hp -= amount

	# Knockback away from the damage source.
	if source_pos != Vector2.ZERO:
		knockback_velocity = (global_position - source_pos).normalized() * KNOCKBACK_FORCE

	# Flash white briefly.
	sprite.color = Color.WHITE
	var tween := create_tween()
	tween.tween_property(sprite, "color", Color(0.86, 0.27, 0.37), FLASH_TIME)

	if hp <= 0:
		_die()


func _die() -> void:
	is_dying = true
	collision_shape.set_deferred("disabled", true)
	enemy_killed.emit(POINT_VALUE)

	# Shrink + fade death animation.
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.25)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(queue_free)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and body.is_in_group("player"):
		body.take_damage(DAMAGE, global_position)
