extends CanvasLayer
## Game over overlay: shows final stats and offers retry / quit.

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var score_label: Label = $Panel/VBox/ScoreLabel
@onready var wave_label: Label = $Panel/VBox/WaveLabel
@onready var hits_label: Label = $Panel/VBox/HitsLabel
@onready var grade_label: Label = $Panel/VBox/GradeLabel
@onready var retry_button: Button = $Panel/VBox/ButtonContainer/RetryButton
@onready var menu_button: Button = $Panel/VBox/ButtonContainer/MenuButton


func _ready() -> void:
	retry_button.pressed.connect(_on_retry)
	menu_button.pressed.connect(_on_menu)
	visible = false


func show_game_over(final_score: int, wave_reached: int, hits_taken: int) -> void:
	visible = true
	score_label.text = "Final Score: %d" % final_score
	wave_label.text = "Waves Survived: %d" % wave_reached
	hits_label.text = "Hits Taken: %d" % hits_taken

	# Grade the player -- the core "hitezero" mechanic.
	if hits_taken == 0:
		grade_label.text = "GRADE: ZERO -- PERFECT RUN!"
		grade_label.modulate = Color(1.0, 0.84, 0.0)
	elif hits_taken <= 2:
		grade_label.text = "GRADE: S -- NEARLY UNTOUCHABLE"
		grade_label.modulate = Color(0.6, 0.4, 1.0)
	elif hits_taken <= 5:
		grade_label.text = "GRADE: A -- IMPRESSIVE"
		grade_label.modulate = Color(0.3, 0.8, 1.0)
	elif hits_taken <= 10:
		grade_label.text = "GRADE: B -- NOT BAD"
		grade_label.modulate = Color(0.3, 0.9, 0.5)
	else:
		grade_label.text = "GRADE: C -- KEEP PRACTICING"
		grade_label.modulate = Color(0.8, 0.8, 0.8)


func _on_retry() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
