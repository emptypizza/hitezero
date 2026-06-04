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
var overlay_panel: PanelContainer
var overlay_title: Label
var overlay_info: Label
var overlay_subinfo: Label
var overlay_retry: Label
var collider_button: Button
var collider_debug_on: bool = false
var combo_label: Label
var combo_gauge: ColorRect
var combo_gauge_bg: ColorRect
var item_slot_icons: Array[ColorRect] = []
var item_slot_labels: Array[Label] = []
var item_container: HBoxContainer
var boss_hp_bar_bg: ColorRect
var boss_hp_bar: ColorRect
var boss_name_label: Label
var boss_warning_label: Label
var boss_phase_label: Label
var score_label: Label
var level_label: Label

const _PANEL_POS := Vector2(40.0, 215.0)

var _prev_hearts: int = -1
var _prev_knife_count: int = -1
var _prev_stars_left: int = -1
var _prev_combo: int = -1
var _prev_score: int = -1
var _prev_level: int = -1


func _ready() -> void:
	layer = 20
	_build_ui()


func update_ui(data: Dictionary) -> void:
	var new_hearts := clampi(int(data.get("hearts", 0)), 0, Session.get_max_hearts())
	var new_knife_count := int(data.get("knife_count", 0))
	var new_stars_left := int(data.get("stars_left", 0))
	var new_combo := int(data.get("combo", 0))
	var combo_timer_val := float(data.get("combo_timer", 0.0))
	var new_score := int(data.get("score", 0))
	var new_level := int(data.get("level", 1))

	if _prev_hearts >= 0:
		if new_hearts < _prev_hearts:
			_heart_flash()
		if new_knife_count != _prev_knife_count:
			_punch_scale(knife_count_label)
		if new_stars_left != _prev_stars_left:
			_punch_scale(stars_label)
		if new_combo > _prev_combo and new_combo >= 3:
			_punch_scale(combo_label)
		if new_score > _prev_score and _prev_score >= 0:
			_punch_scale(score_label)

	_prev_hearts = new_hearts
	_prev_knife_count = new_knife_count
	_prev_stars_left = new_stars_left
	_prev_combo = new_combo
	_prev_score = new_score
	_prev_level = new_level

	_refresh_hearts(new_hearts)
	knife_count_label.text = "%02d" % new_knife_count
	stars_label.text = "%d" % new_stars_left
	_refresh_score(new_score, new_level)
	_refresh_combo(new_combo, combo_timer_val)
	_refresh_items(data.get("item_slots", []), data.get("item_timers", []))


func show_stage_clear(next_level: int, heart_bonus: int) -> void:
	overlay_root.visible = true
	overlay_bg.color = Color(0.0, 0.0, 0.0, 0.60)
	overlay_panel.position = _PANEL_POS
	overlay_title.text = "STAGE CLEAR!"
	overlay_title.modulate = Color(0.29, 0.87, 0.50, 1.0)
	overlay_title.scale = Vector2.ZERO
	overlay_info.text = "Next Level: %d" % next_level
	overlay_subinfo.text = "+%d bonus knife%s from hearts!" % [heart_bonus, "s" if heart_bonus != 1 else ""] if heart_bonus > 0 else "Stars become bonus knives."
	overlay_subinfo.modulate = Color(0.86, 0.89, 0.95, 1.0)
	overlay_retry.text = ""
	overlay_retry.modulate.a = 0.0

	# Wait one frame for layout, then bounce-in the title
	await get_tree().process_frame
	overlay_title.pivot_offset = overlay_title.size / 2.0
	var tw := create_tween()
	tw.tween_property(overlay_title, "scale", Vector2(1.2, 1.2), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(overlay_title, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func show_game_over(score: int, level: int, best_score: int) -> void:
	overlay_root.visible = true
	overlay_bg.color = Color(0.0, 0.0, 0.0, 0.82)
	overlay_title.text = "GAME OVER"
	overlay_title.modulate = Color(0.94, 0.27, 0.27, 1.0)
	overlay_title.scale = Vector2.ONE
	overlay_info.text = "Score: 0"
	overlay_retry.text = "Tap to retry"
	overlay_retry.modulate = Color(0.86, 0.89, 0.95, 0.0)

	# Panel drops from above
	overlay_panel.position = Vector2(_PANEL_POS.x, -180.0)
	var drop_tw := create_tween()
	drop_tw.tween_property(overlay_panel, "position:y", _PANEL_POS.y, 0.45).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	# Score count-up animation
	var countup_tw := create_tween()
	countup_tw.tween_method(
		func(v: float) -> void: overlay_info.text = "Score: %d" % int(v),
		0.0, float(score), 0.8
	)

	# Best score / NEW BEST display
	var is_new_best := score > 0 and score >= best_score
	if is_new_best:
		overlay_subinfo.text = "NEW BEST!"
		overlay_subinfo.modulate = Color(1.0, 0.85, 0.0, 1.0)
		var flash_tw := create_tween().set_loops(3)
		flash_tw.tween_property(overlay_subinfo, "modulate:a", 0.25, 0.18)
		flash_tw.tween_property(overlay_subinfo, "modulate:a", 1.0, 0.18)
	else:
		overlay_subinfo.text = "Best: %d" % best_score
		overlay_subinfo.modulate = Color(0.86, 0.89, 0.95, 1.0)

	# "Tap to retry" fades in after 1.5s
	var retry_tw := create_tween()
	retry_tw.tween_interval(1.5)
	retry_tw.tween_property(overlay_retry, "modulate:a", 1.0, 0.5)


func hide_overlay() -> void:
	overlay_root.visible = false
	overlay_panel.position = _PANEL_POS
	overlay_title.scale = Vector2.ONE
	overlay_retry.text = ""
	overlay_retry.modulate.a = 0.0
	hide_boss_ui()


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
	knife_count_label.pivot_offset = Vector2(28.0, 11.0)
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
	stars_label.pivot_offset = Vector2(22.0, 11.0)
	stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	stars_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stars_label.modulate = Color(0.98, 0.82, 0.26, 1.0)
	stars_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_font(stars_label, 10)
	root.add_child(stars_label)

	# ─── Score & Level (top-bar right) ────────────────────────────────────
	level_label = Label.new()
	level_label.position = Vector2(GameConstants.CANVAS_WIDTH - 114.0, 6.0)
	level_label.size = Vector2(104.0, 16.0)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_label.modulate = Color(0.65, 0.75, 0.90, 0.85)
	level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_font(level_label, 7)
	root.add_child(level_label)

	score_label = Label.new()
	score_label.position = Vector2(GameConstants.CANVAS_WIDTH - 114.0, 24.0)
	score_label.size = Vector2(104.0, 20.0)
	score_label.pivot_offset = Vector2(104.0, 10.0)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_font(score_label, 11)
	root.add_child(score_label)

	# ─── Combo UI (bottom-left) ────────────────────────────────────────────
	combo_label = Label.new()
	combo_label.position = Vector2(10.0, GameConstants.CANVAS_HEIGHT - 40.0)
	combo_label.size = Vector2(120.0, 18.0)
	combo_label.pivot_offset = Vector2(60.0, 9.0)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	combo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	combo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combo_label.visible = false
	_apply_font(combo_label, 9)
	root.add_child(combo_label)

	combo_gauge_bg = ColorRect.new()
	combo_gauge_bg.position = Vector2(10.0, GameConstants.CANVAS_HEIGHT - 20.0)
	combo_gauge_bg.size = Vector2(80.0, 4.0)
	combo_gauge_bg.color = Color(0.15, 0.15, 0.22, 0.6)
	combo_gauge_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combo_gauge_bg.visible = false
	root.add_child(combo_gauge_bg)

	combo_gauge = ColorRect.new()
	combo_gauge.position = Vector2(10.0, GameConstants.CANVAS_HEIGHT - 20.0)
	combo_gauge.size = Vector2(80.0, 4.0)
	combo_gauge.color = Color(0.40, 0.85, 1.0, 0.8)
	combo_gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combo_gauge.visible = false
	root.add_child(combo_gauge)

	# ─── Item slot UI (bottom-right) ───────────────────────────────────────
	item_container = HBoxContainer.new()
	item_container.position = Vector2(GameConstants.CANVAS_WIDTH - 90.0, GameConstants.CANVAS_HEIGHT - 42.0)
	item_container.add_theme_constant_override("separation", 6)
	item_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(item_container)

	for i in range(3):  # Max possible slots (2 base + 1 upgrade)
		var slot_wrapper := VBoxContainer.new()
		slot_wrapper.alignment = BoxContainer.ALIGNMENT_CENTER
		slot_wrapper.add_theme_constant_override("separation", 2)
		slot_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item_container.add_child(slot_wrapper)

		var icon := ColorRect.new()
		icon.custom_minimum_size = Vector2(24.0, 24.0)
		icon.size = Vector2(24.0, 24.0)
		icon.color = Color(0.2, 0.2, 0.3, 0.4)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_wrapper.add_child(icon)
		item_slot_icons.append(icon)

		var slot_label := Label.new()
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_label.text = ""
		_apply_font(slot_label, 6)
		slot_wrapper.add_child(slot_label)
		item_slot_labels.append(slot_label)

	var title_button := Button.new()
	title_button.text = "TITLE"
	title_button.position = Vector2(GameConstants.CANVAS_WIDTH - 84.0, 10.0)
	title_button.size = Vector2(72.0, 22.0)
	_apply_font(title_button, 9)
	title_button.pressed.connect(func() -> void:
		AudioManager.play("ui_click")
		title_requested.emit()
	)
	root.add_child(title_button)

	collider_button = Button.new()
	collider_button.text = "COL OFF"
	collider_button.position = Vector2(GameConstants.CANVAS_WIDTH - 174.0, 10.0)
	collider_button.size = Vector2(84.0, 22.0)
	_apply_font(collider_button, 9)
	collider_button.pressed.connect(_on_collider_button_pressed)
	collider_button.visible = OS.is_debug_build()
	root.add_child(collider_button)

	# ─── Boss HP bar ───────────────────────────────────────────────────────
	boss_hp_bar_bg = ColorRect.new()
	boss_hp_bar_bg.position = Vector2(10.0, GameConstants.TOP_BAR_HEIGHT + 4.0)
	boss_hp_bar_bg.size = Vector2(GameConstants.CANVAS_WIDTH - 20.0, 8.0)
	boss_hp_bar_bg.color = Color(0.12, 0.12, 0.18, 0.7)
	boss_hp_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_hp_bar_bg.visible = false
	root.add_child(boss_hp_bar_bg)

	boss_hp_bar = ColorRect.new()
	boss_hp_bar.position = Vector2(10.0, GameConstants.TOP_BAR_HEIGHT + 4.0)
	boss_hp_bar.size = Vector2(GameConstants.CANVAS_WIDTH - 20.0, 8.0)
	boss_hp_bar.color = Color(0.90, 0.20, 0.25, 0.9)
	boss_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_hp_bar.visible = false
	root.add_child(boss_hp_bar)

	boss_name_label = Label.new()
	boss_name_label.position = Vector2(10.0, GameConstants.TOP_BAR_HEIGHT + 14.0)
	boss_name_label.size = Vector2(GameConstants.CANVAS_WIDTH - 20.0, 16.0)
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	boss_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_name_label.visible = false
	_apply_font(boss_name_label, 7)
	root.add_child(boss_name_label)

	# Boss warning label (centered, large)
	boss_warning_label = Label.new()
	boss_warning_label.set_anchors_preset(Control.PRESET_CENTER)
	boss_warning_label.position = Vector2(0.0, 200.0)
	boss_warning_label.size = Vector2(GameConstants.CANVAS_WIDTH, 50.0)
	boss_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_warning_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	boss_warning_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_warning_label.visible = false
	boss_warning_label.text = "WARNING"
	boss_warning_label.modulate = Color(1.0, 0.20, 0.20, 1.0)
	_apply_font(boss_warning_label, 20)
	root.add_child(boss_warning_label)

	# Boss phase label (briefly shown)
	boss_phase_label = Label.new()
	boss_phase_label.position = Vector2(0.0, 250.0)
	boss_phase_label.size = Vector2(GameConstants.CANVAS_WIDTH, 30.0)
	boss_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_phase_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	boss_phase_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_phase_label.visible = false
	_apply_font(boss_phase_label, 12)
	root.add_child(boss_phase_label)

	overlay_root = Control.new()
	overlay_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_root.visible = false
	overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(overlay_root)

	overlay_bg = ColorRect.new()
	overlay_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_root.add_child(overlay_bg)

	overlay_panel = PanelContainer.new()
	overlay_panel.position = _PANEL_POS
	overlay_panel.size = Vector2(GameConstants.CANVAS_WIDTH - 80.0, 180.0)
	overlay_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.07, 0.11, 0.94)
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color(0.28, 0.55, 0.85, 0.55)
	panel_style.set_corner_radius_all(4)
	panel_style.set_content_margin_all(16)
	overlay_panel.add_theme_stylebox_override("panel", panel_style)
	overlay_root.add_child(overlay_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 18.0
	vbox.offset_top = 18.0
	vbox.offset_right = -18.0
	vbox.offset_bottom = -18.0
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	overlay_panel.add_child(vbox)

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

	overlay_retry = Label.new()
	overlay_retry.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_retry.modulate = Color(0.86, 0.89, 0.95, 0.0)
	_apply_font(overlay_retry, 8)
	vbox.add_child(overlay_retry)

	update_ui({
		"hearts": Session.get_max_hearts(),
		"knife_count": Session.get_starting_knives(),
		"stars_left": 0,
	})
	hide_overlay()


func _refresh_score(new_score: int, new_level: int) -> void:
	if score_label == null or level_label == null:
		return
	level_label.text = "STAGE %d" % new_level
	score_label.text = "%d" % new_score
	# Score color shifts from white → cyan as score grows
	var intensity := clampf(float(new_score) / 5000.0, 0.0, 1.0)
	score_label.modulate = Color(
		1.0 - intensity * 0.45,
		0.92 + intensity * 0.08,
		0.92 + intensity * 0.08,
		1.0
	)


func _refresh_combo(combo: int, timer_val: float) -> void:
	if combo_label == null or combo_gauge == null or combo_gauge_bg == null:
		return
	if combo < 3:
		combo_label.visible = false
		combo_gauge.visible = false
		combo_gauge_bg.visible = false
		return

	combo_label.visible = true
	combo_gauge.visible = true
	combo_gauge_bg.visible = true

	# Determine tier
	var tier := 0
	var tiers := GameConstants.COMBO_TIERS
	for i in range(tiers.size() - 1, -1, -1):
		if combo >= tiers[i]:
			tier = i + 1
			break

	var color: Color = GameConstants.COMBO_COLORS[mini(tier, GameConstants.COMBO_COLORS.size() - 1)]
	var mult: float = GameConstants.COMBO_MULTIPLIERS[mini(tier, GameConstants.COMBO_MULTIPLIERS.size() - 1)]
	combo_label.text = "%d HIT x%.1f" % [combo, mult]
	combo_label.modulate = color

	# Gauge fill
	var gauge_pct := clampf(timer_val / Session.get_combo_window(), 0.0, 1.0)
	combo_gauge.size.x = 80.0 * gauge_pct
	combo_gauge.color = Color(color.r, color.g, color.b, 0.8)


func _refresh_items(slots: Array, timers: Array) -> void:
	for i in range(item_slot_icons.size()):
		if i >= item_slot_icons.size():
			break
		if i < slots.size():
			var item_type: int = int(slots[i])
			var color: Color = GameConstants.ITEM_COLORS.get(item_type, Color(0.5, 0.5, 0.5, 1.0))
			item_slot_icons[i].color = color
			var name_str: String = GameConstants.ITEM_NAMES.get(item_type, "?")
			var time_left := float(timers[i]) if i < timers.size() else 0.0
			item_slot_labels[i].text = "%s %ds" % [name_str, ceili(time_left)]
			item_slot_labels[i].modulate = color
		else:
			item_slot_icons[i].color = Color(0.2, 0.2, 0.3, 0.4)
			item_slot_labels[i].text = ""
			item_slot_labels[i].modulate = Color(0.5, 0.5, 0.5, 0.5)


# ─── Boss UI ───────────────────────────────────────────────────────────────

func show_boss_warning(boss_name_text: String, color: Color) -> void:
	boss_hp_bar_bg.visible = true
	boss_hp_bar.visible = true
	boss_hp_bar.color = color
	boss_name_label.visible = true
	boss_name_label.text = boss_name_text
	boss_name_label.modulate = color

	# Warning flash
	boss_warning_label.visible = true
	boss_warning_label.modulate = Color(1.0, 0.20, 0.20, 1.0)
	boss_warning_label.text = "WARNING"
	boss_warning_label.scale = Vector2.ONE
	boss_warning_label.pivot_offset = boss_warning_label.size / 2.0

	# Flash animation
	var tw := create_tween().set_loops(3)
	tw.tween_property(boss_warning_label, "modulate:a", 0.2, 0.2)
	tw.tween_property(boss_warning_label, "modulate:a", 1.0, 0.2)

	# Fade out warning after 1.5s
	var fade_tw := create_tween()
	fade_tw.tween_interval(1.5)
	fade_tw.tween_property(boss_warning_label, "modulate:a", 0.0, 0.3)
	fade_tw.tween_callback(func() -> void: boss_warning_label.visible = false)

	# Boss name fades out after 2s
	var name_tw := create_tween()
	name_tw.tween_interval(2.5)
	name_tw.tween_property(boss_name_label, "modulate:a", 0.0, 0.5)


func update_boss_hp(hp: int, max_hp: int) -> void:
	if boss_hp_bar == null or boss_hp_bar_bg == null:
		return
	var bar_max_w := GameConstants.CANVAS_WIDTH - 20.0
	var pct := clampf(float(hp) / float(maxi(1, max_hp)), 0.0, 1.0)
	boss_hp_bar.size.x = bar_max_w * pct

	# Color shift: green → yellow → red as HP drops
	if pct > 0.5:
		boss_hp_bar.color = Color(0.30, 0.85, 0.40, 0.9).lerp(Color(1.0, 0.85, 0.0, 0.9), (1.0 - pct) * 2.0)
	else:
		boss_hp_bar.color = Color(1.0, 0.85, 0.0, 0.9).lerp(Color(0.90, 0.20, 0.25, 0.9), (0.5 - pct) * 2.0)


func show_boss_phase(new_phase: int) -> void:
	boss_phase_label.visible = true
	boss_phase_label.text = "PHASE %d" % new_phase
	boss_phase_label.modulate = Color(1.0, 0.85, 0.0, 1.0)
	boss_phase_label.scale = Vector2.ZERO
	boss_phase_label.pivot_offset = boss_phase_label.size / 2.0

	var tw := create_tween()
	tw.tween_property(boss_phase_label, "scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(boss_phase_label, "scale", Vector2.ONE, 0.1)
	tw.tween_interval(0.8)
	tw.tween_property(boss_phase_label, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func() -> void: boss_phase_label.visible = false)


func show_boss_defeated() -> void:
	# Hide boss HP bar with animation
	var tw := create_tween()
	tw.tween_property(boss_hp_bar, "modulate:a", 0.0, 0.5)
	tw.parallel().tween_property(boss_hp_bar_bg, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func() -> void:
		boss_hp_bar.visible = false
		boss_hp_bar_bg.visible = false
		boss_name_label.visible = false
		boss_hp_bar.modulate.a = 1.0
		boss_hp_bar_bg.modulate.a = 1.0
	)


func hide_boss_ui() -> void:
	if boss_hp_bar != null:
		boss_hp_bar.visible = false
	if boss_hp_bar_bg != null:
		boss_hp_bar_bg.visible = false
	if boss_name_label != null:
		boss_name_label.visible = false
	if boss_warning_label != null:
		boss_warning_label.visible = false
	if boss_phase_label != null:
		boss_phase_label.visible = false


func _on_collider_button_pressed() -> void:
	AudioManager.play("ui_click")
	set_collider_debug(not collider_debug_on)
	collider_debug_toggled.emit(collider_debug_on)


func _punch_scale(node: Control) -> void:
	if node == null:
		return
	node.scale = Vector2.ONE
	var t := create_tween()
	t.tween_property(node, "scale", Vector2(1.25, 1.25), 0.06).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(node, "scale", Vector2(1.0, 1.0), 0.06).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _heart_flash() -> void:
	if hearts_row == null:
		return
	var t := create_tween()
	t.tween_property(hearts_row, "modulate", Color(1.0, 0.22, 0.22, 1.0), 0.05)
	t.tween_property(hearts_row, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.18)
