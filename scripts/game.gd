extends Node2D
## Main game scene: manages waves, spawning enemies, and game-over flow.

const ENEMY_SCENE_PATH := "res://scenes/enemy.tscn"
const WAVE_DELAY := 2.0
const BASE_ENEMIES_PER_WAVE := 3
const ENEMIES_SCALE_PER_WAVE := 2

var enemy_scene: PackedScene
var current_wave := 0
var enemies_alive := 0
var score := 0
var game_active := false

@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var game_over_screen: CanvasLayer = $GameOverScreen
@onready var wave_timer: Timer = $WaveTimer
@onready var enemy_container: Node2D = $EnemyContainer
@onready var camera: Camera2D = $Player/Camera2D


func _ready() -> void:
	enemy_scene = load(ENEMY_SCENE_PATH)
	game_over_screen.visible = false
	game_over_screen.process_mode = Node.PROCESS_MODE_ALWAYS

	player.health_changed.connect(_on_player_health_changed)
	player.player_died.connect(_on_player_died)

	wave_timer.wait_time = WAVE_DELAY
	wave_timer.one_shot = true
	wave_timer.timeout.connect(_start_next_wave)

	game_active = true
	hud.set_score(0)
	hud.update_hits(0)
	# Slight delay before first wave so the player can orient.
	wave_timer.start()


func _start_next_wave() -> void:
	if not game_active:
		return
	current_wave += 1
	var enemy_count := BASE_ENEMIES_PER_WAVE + (current_wave - 1) * ENEMIES_SCALE_PER_WAVE
	hud.update_wave(current_wave)
	hud.show_wave_banner(current_wave)
	_spawn_wave(enemy_count)


func _spawn_wave(count: int) -> void:
	var vp_size := get_viewport_rect().size
	for i in count:
		var enemy := enemy_scene.instantiate() as CharacterBody2D
		enemy.global_position = _get_spawn_position(vp_size)
		enemy.set_target(player)
		enemy.enemy_killed.connect(_on_enemy_killed)
		enemy_container.add_child(enemy)
		enemies_alive += 1


func _get_spawn_position(vp_size: Vector2) -> Vector2:
	## Spawn enemies along the edges of the screen, outside the player's immediate area.
	var margin := 60.0
	var edge := randi() % 4
	var pos := Vector2.ZERO
	match edge:
		0: # top
			pos = Vector2(randf_range(margin, vp_size.x - margin), -margin)
		1: # bottom
			pos = Vector2(randf_range(margin, vp_size.x - margin), vp_size.y + margin)
		2: # left
			pos = Vector2(-margin, randf_range(margin, vp_size.y - margin))
		3: # right
			pos = Vector2(vp_size.x + margin, randf_range(margin, vp_size.y - margin))

	# Offset by camera position so spawns are relative to the viewport.
	if camera:
		pos += camera.global_position - vp_size / 2.0
	return pos


func _on_enemy_killed(points: int) -> void:
	enemies_alive -= 1
	score += points
	hud.update_score(points)
	hud.update_hits(player.hits_taken)

	if enemies_alive <= 0 and game_active:
		# Brief pause before next wave.
		wave_timer.start()


func _on_player_health_changed(current_hp: int, max_hp: int) -> void:
	hud.update_health(current_hp, max_hp)
	hud.update_hits(player.hits_taken)


func _on_player_died() -> void:
	game_active = false
	wave_timer.stop()

	# Clean up remaining enemies.
	for enemy in enemy_container.get_children():
		enemy.queue_free()

	game_over_screen.show_game_over(score, current_wave, player.hits_taken)
	get_tree().paused = true
