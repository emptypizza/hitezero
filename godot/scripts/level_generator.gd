extends RefCounted
class_name LevelGenerator

const Block = preload("res://scripts/block.gd")
const GameConstants = preload("res://scripts/game_constants.gd")
const BLOCK_SCENE := preload("res://scenes/block.tscn")


static func init_level(game_root, level: int) -> void:
    game_root.clear_level_nodes()
    game_root.pending_stars = 0
    game_root.knives_to_spawn = 0

    var rng := RandomNumberGenerator.new()
    rng.randomize()

    var max_rows := 8
    var rows: int = min(3 + int(floor(float(level) / 2.0)), max_rows)
    for row in range(rows):
        _generate_row(game_root, 60.0 + float(row) * GameConstants.BLOCK_HEIGHT, level, true, rng)

    if not _has_star(game_root):
        _add_block(game_root, 3, 60.0, 1, 1, GameConstants.BLOCK_STAR)


static func _generate_row(game_root, y_pos: float, level: int, is_init: bool, rng: RandomNumberGenerator) -> void:
    for col in range(GameConstants.BLOCK_COLS):
        if rng.randf() > 0.4:
            var block_type := GameConstants.BLOCK_NORMAL
            var hp := level
            var rand := rng.randf()

            if rand < 0.1:
                block_type = GameConstants.BLOCK_POW
                hp = 1
            elif is_init and rand < 0.25:
                block_type = GameConstants.BLOCK_STAR
                hp = 1
            elif rand < 0.35:
                block_type = GameConstants.BLOCK_RED_ENEMY

            _add_block(game_root, col, y_pos, hp, hp, block_type)


static func _add_block(game_root, col: int, y_pos: float, hp: int, max_hp: int, block_type: String) -> void:
    var block_size := Vector2(GameConstants.BLOCK_WIDTH - 4.0, GameConstants.BLOCK_HEIGHT - 4.0)
    var x := float(col) * GameConstants.BLOCK_WIDTH + 2.0 + block_size.x * 0.5
    var y := y_pos + 2.0 + block_size.y * 0.5

    var block: Block = BLOCK_SCENE.instantiate()
    block.position = Vector2(x, y)
    block.configure(block_type, hp, max_hp, block_size)

    var group = game_root.moving_blocks_layer if block_type == GameConstants.BLOCK_RED_ENEMY else game_root.blocks_layer
    group.add_child(block)


static func _has_star(game_root) -> bool:
    for container in [game_root.blocks_layer, game_root.moving_blocks_layer]:
        for child in container.get_children():
            var block := child as Block
            if block != null and block.block_type == GameConstants.BLOCK_STAR and not block.is_destroyed():
                return true
    return false
