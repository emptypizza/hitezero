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

# ─── Reference DNA tokens (docs/duckflock_reference_goal_plan.md) ────────────
# Timing spec measured from the duck-flock reference at 67 ms frame steps:
# muzzle/hit flashes live 1–2 frames, every kill chains pop → loot → counter
# inside ~300 ms, toasts slide in under 270 ms. Constants below are the single
# source of truth for that spec — new VFX/UI must reference these, not literals.
const FLASH_LIFE := 0.13           # s — hot flash lifetime (≤2 frames @15fps ref)
const HIT_BURST_LIFE := 0.14       # s — non-destroy hit ring lifetime
const KILL_CHAIN_BUDGET := 0.30    # s — destroy → last feedback onset budget
const TOAST_IN_TIME := 0.22        # s — toast slide-in (AC ≤ 0.27)
const TOAST_HOLD_TIME := 2.2       # s — toast hold before fade-out
const TOAST_OUT_TIME := 0.25       # s — toast fade/slide-out

# Restraint rule from the reference: at most 2 glow hues on screen at once.
const GLOW_PRIMARY := Color(0.0, 1.0, 1.0, 1.0)    # cyan — combat glow
const GLOW_REWARD := Color(1.0, 0.84, 0.30, 1.0)   # warm gold — loot/reward
const UI_CARD_BG := Color(0.97, 0.97, 0.99, 1.0)   # white rounded card
const UI_CARD_TEXT := Color(0.10, 0.11, 0.16, 1.0) # bold dark text on card
const UI_BANNER_GOLD := Color(1.0, 0.76, 0.18, 1.0)

# ─── Coin shards (kill-chain loot moment) ──────────────────────────────────
const COIN_SHARDS_MIN := 4         # every destroy spawns at least this many
const COIN_SHARDS_MAX := 6
const COIN_SCATTER_TIME := 0.25    # s — free scatter before magnet kicks in
const COIN_MAGNET_ACCEL := 2600.0  # px/s² toward the paddle
const COIN_COLLECT_DIST := 26.0    # px — collected when this close
const COIN_LIFETIME := 2.5         # s — hard cap so shards never linger

# ─── Group kill (simultaneous-destroy bonus) ────────────────────────────────
const GROUP_KILL_WINDOW := 0.5     # s — chain window, extended by each destroy
const GROUP_KILL_MIN := 5          # destroys inside one window to trigger
const GROUP_KILL_DMG_BONUS := 1    # run-scoped +damage per stack

# ─── In-run level-up choices (3-card roguelite pick) ────────────────────────
# Mix of run-permanent stats and timed buffs, mirroring the reference popup
# (攻撃力↑ / 体力↑ / 攻撃力2倍 18秒). Picked every stage clear.
const LEVELUP_CHOICE_COUNT := 3
const RUN_BUFF_DOUBLE_DAMAGE := "DOUBLE_DMG"
const RUN_BUFF_PIERCE := "PIERCE"
const LEVELUP_OPTIONS: Array = [
	{"key": "damage", "name": "DAMAGE +1", "desc": "Every knife hits harder", "kind": "perm"},
	{"key": "knife", "name": "KNIFE +1", "desc": "One more knife per volley", "kind": "perm"},
	{"key": "speed", "name": "SPEED +10%", "desc": "Faster knives", "kind": "perm"},
	{"key": "tray", "name": "TRAY +12", "desc": "Wider paddle", "kind": "perm"},
	{"key": "double_dmg", "name": "2x DAMAGE 18s", "desc": "Timed power spike", "kind": "buff", "buff": RUN_BUFF_DOUBLE_DAMAGE, "duration": 18.0},
	{"key": "pierce", "name": "PIERCE 12s", "desc": "Knives pass through", "kind": "buff", "buff": RUN_BUFF_PIERCE, "duration": 12.0},
]

# ─── Game speed toggle (mobile QoL, reference ⏩ x2 button) ─────────────────
# Applied to the simulation delta only — hit-stop, shake, flash and HUD tweens
# stay on real time so impacts keep their weight at double speed.
const GAME_SPEED_FAST := 2.0

# ─── CEL 2.5D pass (subculture cel-slab look, 2026-06-13) ───────────────────
# Single source of truth for the fake-3D depth pass: blocks read as thick
# cel-shaded tiles extruded toward a canvas-centre vanishing point, grounded
# by a key-light drop shadow. Draw-only — AABBs and sim state never change.
const CEL_INK := Color(0.13, 0.09, 0.22, 1.0)          # manga ink outline tone
const CEL_SHADOW_COLOR := Color(0.08, 0.05, 0.18, 1.0) # purple-ink drop shadow
const CEL_SHADOW_ALPHA := 0.32
const CEL_SLAB_THICKNESS := 7.0     # px of fake depth below each card
const CEL_SLAB_PERSPECTIVE := 0.045 # horizontal extrusion per px from centre
const CEL_SLAB_MAX_SIDE := 7.0      # clamp so edge columns stay tidy
# Side-face base tints per card type (bottom face uses the same tint darker).
# RED_ENEMY is intentionally absent: the blob keeps its organic silhouette and
# only receives a soft contact shadow, never a slab.
const CEL_SIDE_COLORS: Dictionary = {
	BLOCK_NORMAL: Color(0.34, 0.19, 0.13, 1.0),
	BLOCK_STAR: Color(0.58, 0.54, 0.68, 1.0),
	BLOCK_POW: Color(0.11, 0.09, 0.16, 1.0),
}
