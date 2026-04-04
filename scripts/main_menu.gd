extends Control
## Main menu: title screen with play and quit buttons.

@onready var play_button: Button = $VBox/PlayButton
@onready var quit_button: Button = $VBox/QuitButton
@onready var title_label: Label = $VBox/TitleLabel
@onready var subtitle_label: Label = $VBox/SubtitleLabel


func _ready() -> void:
	play_button.pressed.connect(_on_play)
	quit_button.pressed.connect(_on_quit)
	_animate_title()


func _animate_title() -> void:
	# Gentle pulsing effect on the title.
	var tween := create_tween().set_loops()
	tween.tween_property(title_label, "modulate:a", 0.7, 1.0)
	tween.tween_property(title_label, "modulate:a", 1.0, 1.0)


func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_quit() -> void:
	get_tree().quit()
