extends Node

const GameConstants = preload("res://scripts/game_constants.gd")
const SAVE_PATH := "user://save.cfg"

var best_score: int = 0
var best_stage: int = 0
var coins: int = 0

# ─── Upgrade levels ────────────────────────────────────────────────────────
var upgrade_knife: int = 0       # +1 starting knife per level (max 3)
var upgrade_heart: int = 0       # +1 max heart per level (max 2)
var upgrade_tray: int = 0        # +10 paddle width per level (max 3)
var upgrade_speed: int = 0       # +5% knife speed per level (max 4)
var upgrade_combo: int = 0       # +0.2s combo window per level (max 2)
var upgrade_item_slot: int = 0   # +1 item slot (max 1)
var upgrade_pow: int = 0         # +2 POW mini-knives per level (max 2)
var upgrade_drop: int = 0        # +3% item drop per level (max 3)

# ─── Stats ─────────────────────────────────────────────────────────────────
var total_runs: int = 0
var total_blocks_destroyed: int = 0
var total_enemies_destroyed: int = 0
var total_bosses_defeated: int = 0
var best_combo: int = 0
var total_items_collected: int = 0

var _save_dirty: bool = false
const _SAVE_INTERVAL := 2.0
var _save_timer: float = 0.0

# ─── Upgrade definitions ──────────────────────────────────────────────────
# { name, max_level, costs[], description }
const UPGRADES: Array = [
	{"key": "knife", "name": "KNIFE +1", "max": 3, "costs": [500, 1500, 4000], "desc": "Start with more knives"},
	{"key": "heart", "name": "HEART +1", "max": 2, "costs": [2000, 6000], "desc": "More max hearts"},
	{"key": "tray", "name": "TRAY +10", "max": 3, "costs": [800, 2400, 5000], "desc": "Wider paddle"},
	{"key": "speed", "name": "SPEED +5%", "max": 4, "costs": [300, 900, 2700, 8000], "desc": "Faster knives"},
	{"key": "combo", "name": "COMBO +0.2s", "max": 2, "costs": [1000, 3000], "desc": "Longer combo window"},
	{"key": "item_slot", "name": "SLOT +1", "max": 1, "costs": [5000], "desc": "Extra item slot"},
	{"key": "pow", "name": "POW +2", "max": 2, "costs": [1500, 4500], "desc": "More POW knives"},
	{"key": "drop", "name": "DROP +3%", "max": 3, "costs": [600, 1800, 5400], "desc": "Better item drops"},
]


func _ready() -> void:
	load_progress()


func _process(delta: float) -> void:
	if _save_dirty:
		_save_timer += delta
		if _save_timer >= _SAVE_INTERVAL:
			_flush_save()


func _flush_save() -> void:
	_save_dirty = false
	_save_timer = 0.0
	save_progress()


func _mark_dirty() -> void:
	_save_dirty = true


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _save_dirty:
			_flush_save()


func load_progress() -> void:
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	if err == OK:
		best_score = int(config.get_value("progress", "best_score", 0))
		best_stage = int(config.get_value("progress", "best_stage", 0))
		coins = int(config.get_value("progress", "coins", 0))

		upgrade_knife = int(config.get_value("upgrades", "knife", 0))
		upgrade_heart = int(config.get_value("upgrades", "heart", 0))
		upgrade_tray = int(config.get_value("upgrades", "tray", 0))
		upgrade_speed = int(config.get_value("upgrades", "speed", 0))
		upgrade_combo = int(config.get_value("upgrades", "combo", 0))
		upgrade_item_slot = int(config.get_value("upgrades", "item_slot", 0))
		upgrade_pow = int(config.get_value("upgrades", "pow", 0))
		upgrade_drop = int(config.get_value("upgrades", "drop", 0))

		total_runs = int(config.get_value("stats", "total_runs", 0))
		total_blocks_destroyed = int(config.get_value("stats", "total_blocks_destroyed", 0))
		total_enemies_destroyed = int(config.get_value("stats", "total_enemies_destroyed", 0))
		total_bosses_defeated = int(config.get_value("stats", "total_bosses_defeated", 0))
		best_combo = int(config.get_value("stats", "best_combo", 0))
		total_items_collected = int(config.get_value("stats", "total_items_collected", 0))


func save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "best_score", best_score)
	config.set_value("progress", "best_stage", best_stage)
	config.set_value("progress", "coins", coins)

	config.set_value("upgrades", "knife", upgrade_knife)
	config.set_value("upgrades", "heart", upgrade_heart)
	config.set_value("upgrades", "tray", upgrade_tray)
	config.set_value("upgrades", "speed", upgrade_speed)
	config.set_value("upgrades", "combo", upgrade_combo)
	config.set_value("upgrades", "item_slot", upgrade_item_slot)
	config.set_value("upgrades", "pow", upgrade_pow)
	config.set_value("upgrades", "drop", upgrade_drop)

	config.set_value("stats", "total_runs", total_runs)
	config.set_value("stats", "total_blocks_destroyed", total_blocks_destroyed)
	config.set_value("stats", "total_enemies_destroyed", total_enemies_destroyed)
	config.set_value("stats", "total_bosses_defeated", total_bosses_defeated)
	config.set_value("stats", "best_combo", best_combo)
	config.set_value("stats", "total_items_collected", total_items_collected)

	config.save(SAVE_PATH)
	_save_dirty = false
	_save_timer = 0.0


func submit_score(score: int) -> void:
	if score > best_score:
		best_score = score
	save_progress()


func submit_run(score: int, stage: int, combo_max: int) -> void:
	total_runs += 1
	if score > best_score:
		best_score = score
	if stage > best_stage:
		best_stage = stage
	if combo_max > best_combo:
		best_combo = combo_max
	save_progress()


func add_coins(amount: int) -> void:
	coins += amount
	_mark_dirty()


func get_upgrade_level(key: String) -> int:
	match key:
		"knife": return upgrade_knife
		"heart": return upgrade_heart
		"tray": return upgrade_tray
		"speed": return upgrade_speed
		"combo": return upgrade_combo
		"item_slot": return upgrade_item_slot
		"pow": return upgrade_pow
		"drop": return upgrade_drop
		_: return 0


func try_purchase_upgrade(key: String) -> bool:
	var current := get_upgrade_level(key)
	for u in UPGRADES:
		if u["key"] == key:
			var max_level: int = u["max"]
			if current >= max_level:
				return false
			var cost: int = u["costs"][current]
			if coins < cost:
				return false
			coins -= cost
			_set_upgrade_level(key, current + 1)
			save_progress()
			return true
	return false


func _set_upgrade_level(key: String, value: int) -> void:
	match key:
		"knife": upgrade_knife = value
		"heart": upgrade_heart = value
		"tray": upgrade_tray = value
		"speed": upgrade_speed = value
		"combo": upgrade_combo = value
		"item_slot": upgrade_item_slot = value
		"pow": upgrade_pow = value
		"drop": upgrade_drop = value


# ─── Computed values from upgrades ─────────────────────────────────────────

func get_starting_knives() -> int:
	return 3 + upgrade_knife


func get_max_hearts() -> int:
	return GameConstants.HEARTS_MAX + upgrade_heart


func get_paddle_width() -> float:
	return GameConstants.PADDLE_WIDTH + float(upgrade_tray) * 10.0


func get_knife_speed() -> float:
	return GameConstants.BALL_SPEED * (1.0 + float(upgrade_speed) * 0.05)


func get_combo_window() -> float:
	return GameConstants.COMBO_WINDOW + float(upgrade_combo) * 0.2


func get_item_max_slots() -> int:
	return GameConstants.ITEM_MAX_SLOTS + upgrade_item_slot


func get_pow_count() -> int:
	return 8 + upgrade_pow * 2


func get_item_drop_bonus() -> float:
	return float(upgrade_drop) * 0.03
