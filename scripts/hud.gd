extends CanvasLayer
## HUD: displays health bar, score, wave number, and hits taken.

@onready var health_bar: ProgressBar = $MarginContainer/VBox/TopBar/HealthBar
@onready var health_label: Label = $MarginContainer/VBox/TopBar/HealthLabel
@onready var score_label: Label = $MarginContainer/VBox/TopBar/ScoreLabel
@onready var wave_label: Label = $MarginContainer/VBox/TopBar/WaveLabel
@onready var hits_label: Label = $MarginContainer/VBox/BottomInfo/HitsLabel
@onready var wave_banner: Label = $WaveBanner

var current_score := 0


func _ready() -> void:
	wave_banner.visible = false


func update_health(current_hp: int, max_hp: int) -> void:
	health_bar.max_value = max_hp
	health_bar.value = current_hp
	health_label.text = "HP: %d/%d" % [current_hp, max_hp]

	# Color the bar based on remaining health.
	var ratio := float(current_hp) / float(max_hp)
	if ratio > 0.6:
		health_bar.modulate = Color(0.3, 0.9, 0.3)
	elif ratio > 0.3:
		health_bar.modulate = Color(0.9, 0.8, 0.2)
	else:
		health_bar.modulate = Color(0.9, 0.2, 0.2)


func update_score(points: int) -> void:
	current_score += points
	score_label.text = "Score: %d" % current_score


func set_score(value: int) -> void:
	current_score = value
	score_label.text = "Score: %d" % current_score


func update_wave(wave_num: int) -> void:
	wave_label.text = "Wave: %d" % wave_num


func update_hits(hits: int) -> void:
	if hits == 0:
		hits_label.text = "HITS TAKEN: 0  --  PERFECT!"
		hits_label.modulate = Color(0.3, 1.0, 0.5)
	else:
		hits_label.text = "HITS TAKEN: %d" % hits
		hits_label.modulate = Color(0.9, 0.3, 0.3)


func show_wave_banner(wave_num: int) -> void:
	wave_banner.text = "-- WAVE %d --" % wave_num
	wave_banner.visible = true
	wave_banner.modulate.a = 1.0

	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(wave_banner, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): wave_banner.visible = false)
