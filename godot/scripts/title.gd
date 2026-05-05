extends Control

const GameConstants = preload("res://scripts/game_constants.gd")
const PLAYER_SCENE := preload("res://scenes/player.tscn")
const BG_TEX: Texture2D = preload("res://assets/textures/bg/bg.png")

var how_to_modal: PanelContainer
var best_score_label: Label


func _ready() -> void:
	_clear_web_bridge_state()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_layout()


func _clear_web_bridge_state() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("window.__hitezero_state_json = null; window.render_game_to_text = function () { return null; };", true)


func _build_layout() -> void:
	var tex_bg := TextureRect.new()
	tex_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	tex_bg.texture = BG_TEX
	tex_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tex_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tex_bg.modulate = Color(1, 1, 1, 1)
	add_child(tex_bg)

	var vignette := ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(0.0, 0.0, 0.0, 0.14)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)

	var title_card := PanelContainer.new()
	title_card.position = Vector2(22.0, 58.0)
	title_card.size = Vector2(GameConstants.CANVAS_WIDTH - 44.0, 196.0)
	title_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_card.add_theme_stylebox_override("panel", _make_panel_style(Color(0.02, 0.04, 0.09, 0.44), Color(0.38, 0.70, 1.0, 0.22)))
	add_child(title_card)

	var preview := PLAYER_SCENE.instantiate()
	preview.position = Vector2(GameConstants.CANVAS_WIDTH * 0.5, 372.0)
	preview.scale = Vector2(1.28, 1.28)
	preview.show_tray = false
	preview.set_state("idle")
	preview.set_waiting_knives(0, false)
	add_child(preview)

	var title_box := VBoxContainer.new()
	title_box.position = Vector2(34.0, 72.0)
	title_box.size = Vector2(GameConstants.CANVAS_WIDTH - 68.0, 166.0)
	title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(title_box)

	var eyebrow := Label.new()
	eyebrow.text = "HiteZero Godot"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_font_size_override("font_size", 22)
	eyebrow.modulate = Color(0.98, 0.57, 0.17, 1.0)
	_apply_label_shadow(eyebrow, Color(0.0, 0.0, 0.0, 0.82), 2)
	title_box.add_child(eyebrow)

	var title := Label.new()
	title.text = "Meteor Knife Guard"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_apply_label_shadow(title, Color(0.0, 0.0, 0.0, 0.88), 4)
	title_box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Destroy every STAR block before the enemies reach the floor."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.modulate = Color(0.84, 0.98, 0.90, 1.0)
	_apply_label_shadow(subtitle, Color(0.0, 0.0, 0.0, 0.86), 2)
	title_box.add_child(subtitle)

	var button_box := VBoxContainer.new()
	button_box.position = Vector2(70.0, 438.0)
	button_box.size = Vector2(GameConstants.CANVAS_WIDTH - 140.0, 152.0)
	button_box.alignment = BoxContainer.ALIGNMENT_CENTER
	button_box.add_theme_constant_override("separation", 14)
	add_child(button_box)

	var start_button := Button.new()
	start_button.text = "Start Game"
	start_button.custom_minimum_size = Vector2(0.0, 54.0)
	start_button.add_theme_font_size_override("font_size", 18)
	start_button.add_theme_color_override("font_color", Color(1.0, 0.97, 0.78, 1.0))
	start_button.add_theme_color_override("font_hover_color", Color.WHITE)
	start_button.add_theme_stylebox_override("normal", _make_button_style(Color(0.10, 0.22, 0.34, 0.88), Color(0.96, 0.72, 0.28, 0.90)))
	start_button.add_theme_stylebox_override("hover", _make_button_style(Color(0.16, 0.34, 0.48, 0.96), Color(1.0, 0.86, 0.42, 1.0)))
	start_button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.08, 0.18, 0.26, 0.98), Color(1.0, 0.62, 0.30, 1.0)))
	start_button.pressed.connect(_on_start_pressed)
	button_box.add_child(start_button)

	var how_to_button := Button.new()
	how_to_button.text = "How To Play"
	how_to_button.custom_minimum_size = Vector2(0.0, 44.0)
	how_to_button.add_theme_color_override("font_color", Color(0.86, 0.95, 1.0, 1.0))
	how_to_button.add_theme_stylebox_override("normal", _make_button_style(Color(0.06, 0.10, 0.19, 0.74), Color(0.42, 0.70, 1.0, 0.55)))
	how_to_button.add_theme_stylebox_override("hover", _make_button_style(Color(0.10, 0.18, 0.30, 0.90), Color(0.60, 0.84, 1.0, 0.90)))
	how_to_button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.04, 0.08, 0.14, 0.94), Color(0.40, 0.62, 0.94, 0.90)))
	how_to_button.pressed.connect(_on_how_to_pressed)
	button_box.add_child(how_to_button)

	best_score_label = Label.new()
	best_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best_score_label.custom_minimum_size = Vector2(0.0, 28.0)
	best_score_label.add_theme_font_size_override("font_size", 16)
	best_score_label.modulate = Color(0.99, 0.91, 0.42, 1.0)
	best_score_label.text = "Best Score: %d" % Session.best_score
	button_box.add_child(best_score_label)

	var footer := Label.new()
	footer.text = "Keyboard: A/D or Arrows   Pointer: drag to aim"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 12)
	footer.modulate = Color(0.44, 0.48, 0.55, 1.0)
	footer.position = Vector2(24.0, GameConstants.CANVAS_HEIGHT - 48.0)
	footer.size = Vector2(GameConstants.CANVAS_WIDTH - 48.0, 24.0)
	add_child(footer)

	_build_modal()


func _apply_label_shadow(label: Label, shadow_color: Color, outline_size: int) -> void:
	label.add_theme_color_override("font_shadow_color", shadow_color)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 3)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.07, 0.68))
	label.add_theme_constant_override("outline_size", outline_size)


func _make_button_style(fill_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(13)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0.0, 3.0)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	return style


func _make_panel_style(fill_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(20)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.36)
	style.shadow_size = 16
	style.shadow_offset = Vector2(0.0, 8.0)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	return style


func _build_modal() -> void:
	how_to_modal = PanelContainer.new()
	how_to_modal.visible = false
	how_to_modal.position = Vector2(28.0, 180.0)
	how_to_modal.size = Vector2(GameConstants.CANVAS_WIDTH - 56.0, 300.0)
	add_child(how_to_modal)

	var modal_vbox := VBoxContainer.new()
	modal_vbox.add_theme_constant_override("separation", 12)
	modal_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_vbox.offset_left = 18.0
	modal_vbox.offset_top = 18.0
	modal_vbox.offset_right = -18.0
	modal_vbox.offset_bottom = -18.0
	how_to_modal.add_child(modal_vbox)

	var header := Label.new()
	header.text = "How To Play"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 22)
	modal_vbox.add_child(header)

	for line in [
		"1. Drag upward-left or upward-right to choose the throw angle.",
		"2. Clear every STAR block to finish the stage.",
		"3. Falling RED_ENEMY blocks remove hearts if they reach the danger zone.",
		"4. Destroyed STAR blocks add knives for the next stage.",
	]:
		var label := Label.new()
		label.text = line
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 14)
		modal_vbox.add_child(label)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.custom_minimum_size = Vector2(0.0, 42.0)
	close_button.pressed.connect(func() -> void:
		how_to_modal.visible = false
	)
	modal_vbox.add_child(close_button)


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_how_to_pressed() -> void:
	how_to_modal.visible = true
