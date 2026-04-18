extends Node2D
class_name Player

const GameConstants = preload("res://scripts/game_constants.gd")

var visual_state := "idle"
var waiting_knives: int = 3
var show_waiting_knives: bool = true


func set_state(new_state: String) -> void:
    visual_state = new_state
    queue_redraw()


func set_waiting_knives(count: int, visible_now: bool) -> void:
    waiting_knives = count
    show_waiting_knives = visible_now
    queue_redraw()


func _draw() -> void:
    _draw_tray()
    _draw_maid()
    if show_waiting_knives:
        _draw_waiting_knives()


func _draw_tray() -> void:
    var tray_rect := Rect2(
        Vector2(-GameConstants.PADDLE_WIDTH * 0.5, -GameConstants.PADDLE_Y_OFFSET - 7.0),
        Vector2(GameConstants.PADDLE_WIDTH, 10.0)
    )
    draw_rect(tray_rect, GameConstants.COLOR_TRAY, true)
    draw_rect(tray_rect, GameConstants.COLOR_TRAY_HIGHLIGHT, false, 2.0)
    draw_rect(Rect2(tray_rect.position + Vector2(4.0, 1.0), Vector2(tray_rect.size.x - 8.0, 3.0)), Color(0.18, 0.18, 0.32, 1.0), true)
    draw_rect(Rect2(tray_rect.position + Vector2(GameConstants.PADDLE_WIDTH * 0.25, 2.0), Vector2(GameConstants.PADDLE_WIDTH * 0.5, 2.0)), GameConstants.COLOR_TRAY_HIGHLIGHT, true)


func _draw_maid() -> void:
    var tint := Color(0.75, 0.78, 0.86, 1.0)
    var dress := Color(0.22, 0.19, 0.68, 1.0)
    if visual_state == "gameover":
        tint = Color(0.60, 0.60, 0.64, 1.0)
        dress = Color(0.28, 0.28, 0.34, 1.0)

    var head_center := Vector2(0.0, -42.0)
    draw_circle(head_center, 16.0, tint)
    draw_rect(Rect2(head_center + Vector2(-14.0, -16.0), Vector2(28.0, 5.0)), Color(1.0, 1.0, 1.0, 1.0), true)
    draw_circle(head_center + Vector2(-5.0, -2.0), 2.0, Color(0.0, 0.0, 0.0, 1.0))
    draw_circle(head_center + Vector2(5.0, -2.0), 2.0, Color(0.0, 0.0, 0.0, 1.0))

    var body := PackedVector2Array([
        Vector2(-16.0, -16.0),
        Vector2(16.0, -16.0),
        Vector2(22.0, 16.0),
        Vector2(-22.0, 16.0),
    ])
    draw_colored_polygon(body, dress)

    var apron := PackedVector2Array([
        Vector2(-11.0, -12.0),
        Vector2(11.0, -12.0),
        Vector2(15.0, 14.0),
        Vector2(-15.0, 14.0),
    ])
    draw_colored_polygon(apron, Color(0.98, 0.98, 1.0, 1.0))

    var arm_y := -6.0
    if visual_state in ["throw", "clear"]:
        draw_line(Vector2(5.0, arm_y), Vector2(18.0, arm_y - 8.0), tint, 3.0)
        draw_line(Vector2(-5.0, arm_y), Vector2(-15.0, arm_y + 4.0), tint, 3.0)
    else:
        draw_line(Vector2(6.0, arm_y), Vector2(14.0, arm_y + 6.0), tint, 3.0)
        draw_line(Vector2(-6.0, arm_y), Vector2(-14.0, arm_y + 6.0), tint, 3.0)

    draw_line(Vector2(-6.0, 16.0), Vector2(-10.0, 28.0), tint, 3.0)
    draw_line(Vector2(6.0, 16.0), Vector2(10.0, 28.0), tint, 3.0)


func _draw_waiting_knives() -> void:
    var count := mini(waiting_knives, 12)
    if count <= 0:
        return

    var spacing := 6.0
    var offset_x := -((float(count - 1) * spacing) * 0.5)
    for i in count:
        var x := offset_x + float(i) * spacing
        draw_line(Vector2(x, 2.0), Vector2(x, 11.0), Color(0.85, 0.87, 0.92, 1.0), 2.0)
        draw_line(Vector2(x, 11.0), Vector2(x - 2.0, 13.0), Color(0.57, 0.25, 0.05, 1.0), 1.5)
        draw_line(Vector2(x, 11.0), Vector2(x + 2.0, 13.0), Color(0.57, 0.25, 0.05, 1.0), 1.5)
