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

const HEART_BONUS_KNIVES := 1

# ─── Combo system ──────────────────────────────────────────────────────────
const COMBO_WINDOW := 0.8
const COMBO_TIERS: Array[int] = [3, 6, 10, 15]
const COMBO_MULTIPLIERS: Array[float] = [1.0, 1.5, 2.0, 3.0, 5.0]
const COMBO_COLORS: Array[Color] = [
	Color(0.86, 0.89, 0.95, 1.0),
	Color(0.40, 0.85, 1.0, 1.0),
	Color(0.30, 1.0, 0.50, 1.0),
	Color(1.0, 0.85, 0.0, 1.0),
	Color(1.0, 0.25, 0.85, 1.0),
]

# ─── Item system ───────────────────────────────────────────────────────────
enum ItemType {
	NONE = 0,
	PIERCE = 1,
	SPREAD = 2,
	MAGNET = 3,
	BLAST = 4,
	SHIELD = 5,
	SLOW = 6,
}

const ITEM_MAX_SLOTS := 2
const ITEM_DROP_BASE := 0.08
const ITEM_DROP_ENEMY := 0.25
const ITEM_PITY_STAGES := 3
const ITEM_DURATION := 8.0

const ITEM_NAMES: Dictionary = {
	ItemType.PIERCE: "PIERCE",
	ItemType.SPREAD: "SPREAD",
	ItemType.MAGNET: "MAGNET",
	ItemType.BLAST: "BLAST",
	ItemType.SHIELD: "SHIELD",
	ItemType.SLOW: "SLOW",
}

const ITEM_COLORS: Dictionary = {
	ItemType.PIERCE: Color(1.0, 0.45, 0.15, 1.0),
	ItemType.SPREAD: Color(0.30, 0.85, 1.0, 1.0),
	ItemType.MAGNET: Color(0.85, 0.25, 1.0, 1.0),
	ItemType.BLAST: Color(1.0, 0.15, 0.30, 1.0),
	ItemType.SHIELD: Color(0.30, 1.0, 0.55, 1.0),
	ItemType.SLOW: Color(0.65, 0.85, 1.0, 1.0),
}

const ITEM_ORB_RADIUS := 8.0
const ITEM_ORB_SPEED := 45.0

# ─── Boss system ───────────────────────────────────────────────────────────
const BOSS_STAGE_INTERVAL := 5
const BOSS_WARNING_DURATION := 1.5
const BOSS_DEFEAT_FREEZE := 0.4
const BOSS_DEFEAT_KNIFE_BONUS := 3
const BOSS_DEFEAT_SCORE_MULT := 5

enum BossType {
	SLIME = 0,
	MIRROR = 1,
	SPAWNER = 2,
	SPLITTER = 3,
	TIMEWEAVER = 4,
}

const BOSS_NAMES: Dictionary = {
	BossType.SLIME: "GIANT SLIME",
	BossType.MIRROR: "MIRROR PRISM",
	BossType.SPAWNER: "SPAWN MOTHER",
	BossType.SPLITTER: "THE DIVIDER",
	BossType.TIMEWEAVER: "TIME WEAVER",
}

const BOSS_COLORS: Dictionary = {
	BossType.SLIME: Color(0.30, 0.85, 0.40, 1.0),
	BossType.MIRROR: Color(0.50, 0.70, 1.0, 1.0),
	BossType.SPAWNER: Color(0.90, 0.25, 0.30, 1.0),
	BossType.SPLITTER: Color(0.85, 0.55, 0.15, 1.0),
	BossType.TIMEWEAVER: Color(0.65, 0.35, 1.0, 1.0),
}
