extends Node2D

var player: Node = null


func bind_player(value: Node) -> void:
	player = value
	queue_redraw()


func _draw() -> void:
	if player != null and player.has_method("_draw_output_vfx"):
		player._draw_output_vfx(self)
