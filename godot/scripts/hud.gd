extends CanvasLayer
class_name Hud

const GameConstants = preload("res://scripts/game_constants.gd")

signal title_requested
signal collider_debug_toggled(enabled: bool)

var hearts_label: Label
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
    hearts_label.text = "HP %d" % int(data.get("hearts", 0))
    knife_count_label.text = "KNIVES %02d" % int(data.get("knife_count", 0))
    stars_label.text = "GOAL * %d" % int(data.get("stars_left", 0))


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


func _build_ui() -> void:
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)

    var top_bar := ColorRect.new()
    top_bar.position = Vector2.ZERO
    top_bar.size = Vector2(GameConstants.CANVAS_WIDTH, GameConstants.TOP_BAR_HEIGHT)
    top_bar.color = Color(0.07, 0.07, 0.10, 0.96)
    top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(top_bar)

    hearts_label = Label.new()
    hearts_label.position = Vector2(12.0, 14.0)
    hearts_label.size = Vector2(88.0, 22.0)
    hearts_label.add_theme_font_size_override("font_size", 18)
    hearts_label.modulate = Color(0.95, 0.28, 0.28, 1.0)
    hearts_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(hearts_label)

    knife_count_label = Label.new()
    knife_count_label.position = Vector2(118.0, 14.0)
    knife_count_label.size = Vector2(140.0, 22.0)
    knife_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    knife_count_label.add_theme_font_size_override("font_size", 18)
    knife_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(knife_count_label)

    stars_label = Label.new()
    stars_label.position = Vector2(270.0, 14.0)
    stars_label.size = Vector2(118.0, 22.0)
    stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    stars_label.add_theme_font_size_override("font_size", 18)
    stars_label.modulate = Color(0.98, 0.82, 0.26, 1.0)
    stars_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(stars_label)

    var title_button := Button.new()
    title_button.text = "TITLE"
    title_button.position = Vector2(GameConstants.CANVAS_WIDTH - 84.0, 6.0)
    title_button.size = Vector2(72.0, 22.0)
    title_button.pressed.connect(func() -> void:
        title_requested.emit()
    )
    root.add_child(title_button)

    collider_button = Button.new()
    collider_button.text = "COL OFF"
    collider_button.position = Vector2(GameConstants.CANVAS_WIDTH - 174.0, 6.0)
    collider_button.size = Vector2(84.0, 22.0)
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
    overlay_title.add_theme_font_size_override("font_size", 28)
    vbox.add_child(overlay_title)

    overlay_info = Label.new()
    overlay_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    overlay_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    overlay_info.add_theme_font_size_override("font_size", 16)
    vbox.add_child(overlay_info)

    overlay_subinfo = Label.new()
    overlay_subinfo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    overlay_subinfo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    overlay_subinfo.add_theme_font_size_override("font_size", 14)
    overlay_subinfo.modulate = Color(0.86, 0.89, 0.95, 1.0)
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
