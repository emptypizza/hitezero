extends Node2D
class_name Block

const GameConstants = preload("res://scripts/game_constants.gd")

var label: Label

var block_type: String = GameConstants.BLOCK_NORMAL
var hp: int = 1
var max_hp: int = 1
var block_size := Vector2(GameConstants.BLOCK_WIDTH - 4.0, GameConstants.BLOCK_HEIGHT - 4.0)
var enemy_speed: float = 0.0
var enemy_active: bool = false
var flash_amount: float = 0.0


func _ready() -> void:
    _ensure_label()
    z_index = 3
    _sync_label()
    queue_redraw()


func _process(delta: float) -> void:
    if flash_amount > 0.0:
        flash_amount = maxf(0.0, flash_amount - delta * 4.0)
        queue_redraw()


func configure(new_type: String, new_hp: int, new_max_hp: int, new_size: Vector2) -> void:
    block_type = new_type
    hp = new_hp
    max_hp = new_max_hp
    block_size = new_size
    enemy_speed = 30.0 + float(hp) * 2.0 if block_type == GameConstants.BLOCK_RED_ENEMY else 0.0
    enemy_active = false
    _sync_label()
    queue_redraw()


func activate_enemy_motion() -> void:
    if block_type == GameConstants.BLOCK_RED_ENEMY:
        enemy_active = true


func advance_enemy(delta: float) -> void:
    if enemy_active and block_type == GameConstants.BLOCK_RED_ENEMY:
        position.y += enemy_speed * delta


func take_hit() -> int:
    hp = maxi(0, hp - 1)
    flash_amount = 1.0
    _sync_label()
    queue_redraw()
    return hp


func is_destroyed() -> bool:
    return hp <= 0


func get_aabb() -> Rect2:
    return Rect2(global_position - block_size * 0.5, block_size)


func get_hit_color() -> Color:
    match block_type:
        GameConstants.BLOCK_NORMAL:
            return Color(0.30, 0.78, 1.0, 1.0)
        GameConstants.BLOCK_STAR:
            return Color(1.0, 0.80, 0.24, 1.0)
        GameConstants.BLOCK_POW:
            return Color(1.0, 0.0, 1.0, 1.0)
        GameConstants.BLOCK_RED_ENEMY:
            return Color(0.94, 0.27, 0.27, 1.0)
        _:
            return Color(1.0, 1.0, 1.0, 1.0)


func _sync_label() -> void:
    _ensure_label()
    if label == null:
        return
    label.position = Vector2(-block_size.x * 0.5, -12.0)
    label.size = Vector2(block_size.x, 24.0)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.visible = block_type in [GameConstants.BLOCK_NORMAL, GameConstants.BLOCK_RED_ENEMY]
    label.text = str(hp)
    label.modulate = Color(1.0, 1.0, 1.0, 1.0) if block_type == GameConstants.BLOCK_RED_ENEMY else Color(0.08, 0.08, 0.08, 1.0)
    queue_redraw()


func _ensure_label() -> void:
    if label == null:
        label = get_node_or_null("Label") as Label


func _draw() -> void:
    var rect := Rect2(-block_size * 0.5, block_size)
    var fill := _get_fill_color()
    var border := _get_border_color()
    if flash_amount > 0.0:
        fill = fill.lerp(Color(1.0, 1.0, 1.0, 1.0), minf(0.6, flash_amount * 0.5))

    draw_rect(rect, fill, true)
    draw_rect(rect, border, false, 2.0)

    match block_type:
        GameConstants.BLOCK_NORMAL:
            draw_rect(Rect2(rect.position + Vector2(2.0, 2.0), Vector2(block_size.x - 4.0, 4.0)), Color(0.16, 0.16, 0.30, 0.75), true)
        GameConstants.BLOCK_STAR:
            _draw_star(rect)
        GameConstants.BLOCK_POW:
            _draw_pow(rect)
        GameConstants.BLOCK_RED_ENEMY:
            _draw_enemy(rect)


func _draw_star(rect: Rect2) -> void:
    var center := rect.get_center()
    var points := PackedVector2Array([
        center + Vector2(0.0, -14.0),
        center + Vector2(5.0, -4.0),
        center + Vector2(16.0, -4.0),
        center + Vector2(8.0, 3.0),
        center + Vector2(12.0, 14.0),
        center + Vector2(0.0, 8.0),
        center + Vector2(-12.0, 14.0),
        center + Vector2(-8.0, 3.0),
        center + Vector2(-16.0, -4.0),
        center + Vector2(-5.0, -4.0),
    ])
    draw_colored_polygon(points, Color(1.0, 0.86, 0.20, 0.85))


func _draw_pow(rect: Rect2) -> void:
    var center := rect.get_center()
    draw_circle(center, 10.0, Color(0.96, 0.44, 1.0, 0.95))
    draw_line(center + Vector2(-14.0, 0.0), center + Vector2(14.0, 0.0), Color(1.0, 0.70, 1.0, 0.9), 2.0)
    draw_line(center + Vector2(0.0, -14.0), center + Vector2(0.0, 14.0), Color(1.0, 0.70, 1.0, 0.9), 2.0)


func _draw_enemy(rect: Rect2) -> void:
    var left_eye := Vector2(rect.position.x + 16.0, rect.position.y + 22.0)
    var right_eye := Vector2(rect.position.x + rect.size.x - 16.0, rect.position.y + 22.0)
    draw_rect(Rect2(left_eye - Vector2(5.0, 5.0), Vector2(10.0, 10.0)), Color(1.0, 0.0, 0.0, 1.0), true)
    draw_rect(Rect2(right_eye - Vector2(5.0, 5.0), Vector2(10.0, 10.0)), Color(1.0, 0.0, 0.0, 1.0), true)
    draw_rect(Rect2(left_eye - Vector2(2.0, 2.0), Vector2(4.0, 4.0)), Color(1.0, 1.0, 1.0, 1.0), true)
    draw_rect(Rect2(right_eye - Vector2(2.0, 2.0), Vector2(4.0, 4.0)), Color(1.0, 1.0, 1.0, 1.0), true)
    draw_line(left_eye + Vector2(-8.0, -10.0), left_eye + Vector2(6.0, -6.0), Color(1.0, 0.26, 0.36, 1.0), 2.0)
    draw_line(right_eye + Vector2(8.0, -10.0), right_eye + Vector2(-6.0, -6.0), Color(1.0, 0.26, 0.36, 1.0), 2.0)


func _get_fill_color() -> Color:
    match block_type:
        GameConstants.BLOCK_NORMAL:
            return GameConstants.COLOR_NORMAL_FILL
        GameConstants.BLOCK_STAR:
            return GameConstants.COLOR_STAR_FILL
        GameConstants.BLOCK_POW:
            return GameConstants.COLOR_POW_FILL
        GameConstants.BLOCK_RED_ENEMY:
            return GameConstants.COLOR_ENEMY_FILL
        _:
            return Color(0.12, 0.12, 0.12, 1.0)


func _get_border_color() -> Color:
    match block_type:
        GameConstants.BLOCK_NORMAL:
            return GameConstants.COLOR_NORMAL_BORDER
        GameConstants.BLOCK_STAR:
            return GameConstants.COLOR_STAR_BORDER
        GameConstants.BLOCK_POW:
            return GameConstants.COLOR_POW_BORDER
        GameConstants.BLOCK_RED_ENEMY:
            return GameConstants.COLOR_ENEMY_BORDER
        _:
            return Color(1.0, 1.0, 1.0, 1.0)
