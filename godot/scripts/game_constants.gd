extends RefCounted
class_name GameConstants

const CANVAS_WIDTH := 400.0
const CANVAS_HEIGHT := 700.0
const CANVAS_SIZE := Vector2(CANVAS_WIDTH, CANVAS_HEIGHT)
const BOTTOM_Y := 620.0
const BALL_SPEED := 12.0 * 60.0
const BLOCK_COLS := 7
const BLOCK_WIDTH := CANVAS_WIDTH / float(BLOCK_COLS)
const BLOCK_HEIGHT := BLOCK_WIDTH
const PADDLE_SPEED := 420.0
const PADDLE_WIDTH := 80.0
const PADDLE_Y_OFFSET := 76.0
const TOP_BAR_HEIGHT := 50.0
const LEVEL_START_Y := TOP_BAR_HEIGHT + 24.0
const SPAWN_INTERVAL := 0.066
const HEARTS_MAX := 3
const KNIFE_RADIUS := 5.0

enum GameState {
    AIMING,
    SHOOTING,
    STAGE_CLEAR,
    GAME_OVER,
}

const BLOCK_NORMAL := "NORMAL"
const BLOCK_POW := "POW"
const BLOCK_STAR := "STAR"
const BLOCK_RED_ENEMY := "RED_ENEMY"

const COLOR_BG := Color(0.04, 0.04, 0.09, 1.0)
const COLOR_NEON := Color(0.0, 1.0, 1.0, 0.5)
const COLOR_NEON_SOFT := Color(0.14, 0.2, 0.32, 0.11)
const COLOR_NORMAL_FILL := Color(0.09, 0.09, 0.16, 1.0)
const COLOR_NORMAL_BORDER := Color(0.27, 0.27, 0.67, 1.0)
const COLOR_POW_FILL := Color(0.10, 0.04, 0.18, 1.0)
const COLOR_POW_BORDER := Color(1.0, 0.0, 1.0, 1.0)
const COLOR_STAR_FILL := Color(0.10, 0.10, 0.04, 1.0)
const COLOR_STAR_BORDER := Color(1.0, 0.8, 0.0, 1.0)
const COLOR_ENEMY_FILL := Color(0.16, 0.04, 0.04, 1.0)
const COLOR_ENEMY_BORDER := Color(1.0, 0.13, 0.27, 1.0)
const COLOR_TRAY := Color(0.1, 0.1, 0.18, 1.0)
const COLOR_TRAY_HIGHLIGHT := Color(0.0, 1.0, 1.0, 0.6)
