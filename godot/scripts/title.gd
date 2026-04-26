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
	tex_bg.modulate = Color(0.28, 0.32, 0.42, 1.0)
	add_child(tex_bg)

	var vignette := ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(0.0, 0.0, 0.0, 0.42)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)

	var preview := PLAYER_SCENE.instantiate()
	preview.position = Vector2(GameConstants.CANVAS_WIDTH * 0.5, 360.0)
	preview.scale = Vector2(1.65, 1.65)
	preview.set_state("idle")
	preview.set_waiting_knives(4, true)
	add_child(preview)

	var title_box := VBoxContainer.new()
	title_box.position = Vector2(38.0, 120.0)
	title_box.size = Vector2(GameConstants.CANVAS_WIDTH - 76.0, 240.0)
	title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(title_box)

	var eyebrow := Label.new()
	eyebrow.text = "HiteZero Godot"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_font_size_override("font_size", 22)
	eyebrow.modulate = Color(0.98, 0.57, 0.17, 1.0)
	title_box.add_child(eyebrow)

	var title := Label.new()
	title.text = "Meteor Knife Guard"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.modulate = Color(1.0, 1.0, 1.0, 1.0)
	title_box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Destroy every STAR block before the enemies reach the floor."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.modulate = Color(0.84, 0.98, 0.90, 1.0)
	title_box.add_child(subtitle)

	var button_box := VBoxContainer.new()
	button_box.position = Vector2(70.0, 420.0)
	button_box.size = Vector2(GameConstants.CANVAS_WIDTH - 140.0, 150.0)
	button_box.alignment = BoxContainer.ALIGNMENT_CENTER
	button_box.add_theme_constant_override("separation", 12)
	add_child(button_box)

	var start_button := Button.new()
	start_button.text = "Start Game"
	start_button.custom_minimum_size = Vector2(0.0, 54.0)
	start_button.pressed.connect(_on_start_pressed)
	button_box.add_child(start_button)

	var how_to_button := Button.new()
	how_to_button.text = "How To Play"
	how_to_button.custom_minimum_size = Vector2(0.0, 44.0)
	how_to_button.pressed.connect(_on_how_to_pressed)
	button_box.add_child(how_to_button)

	best_score_label = Label.new()
	best_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
