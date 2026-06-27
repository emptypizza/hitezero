extends CanvasLayer
class_name Hud

const GameConstants = preload("res://scripts/game_constants.gd")
const HUD_FONT: Font = preload("res://assets/fonts/PressStart2P-Regular.ttf")
const ICON_HEART: Texture2D = preload("res://assets/textures/ui/heart.png")
const ICON_KNIFE: Texture2D = preload("res://assets/textures/ui/knife_icon.png")
const ICON_STAR: Texture2D = preload("res://assets/textures/ui/star.png")

signal title_requested
signal collider_debug_toggled(enabled: bool)
signal speed_toggled(fast: bool)
signal levelup_chosen(option_key: String)
signal pause_toggled  # NEW-01: pause pill pressed (game_root owns the state)
signal revive_requested  # game-over REVIVE button (coin continue)

var hearts_row: HBoxContainer
var knife_count_label: Label
var overlay_root: Control
var overlay_bg: ColorRect
var overlay_panel: PanelContainer
var overlay_title: Label
var overlay_info: Label
var overlay_subinfo: Label
var overlay_retry: Label
var overlay_revive_btn: Button
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

# ─── Reference-DNA UI (duckflock goal plan) ────────────────────────────────
var pill_panel: PanelContainer       # top-centre objective pill: ★ n/m
var pill_label: Label
var speed_button: Button             # ⏩ x2 toggle (bottom centre)
var mute_button: Button
var pause_button: Button             # NEW-01: ❚❚ pause pill (bottom centre)
var pause_root: Control              # NEW-01: dim + "PAUSED" overlay
var pause_title_label: Label
var pause_hint_label: Label
var group_chip_label: Label          # "ATK +n" group-kill stack chip
var buff_label: Label                # timed run-buff readout (2xDMG 12s …)
var levelup_root: Control
var levelup_cards_box: VBoxContainer
var levelup_banner: PanelContainer
var _toast_root: Control
var _toasts: Array[PanelContainer] = []
var speed_fast: bool = false
var muted: bool = false

const _TOAST_WIDTH := 158.0
const _TOAST_HEIGHT := 26.0
const _TOAST_GAP := 6.0
const _TOAST_BASE_Y := GameConstants.TOP_BAR_HEIGHT + 34.0
const _TOAST_MAX := 3

const _PANEL_POS := Vector2(40.0, 215.0)

var _prev_hearts: int = -1
var _prev_knife_count: int = -1
var _prev_stars_left: int = -1
var _prev_stars_collected: int = -1
var _prev_combo: int = -1
var _prev_score: int = -1
var _prev_level: int = -1
var _prev_group_bonus: int = 0


func _ready() -> void:
	layer = 20
	_build_ui()


func update_ui(data: Dictionary) -> void:
	var new_hearts := clampi(int(data.get("hearts", 0)), 0, Session.get_max_hearts())
	var new_knife_count := int(data.get("knife_count", 0))
	var new_stars_left := int(data.get("stars_left", 0))
	var new_stars_total := int(data.get("stars_total", new_stars_left))
	var new_stars_collected := clampi(new_stars_total - new_stars_left, 0, new_stars_total)
	var new_combo := int(data.get("combo", 0))
	var combo_timer_val := float(data.get("combo_timer", 0.0))
	var new_score := int(data.get("score", 0))
	var new_level := int(data.get("level", 1))
	var group_bonus := int(data.get("group_dmg_bonus", 0))

	if _prev_hearts >= 0:
		if new_hearts < _prev_hearts:
			_heart_flash()
		if new_knife_count != _prev_knife_count:
			_punch_scale(knife_count_label)
		if new_stars_collected > _prev_stars_collected:
			_pill_flip()
		if new_combo > _prev_combo and new_combo >= 3:
			_punch_scale(combo_label)
		if new_score > _prev_score and _prev_score >= 0:
			_punch_scale(score_label)
		if group_bonus > _prev_group_bonus:
			_punch_scale(group_chip_label)

	_prev_hearts = new_hearts
	_prev_knife_count = new_knife_count
	_prev_stars_left = new_stars_left
	_prev_stars_collected = new_stars_collected
	_prev_combo = new_combo
	_prev_score = new_score
	_prev_level = new_level
	_prev_group_bonus = group_bonus

	_refresh_hearts(new_hearts)
	knife_count_label.text = "%02d" % new_knife_count
	_refresh_pill(new_stars_collected, new_stars_total)
	_refresh_score(new_score, new_level)
	_refresh_combo(new_combo, combo_timer_val)
	_refresh_items(data.get("item_slots", []), data.get("item_timers", []))
	_refresh_group_chip(group_bonus)
	_refresh_run_buffs(data.get("run_buffs", {}))


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
	if _reduce_motion():
		overlay_title.scale = Vector2.ONE
		return
	overlay_title.pivot_offset = overlay_title.size / 2.0
	var tw := create_tween()
	tw.tween_property(overlay_title, "scale", Vector2(1.2, 1.2), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(overlay_title, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func show_game_over(score: int, level: int, best_score: int, best_stage: int = 0, revive_cost: int = 0, can_revive: bool = false) -> void:
	overlay_root.visible = true
	overlay_bg.color = Color(0.0, 0.0, 0.0, 0.82)
	overlay_title.text = "GAME OVER"
	overlay_title.modulate = Color(0.94, 0.27, 0.27, 1.0)
	overlay_title.scale = Vector2.ONE
	overlay_info.text = "Score: 0"
	overlay_retry.text = "Tap to retry"
	overlay_retry.modulate = Color(0.86, 0.89, 0.95, 0.0)

	# Coin-revive button: continue the same run when the player can afford it.
	if can_revive:
		overlay_revive_btn.visible = true
		overlay_revive_btn.text = "REVIVE   %d coins" % revive_cost
		overlay_revive_btn.modulate = Color(1.0, 0.85, 0.2, 1.0)
	else:
		overlay_revive_btn.visible = false

	# Panel drops from above (snap into place under reduce-motion)
	overlay_panel.position = Vector2(_PANEL_POS.x, -180.0)
	if _reduce_motion():
		overlay_panel.position = _PANEL_POS
	else:
		var drop_tw := create_tween()
		drop_tw.tween_property(overlay_panel, "position:y", _PANEL_POS.y, 0.45).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	# Score count-up animation (snap to final under reduce-motion)
	if _reduce_motion():
		overlay_info.text = "Score: %d" % score
	else:
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
		if not _reduce_motion():
			var flash_tw := create_tween().set_loops(3)
			flash_tw.tween_property(overlay_subinfo, "modulate:a", 0.25, 0.18)
			flash_tw.tween_property(overlay_subinfo, "modulate:a", 1.0, 0.18)
	else:
		overlay_subinfo.text = "Best: %d   ·   Best Stage %d" % [best_score, best_stage]
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
	if overlay_revive_btn != null:
		overlay_revive_btn.visible = false
	hide_boss_ui()
	hide_levelup()


func punch_score() -> void:
	# Public hook: coin shards punch the score label as they bank.
	_punch_scale(score_label)


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
	knife_icon.position = Vector2(96.0, 11.0)
	knife_icon.size = Vector2(20.0, 20.0)
	knife_icon.texture = ICON_KNIFE
	knife_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	knife_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	knife_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	knife_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(knife_icon)

	knife_count_label = Label.new()
	knife_count_label.position = Vector2(120.0, 12.0)
	knife_count_label.size = Vector2(40.0, 22.0)
	knife_count_label.pivot_offset = Vector2(20.0, 11.0)
	knife_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	knife_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	knife_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_font(knife_count_label, 10)
	root.add_child(knife_count_label)

	# Objective pill (reference: top-centre skull 0/1) — star progress n/m.
	pill_panel = PanelContainer.new()
	pill_panel.position = Vector2(GameConstants.CANVAS_WIDTH * 0.5 - 41.0, 9.0)
	pill_panel.custom_minimum_size = Vector2(82.0, 30.0)
	pill_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pill_style := StyleBoxFlat.new()
	pill_style.bg_color = Color(0.05, 0.06, 0.10, 0.96)
	pill_style.set_border_width_all(1)
	pill_style.border_color = Color(GameConstants.GLOW_REWARD.r, GameConstants.GLOW_REWARD.g, GameConstants.GLOW_REWARD.b, 0.65)
	pill_style.set_corner_radius_all(15)
	pill_style.content_margin_left = 10.0
	pill_style.content_margin_right = 10.0
	pill_style.content_margin_top = 4.0
	pill_style.content_margin_bottom = 4.0
	pill_panel.add_theme_stylebox_override("panel", pill_style)
	root.add_child(pill_panel)

	var pill_box := HBoxContainer.new()
	pill_box.alignment = BoxContainer.ALIGNMENT_CENTER
	pill_box.add_theme_constant_override("separation", 5)
	pill_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill_panel.add_child(pill_box)

	var pill_star := TextureRect.new()
	pill_star.custom_minimum_size = Vector2(16.0, 16.0)
	pill_star.texture = ICON_STAR
	pill_star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pill_star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pill_star.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pill_star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill_box.add_child(pill_star)

	pill_label = Label.new()
	pill_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pill_label.modulate = Color(0.98, 0.82, 0.26, 1.0)
	pill_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill_label.text = "0/0"
	_apply_font(pill_label, 10)
	pill_box.add_child(pill_label)

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
	# Let game-over taps fall through to game_root._unhandled_input (restart);
	# only the REVIVE button below consumes input, so button = revive, rest = restart.
	overlay_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
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

	# Coin-revive button (shown on game-over only when affordable). It's the one
	# overlay child that consumes input — taps elsewhere fall through to restart.
	overlay_revive_btn = Button.new()
	overlay_revive_btn.visible = false
	overlay_revive_btn.focus_mode = Control.FOCUS_NONE
	_apply_font(overlay_revive_btn, 9)
	overlay_revive_btn.pressed.connect(func() -> void:
		AudioManager.play("ui_click")
		revive_requested.emit()
	)
	vbox.add_child(overlay_revive_btn)

	overlay_retry = Label.new()
	overlay_retry.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_retry.modulate = Color(0.86, 0.89, 0.95, 0.0)
	_apply_font(overlay_retry, 8)
	vbox.add_child(overlay_retry)

	# ─── Group-kill stack chip (top-left, under top bar) ──────────────────
	group_chip_label = Label.new()
	group_chip_label.position = Vector2(10.0, GameConstants.TOP_BAR_HEIGHT + 6.0)
	group_chip_label.size = Vector2(130.0, 14.0)
	group_chip_label.pivot_offset = Vector2(20.0, 7.0)
	group_chip_label.modulate = Color(0.98, 0.82, 0.26, 1.0)
	group_chip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group_chip_label.visible = false
	_apply_font(group_chip_label, 7)
	root.add_child(group_chip_label)

	# ─── Timed run-buff readout (above item slots) ─────────────────────────
	buff_label = Label.new()
	buff_label.position = Vector2(GameConstants.CANVAS_WIDTH - 170.0, GameConstants.CANVAS_HEIGHT - 62.0)
	buff_label.size = Vector2(160.0, 14.0)
	buff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	buff_label.modulate = Color(0.98, 0.82, 0.26, 1.0)
	buff_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	buff_label.visible = false
	_apply_font(buff_label, 7)
	root.add_child(buff_label)

	# ─── In-game speed + mute buttons (reference ⏩ x2 / 🔇, bottom centre) ─
	speed_button = _make_pill_button("x2", Vector2(GameConstants.CANVAS_WIDTH * 0.5 - 52.0, GameConstants.CANVAS_HEIGHT - 34.0))
	speed_button.pressed.connect(_on_speed_button_pressed)
	root.add_child(speed_button)

	mute_button = _make_pill_button("SND", Vector2(GameConstants.CANVAS_WIDTH * 0.5 + 8.0, GameConstants.CANVAS_HEIGHT - 34.0))
	mute_button.pressed.connect(_on_mute_button_pressed)
	root.add_child(mute_button)

	# NEW-02: restore the persisted mute state before the first sound plays.
	muted = Session.sound_muted
	if muted:
		mute_button.text = "OFF"
		_style_pill_button(mute_button, true)
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)

	# NEW-01: pause pill, left of the x2 toggle.
	pause_button = _make_pill_button("II", Vector2(GameConstants.CANVAS_WIDTH * 0.5 - 112.0, GameConstants.CANVAS_HEIGHT - 34.0))
	pause_button.pressed.connect(_on_pause_button_pressed)
	root.add_child(pause_button)
	_build_pause_overlay(root)

	# ─── Level-up 3-card overlay (reference レベルアップ!! popup) ───────────
	_build_levelup_ui(root)

	# ─── Toast root (top-right sliding cards) — last so toasts draw on top ─
	_toast_root = Control.new()
	_toast_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_toast_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_toast_root)

	update_ui({
		"hearts": Session.get_max_hearts(),
		"knife_count": Session.get_starting_knives(),
		"stars_left": 0,
	})
	hide_overlay()
	hide_levelup()


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

	# Flash animation (skip the looping blink under reduce-motion — photosensitivity)
	if not _reduce_motion():
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
	boss_phase_label.scale = Vector2.ONE
	boss_phase_label.pivot_offset = boss_phase_label.size / 2.0

	var tw := create_tween()
	if not _reduce_motion():
		boss_phase_label.scale = Vector2.ZERO
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


func _reduce_motion() -> bool:
	# Screen Shake "Off" (shake_scale 0) also suppresses HUD juice — punch/flash/
	# flip scaling and every looping blink — for motion-sensitive and
	# photosensitive players. Mirrors how game_root gates camera shake on the
	# same setting, so the accessibility toggle is honored end-to-end.
	return Session.shake_scale <= 0.0


func _punch_scale(node: Control) -> void:
	if node == null:
		return
	node.scale = Vector2.ONE
	if _reduce_motion():
		return
	var t := create_tween()
	t.tween_property(node, "scale", Vector2(1.25, 1.25), 0.06).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(node, "scale", Vector2(1.0, 1.0), 0.06).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _heart_flash() -> void:
	if hearts_row == null:
		return
	if _reduce_motion():
		hearts_row.modulate = Color(1.0, 1.0, 1.0, 1.0)
		return
	var t := create_tween()
	t.tween_property(hearts_row, "modulate", Color(1.0, 0.22, 0.22, 1.0), 0.05)
	t.tween_property(hearts_row, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.18)


# ─── Objective pill ──────────────────────────────────────────────────────────

func _refresh_pill(collected: int, total: int) -> void:
	if pill_label == null:
		return
	pill_label.text = "%d/%d" % [collected, total]
	# Full set reads as "done": pill text flips to the reward green.
	if total > 0 and collected >= total:
		pill_label.modulate = Color(0.35, 1.0, 0.55, 1.0)
	else:
		pill_label.modulate = Color(0.98, 0.82, 0.26, 1.0)


func _pill_flip() -> void:
	# Counter-flip on collect (reference: skull pill flips 0/1 → 1/1 within a frame).
	if pill_panel == null:
		return
	if _reduce_motion():
		pill_panel.scale = Vector2.ONE
		pill_panel.modulate = Color.WHITE
		return
	pill_panel.pivot_offset = pill_panel.size * 0.5
	pill_panel.scale = Vector2.ONE
	var t := create_tween()
	t.tween_property(pill_panel, "scale:y", 0.15, 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.tween_property(pill_panel, "scale:y", 1.0, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var glow := create_tween()
	glow.tween_property(pill_panel, "modulate", Color(1.6, 1.5, 1.0, 1.0), 0.05)
	glow.tween_property(pill_panel, "modulate", Color.WHITE, 0.22)


# ─── Group-kill chip + timed run buffs ───────────────────────────────────────

func _refresh_group_chip(bonus: int) -> void:
	if group_chip_label == null:
		return
	group_chip_label.visible = bonus > 0
	if bonus > 0:
		group_chip_label.text = "ATK +%d" % bonus


func _refresh_run_buffs(buffs: Dictionary) -> void:
	if buff_label == null:
		return
	if buffs.is_empty():
		buff_label.visible = false
		return
	var parts: Array[String] = []
	for key in buffs.keys():
		var remaining := ceili(float(buffs[key]))
		match key:
			GameConstants.RUN_BUFF_DOUBLE_DAMAGE:
				parts.append("2xDMG %ds" % remaining)
			GameConstants.RUN_BUFF_PIERCE:
				parts.append("PIERCE %ds" % remaining)
			_:
				parts.append("%s %ds" % [str(key), remaining])
	buff_label.text = "  ".join(parts)
	buff_label.visible = true


# ─── Toast system (reference: top-right "Group Kill / Attack +90" card) ──────

func show_toast(text: String, accent: Color = GameConstants.GLOW_REWARD) -> void:
	if _toast_root == null:
		return
	# Cap the stack: drop the oldest immediately so new info always lands.
	while _toasts.size() >= _TOAST_MAX:
		_dismiss_toast(_toasts[_toasts.size() - 1], true)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(_TOAST_WIDTH, _TOAST_HEIGHT)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = GameConstants.UI_CARD_BG
	style.set_corner_radius_all(13)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	style.shadow_size = 4
	style.content_margin_left = 8.0
	style.content_margin_right = 10.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	card.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)

	var accent_bar := ColorRect.new()
	accent_bar.custom_minimum_size = Vector2(4.0, 14.0)
	accent_bar.color = accent
	accent_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(accent_bar)

	var label := Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", GameConstants.UI_CARD_TEXT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_font(label, 7)
	row.add_child(label)

	_toast_root.add_child(card)
	_toasts.insert(0, card)

	# Slide in from the right edge inside TOAST_IN_TIME (AC ≤ 270 ms).
	card.position = Vector2(GameConstants.CANVAS_WIDTH + 8.0, _TOAST_BASE_Y)
	card.modulate.a = 0.0
	var target_x := GameConstants.CANVAS_WIDTH - _TOAST_WIDTH - 8.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(card, "position:x", target_x, GameConstants.TOAST_IN_TIME) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "modulate:a", 1.0, GameConstants.TOAST_IN_TIME * 0.6)
	tw.chain().tween_interval(GameConstants.TOAST_HOLD_TIME)
	tw.chain().tween_callback(_dismiss_toast.bind(card, false))

	_relayout_toasts()


func _dismiss_toast(card: PanelContainer, instant: bool) -> void:
	if card == null or not is_instance_valid(card):
		return
	_toasts.erase(card)
	if instant:
		card.queue_free()
	else:
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(card, "position:x", GameConstants.CANVAS_WIDTH + 8.0, GameConstants.TOAST_OUT_TIME) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.tween_property(card, "modulate:a", 0.0, GameConstants.TOAST_OUT_TIME)
		tw.chain().tween_callback(card.queue_free)
	_relayout_toasts()


func _relayout_toasts() -> void:
	for i in range(_toasts.size()):
		var card := _toasts[i]
		if not is_instance_valid(card):
			continue
		var target_y := _TOAST_BASE_Y + float(i) * (_TOAST_HEIGHT + _TOAST_GAP)
		var tw := create_tween()
		tw.tween_property(card, "position:y", target_y, 0.15) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


# ─── Speed / mute pill buttons ───────────────────────────────────────────────

func _make_pill_button(text: String, pos: Vector2) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.position = pos
	btn.size = Vector2(44.0, 24.0)
	btn.focus_mode = Control.FOCUS_NONE
	_apply_font(btn, 8)
	_style_pill_button(btn, false)
	return btn


func _style_pill_button(btn: Button, active: bool) -> void:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(12)
	style.set_border_width_all(1)
	if active:
		style.bg_color = Color(GameConstants.GLOW_REWARD.r, GameConstants.GLOW_REWARD.g, GameConstants.GLOW_REWARD.b, 0.92)
		style.border_color = Color(1.0, 0.95, 0.70, 0.9)
		btn.add_theme_color_override("font_color", GameConstants.UI_CARD_TEXT)
		btn.add_theme_color_override("font_pressed_color", GameConstants.UI_CARD_TEXT)
		btn.add_theme_color_override("font_hover_color", GameConstants.UI_CARD_TEXT)
	else:
		style.bg_color = Color(0.07, 0.08, 0.13, 0.85)
		style.border_color = Color(0.0, 1.0, 1.0, 0.35)
		btn.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95, 0.9))
		btn.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	for state_name in ["normal", "hover", "pressed", "focus"]:
		btn.add_theme_stylebox_override(state_name, style)


func _on_speed_button_pressed() -> void:
	AudioManager.play("ui_click")
	speed_fast = not speed_fast
	speed_button.text = "x2" if not speed_fast else "x2 ON"
	speed_button.size = Vector2(44.0, 24.0) if not speed_fast else Vector2(58.0, 24.0)
	_style_pill_button(speed_button, speed_fast)
	speed_toggled.emit(speed_fast)


func _on_mute_button_pressed() -> void:
	muted = not muted
	mute_button.text = "OFF" if muted else "SND"
	_style_pill_button(mute_button, muted)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), muted)
	Session.set_sound_muted(muted)  # NEW-02: persist across sessions
	if not muted:
		AudioManager.play("ui_click")


# ─── NEW-01: pause pill + overlay ────────────────────────────────────────────

func _on_pause_button_pressed() -> void:
	AudioManager.play("ui_click")
	pause_toggled.emit()


func _build_pause_overlay(root: Control) -> void:
	# Visual-only: every layer ignores the mouse so the resume tap falls
	# through to game_root._unhandled_input (which also guards aiming).
	pause_root = Control.new()
	pause_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_root.visible = false
	root.add_child(pause_root)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.06, 0.62)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_root.add_child(dim)

	pause_title_label = Label.new()
	pause_title_label.text = "PAUSED"
	pause_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_title_label.position = Vector2(0.0, GameConstants.CANVAS_HEIGHT * 0.42)
	pause_title_label.size = Vector2(GameConstants.CANVAS_WIDTH, 30.0)
	pause_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_title_label.modulate = Color(0.86, 0.95, 1.0, 1.0)
	_apply_font(pause_title_label, 22)
	pause_root.add_child(pause_title_label)

	pause_hint_label = Label.new()
	pause_hint_label.text = "TAP TO RESUME"
	pause_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_hint_label.position = Vector2(0.0, GameConstants.CANVAS_HEIGHT * 0.42 + 42.0)
	pause_hint_label.size = Vector2(GameConstants.CANVAS_WIDTH, 16.0)
	pause_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_hint_label.modulate = Color(0.62, 0.74, 0.86, 0.9)
	_apply_font(pause_hint_label, 9)
	pause_root.add_child(pause_hint_label)


func set_paused(paused: bool) -> void:
	if pause_root != null:
		pause_root.visible = paused
	if pause_button != null:
		pause_button.text = ">" if paused else "II"
		_style_pill_button(pause_button, paused)


# ─── Level-up 3-card overlay ─────────────────────────────────────────────────

func _build_levelup_ui(root: Control) -> void:
	levelup_root = Control.new()
	levelup_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	levelup_root.visible = false
	levelup_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(levelup_root)

	# Dim background swallows clicks so gameplay input can't fire underneath.
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	levelup_root.add_child(dim)

	levelup_banner = PanelContainer.new()
	levelup_banner.position = Vector2(50.0, 150.0)
	levelup_banner.custom_minimum_size = Vector2(GameConstants.CANVAS_WIDTH - 100.0, 44.0)
	levelup_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var banner_style := StyleBoxFlat.new()
	banner_style.bg_color = GameConstants.UI_BANNER_GOLD
	banner_style.set_corner_radius_all(14)
	banner_style.shadow_color = Color(0.0, 0.0, 0.0, 0.4)
	banner_style.shadow_size = 5
	levelup_banner.add_theme_stylebox_override("panel", banner_style)
	levelup_root.add_child(levelup_banner)

	var banner_label := Label.new()
	banner_label.text = "LEVEL UP!"
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner_label.add_theme_color_override("font_color", Color(0.16, 0.10, 0.02, 1.0))
	banner_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_font(banner_label, 14)
	levelup_banner.add_child(banner_label)

	levelup_cards_box = VBoxContainer.new()
	levelup_cards_box.position = Vector2(40.0, 216.0)
	levelup_cards_box.size = Vector2(GameConstants.CANVAS_WIDTH - 80.0, 220.0)
	levelup_cards_box.add_theme_constant_override("separation", 12)
	levelup_root.add_child(levelup_cards_box)


func show_levelup(options: Array) -> void:
	for child in levelup_cards_box.get_children():
		child.queue_free()
	for option in options:
		levelup_cards_box.add_child(_make_levelup_card(option))

	levelup_root.visible = true
	levelup_banner.pivot_offset = levelup_banner.custom_minimum_size * 0.5
	levelup_banner.scale = Vector2(0.4, 0.4)
	var tw := create_tween()
	tw.tween_property(levelup_banner, "scale", Vector2(1.06, 1.06), 0.13) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(levelup_banner, "scale", Vector2.ONE, 0.08)
	AudioManager.play("stage_clear", 1.3)


func hide_levelup() -> void:
	if levelup_root != null:
		levelup_root.visible = false


func _make_levelup_card(option: Dictionary) -> Button:
	var card := Button.new()
	card.custom_minimum_size = Vector2(GameConstants.CANVAS_WIDTH - 80.0, 52.0)
	card.focus_mode = Control.FOCUS_NONE

	var normal := StyleBoxFlat.new()
	normal.bg_color = GameConstants.UI_CARD_BG
	normal.set_corner_radius_all(14)
	normal.set_border_width_all(2)
	normal.border_color = Color(0.45, 0.62, 0.95, 0.85)
	normal.shadow_color = Color(0.0, 0.0, 0.0, 0.3)
	normal.shadow_size = 4
	var hover := normal.duplicate()
	hover.bg_color = Color(0.90, 0.95, 1.0, 1.0)
	var pressed := normal.duplicate()
	pressed.border_color = GameConstants.UI_BANNER_GOLD
	pressed.bg_color = Color(1.0, 0.97, 0.86, 1.0)
	card.add_theme_stylebox_override("normal", normal)
	card.add_theme_stylebox_override("hover", hover)
	card.add_theme_stylebox_override("pressed", pressed)
	card.add_theme_stylebox_override("focus", normal)

	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 12.0
	row.offset_right = -12.0
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)

	var star := TextureRect.new()
	star.custom_minimum_size = Vector2(18.0, 18.0)
	star.texture = ICON_STAR
	star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	star.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	star.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(star)

	var text_box := VBoxContainer.new()
	text_box.alignment = BoxContainer.ALIGNMENT_CENTER
	text_box.add_theme_constant_override("separation", 3)
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text_box)

	var name_label := Label.new()
	name_label.text = str(option.get("name", "?"))
	name_label.add_theme_color_override("font_color", GameConstants.UI_CARD_TEXT)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_font(name_label, 9)
	text_box.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = str(option.get("desc", ""))
	desc_label.add_theme_color_override("font_color", Color(0.45, 0.48, 0.58, 1.0))
	desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_font(desc_label, 6)
	text_box.add_child(desc_label)

	var key := str(option.get("key", ""))
	card.pressed.connect(func() -> void:
		AudioManager.play("ui_click", 1.15)
		# Reference AC: pick → play resumes within 1–2 frames. Hide first,
		# then signal so the game advances on this same frame.
		hide_levelup()
		levelup_chosen.emit(key)
	)
	return card
