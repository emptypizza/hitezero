extends CharacterBody2D
## Player controller: WASD/arrow movement, space/click to attack.
## Emits signals for health changes and death so the HUD and game scene can react.

signal health_changed(current_hp: int, max_hp: int)
signal player_died

const SPEED := 300.0
const MAX_HP := 5
const ATTACK_COOLDOWN := 0.4
const INVINCIBILITY_TIME := 1.0
const KNOCKBACK_FORCE := 400.0

var hp: int = MAX_HP
var hits_taken: int = 0
var is_attacking := false
var can_attack := true
var is_invincible := false
var facing := Vector2.RIGHT

@onready var sprite: Polygon2D = $Sprite
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/AttackShape
@onready var attack_visual: Polygon2D = $AttackArea/AttackVisual
@onready var collision_shape: CollisionShape2D = $CollisionShape
@onready var invincibility_timer: Timer = $InvincibilityTimer
@onready var attack_timer: Timer = $AttackTimer
@onready var attack_duration_timer: Timer = $AttackDurationTimer
@onready var hurtbox: Area2D = $Hurtbox


func _ready() -> void:
	hp = MAX_HP
	hits_taken = 0
	attack_visual.visible = false
	attack_shape.disabled = true

	invincibility_timer.wait_time = INVINCIBILITY_TIME
	invincibility_timer.one_shot = true
	invincibility_timer.timeout.connect(_on_invincibility_timeout)

	attack_timer.wait_time = ATTACK_COOLDOWN
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_cooldown_timeout)

	attack_duration_timer.wait_time = 0.15
	attack_duration_timer.one_shot = true
	attack_duration_timer.timeout.connect(_on_attack_duration_timeout)

	attack_area.body_entered.connect(_on_attack_hit)

	health_changed.emit(hp, MAX_HP)


func _physics_process(delta: float) -> void:
	# -- movement --
	var input_dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if input_dir.length() > 0.0:
		input_dir = input_dir.normalized()
		facing = input_dir

	velocity = input_dir * SPEED
	move_and_slide()

	# Keep player inside the arena (viewport-sized play area at world origin).
	# The arena is 1280x720 centered at (640, 360).
	global_position = global_position.clamp(
		Vector2(16, 16),
		Vector2(1264, 704)
	)

	# Rotate attack area to face movement direction.
	attack_area.rotation = facing.angle()

	# Update sprite color during invincibility (flash effect).
	if is_invincible:
		sprite.color.a = 0.4 + 0.6 * abs(sin(Time.get_ticks_msec() * 0.01))
	else:
		sprite.color.a = 1.0

	# -- attack input --
	if Input.is_action_just_pressed("attack") and can_attack and not is_attacking:
		_perform_attack()


func _perform_attack() -> void:
	is_attacking = true
	can_attack = false
	attack_visual.visible = true
	attack_shape.disabled = false
	attack_duration_timer.start()
	attack_timer.start()


func _on_attack_duration_timeout() -> void:
	is_attacking = false
	attack_visual.visible = false
	attack_shape.disabled = true


func _on_attack_cooldown_timeout() -> void:
	can_attack = true


func _on_attack_hit(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(1, global_position)


func take_damage(amount: int, _source_pos: Vector2 = Vector2.ZERO) -> void:
	if is_invincible:
		return
	hp -= amount
	hits_taken += 1
	health_changed.emit(hp, MAX_HP)

	# Brief knockback away from damage source.
	if _source_pos != Vector2.ZERO:
		var knockback_dir := (global_position - _source_pos).normalized()
		velocity = knockback_dir * KNOCKBACK_FORCE
		move_and_slide()

	if hp <= 0:
		player_died.emit()
		return

	# Start invincibility frames.
	is_invincible = true
	invincibility_timer.start()


func _on_invincibility_timeout() -> void:
	is_invincible = false
	sprite.color.a = 1.0
