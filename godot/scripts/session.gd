extends Node

const SAVE_PATH := "user://save.cfg"

var best_score: int = 0

func _ready() -> void:
    load_progress()


func load_progress() -> void:
    var config := ConfigFile.new()
    var err := config.load(SAVE_PATH)
    if err == OK:
        best_score = int(config.get_value("progress", "best_score", 0))


func submit_score(score: int) -> void:
    if score > best_score:
        best_score = score
        save_progress()


func save_progress() -> void:
    var config := ConfigFile.new()
    config.set_value("progress", "best_score", best_score)
    config.save(SAVE_PATH)
