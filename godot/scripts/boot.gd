extends Node


func _ready() -> void:
	call_deferred("_go_to_title")


func _go_to_title() -> void:
	get_tree().change_scene_to_file("res://scenes/title.tscn")
