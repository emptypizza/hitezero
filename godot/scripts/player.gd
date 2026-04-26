extends Node2D
class_name Player

const GameConstants = preload("res://scripts/game_constants.gd")
const TEX_BODY_IDLE: Texture2D = preload("res://assets/textures/player/character_idle.png")
const TEX_BODY_THROW: Texture2D = preload("res://assets/textures/player/character_throw.png")
const TEX_TRAY: Texture2D = preload("res://assets/textures/player/tray.png")
const TEX_KNIFE: Texture2D = preload("res://assets/textures/knife/knife.png")

@onready var tray: Sprite2D = $Tray
@onready var body: Sprite2D = $Body
@onready var wait_root: Node2D = $WaitKnives

var visual_state := "idle"
var waiting_knives: int = 3
var show_waiting_knives: bool = true


func _ready() -> void:
	tray.texture = TEX_TRAY
	tray.centered = true
	tray.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.centered = true
	body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_refresh_visual()
	_fit_body_scale()
	_rebuild_wait_knives()


func set_state(new_state: String) -> void:
	visual_state = new_state
	_refresh_visual()


func set_waiting_knives(count: int, visible_now: bool) -> void:
	waiting_knives = count
	show_waiting_knives = visible_now
	_rebuild_wait_knives()


func _fit_body_scale() -> void:
	if body.texture == null:
		return
	var ts := body.texture.get_size()
	if ts.x < 1.0:
		return
	var target_w := 56.0
	var factor := int(round(target_w / ts.x))
	factor = maxi(1, factor)
	body.scale = Vector2(float(factor), float(factor))


func _refresh_visual() -> void:
	if body == null:
		return
	if visual_state == "throw":
		body.texture = TEX_BODY_THROW
	else:
		body.texture = TEX_BODY_IDLE
	_fit_body_scale()
	match visual_state:
		"gameover":
			body.modulate = Color(0.62, 0.64, 0.70, 1.0)
			tray.modulate = Color(0.75, 0.75, 0.80, 1.0)
		"hit":
			body.modulate = Color(1.0, 0.52, 0.52, 1.0)
			tray.modulate = Color.WHITE
		"clear":
			body.modulate = Color(0.72, 1.0, 0.82, 1.0)
			tray.modulate = Color.WHITE
		"throw":
			body.modulate = Color(0.95, 0.95, 1.0, 1.0)
			tray.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_:
			body.modulate = Color.WHITE
			tray.modulate = Color.WHITE


func _rebuild_wait_knives() -> void:
	if wait_root == null:
		return
	for c in wait_root.get_children():
		c.queue_free()
	if not show_waiting_knives:
		return
	var count := mini(waiting_knives, 12)
	if count <= 0:
		return
	var spacing := 6.0
	var offset_x := -((float(count - 1) * spacing) * 0.5)
	for i in count:
		var ks := Sprite2D.new()
		ks.texture = TEX_KNIFE
		ks.centered = true
		ks.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ks.scale = Vector2(0.35, 0.35)
		ks.position = Vector2(offset_x + float(i) * spacing, 0.0)
		wait_root.add_child(ks)
