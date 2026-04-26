extends CanvasLayer
class_name Hud

const GameConstants = preload("res://scripts/game_constants.gd")
const HUD_FONT: Font = preload("res://assets/fonts/PressStart2P-Regular.ttf")
const ICON_HEART: Texture2D = preload("res://assets/textures/ui/heart.png")
const ICON_KNIFE: Texture2D = preload("res://assets/textures/ui/knife_icon.png")
const ICON_STAR: Texture2D = preload("res://assets/textures/ui/star.png")

signal title_requested
signal collider_debug_toggled(enabled: bool)

var hearts_row: HBoxContainer
var knife_count_label: Label
var stars_label: Label
var overlay_root: Control
var overlay_bg: ColorRect
var overlay_title: Label
var overlay_info: Label
var overlay_subinfo: Label
var collider_button: Button
var collider_debug_on: bool = false


func _ready() -> void:
	layer = 20
	_build_ui()


func update_ui(data: Dictionary) -> void:
	_refresh_hearts(clampi(int(data.get("hearts", 0)), 0, GameConstants.HEARTS_MAX))
	knife_count_label.text = "%02d" % int(data.get("knife_count", 0))
	stars_label.text = "%d" % int(data.get("stars_left", 0))


func show_stage_clear(next_level: int) -> void:
	overlay_root.visible = true
	overlay_bg.color = Color(0.0, 0.0, 0.0, 0.60)
	overlay_title.text = "STAGE CLEAR!"
	overlay_title.modulate = Color(0.29, 0.87, 0.50, 1.0)
	overlay_info.text = "Next Level: %d" % next_level
	overlay_subinfo.text = "Destroyed stars become bonus knives."


func show_game_over(score: int, level: int, best_score: int) -> void:
	overlay_root.visible = true
	overlay_bg.color = Color(0.0, 0.0, 0.0, 0.82)
	overlay_title.text = "GAME OVER"
	overlay_title.modulate = Color(0.94, 0.27, 0.27, 1.0)
	overlay_info.text = "Tap or click anywhere to retry level %d." % level
	overlay_subinfo.text = "Score %d   Best %d" % [score, best_score]


func hide_overlay() -> void:
	overlay_root.visible = false


func set_collider_debug(enabled: bool) -> void:
	collider_debug_on = enabled
	collider_button.text = "COL ON" if collider_debug_on else "COL OFF"
	collider_button.modulate = Color(0.50, 0.95, 0.60, 1.0) if collider_debug_on else Color(1.0, 1.0, 1.0, 1.0)


func _apply_font(node: Control, size: int) -> void:
	node.add_theme_font_override("font", HUD_FONT)
	node.add_theme_font_size_override("font_size", size)


func _refresh_hearts(count: int) -> void:
	if hearts_row == null:
		return
	for c in hearts_row.get_children():
		c.queue_free()
	for i in count:
		var heart_icon := TextureRect.new()
		heart_icon.custom_minimum_size = Vector2(18.0, 18.0)
		heart_icon.size = Vector2(18.0, 18.0)
		heart_icon.texture = ICON_HEART
		heart_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		heart_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hearts_row.add_child(heart_icon)


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var top_panel := Panel.new()
	top_panel.position = Vector2.ZERO
	top_panel.size = Vector2(GameConstants.CANVAS_WIDTH, GameConstants.TOP_BAR_HEIGHT)
	top_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color(0.055, 0.065, 0.1, 0.91)
	top_style.set_border_width_all(1)
	top_style.border_color = Color(0.22, 0.52, 0.82, 0.42)
	top_panel.add_theme_stylebox_override("panel", top_style)
	root.add_child(top_panel)

	hearts_row = HBoxContainer.new()
	hearts_row.position = Vector2(10.0, 10.0)
	hearts_row.add_theme_constant_override("separation", 5)
	hearts_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hearts_row)

	var knife_icon := TextureRect.new()
	knife_icon.position = Vector2(118.0, 11.0)
	knife_icon.size = Vector2(20.0, 20.0)
	knife_icon.texture = ICON_KNIFE
	knife_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	knife_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	knife_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	knife_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(knife_icon)

	knife_count_label = Label.new()
	knife_count_label.position = Vector2(142.0, 12.0)
	knife_count_label.size = Vector2(56.0, 22.0)
	knife_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	knife_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	knife_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_font(knife_count_label, 10)
	root.add_child(knife_count_label)

	var star_icon := TextureRect.new()
	star_icon.position = Vector2(218.0, 11.0)
	star_icon.size = Vector2(20.0, 20.0)
	star_icon.texture = ICON_STAR
	star_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	star_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	star_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(star_icon)

	stars_label = Label.new()
	stars_label.position = Vector2(242.0, 12.0)
	stars_label.size = Vector2(44.0, 22.0)
	stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	stars_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stars_label.modulate = Color(0.98, 0.82, 0.26, 1.0)
	stars_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_font(stars_label, 10)
	root.add_child(stars_label)

	var title_button := Button.new()
	title_button.text = "TITLE"
	title_button.position = Vector2(GameConstants.CANVAS_WIDTH - 84.0, 10.0)
	title_button.size = Vector2(72.0, 22.0)
	_apply_font(title_button, 9)
	title_button.pressed.connect(func() -> void:
		title_requested.emit()
	)
	root.add_child(title_button)

	collider_button = Button.new()
	collider_button.text = "COL OFF"
	collider_button.position = Vector2(GameConstants.CANVAS_WIDTH - 174.0, 10.0)
	collider_button.size = Vector2(84.0, 22.0)
	_apply_font(collider_button, 9)
	collider_button.pressed.connect(_on_collider_button_pressed)
	root.add_child(collider_button)

	overlay_root = Control.new()
	overlay_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_root.visible = false
	overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(overlay_root)

	overlay_bg = ColorRect.new()
	overlay_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_root.add_child(overlay_bg)

	var panel := PanelContainer.new()
	panel.position = Vector2(40.0, 215.0)
	panel.size = Vector2(GameConstants.CANVAS_WIDTH - 80.0, 180.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.07, 0.11, 0.94)
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color(0.28, 0.55, 0.85, 0.55)
	panel_style.set_corner_radius_all(4)
	panel_style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", panel_style)
	overlay_root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 18.0
	vbox.offset_top = 18.0
	vbox.offset_right = -18.0
	vbox.offset_bottom = -18.0
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	overlay_title = Label.new()
	overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_font(overlay_title, 16)
	vbox.add_child(overlay_title)

	overlay_info = Label.new()
	overlay_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_font(overlay_info, 10)
	vbox.add_child(overlay_info)

	overlay_subinfo = Label.new()
	overlay_subinfo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_subinfo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay_subinfo.modulate = Color(0.86, 0.89, 0.95, 1.0)
	_apply_font(overlay_subinfo, 9)
	vbox.add_child(overlay_subinfo)

	update_ui({
		"hearts": GameConstants.HEARTS_MAX,
		"knife_count": 3,
		"stars_left": 0,
	})
	hide_overlay()


func _on_collider_button_pressed() -> void:
	set_collider_debug(not collider_debug_on)
	collider_debug_toggled.emit(collider_debug_on)
