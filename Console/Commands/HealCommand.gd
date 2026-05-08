extends RefCounted

const COMMAND_NAME := "heal"

var game_data = preload("res://Resources/GameData.tres")

var _console_main: Node = null


func _init(console_main: Node) -> void:
    self._console_main = console_main


func execute(command: String, args: PackedStringArray) -> void:
    if not args.is_empty():
        _console_main.overlay.append_output_line("Usage: " + command)
        return

    var can_heal: bool = _console_main.common.is_in_level() and not (
        game_data.isDead or
        game_data.isCaching or
        game_data.isTransitioning
    )

    if not can_heal:
        _console_main.overlay.append_output_line("Cannot heal at the moment.")
        return

    game_data.health = 100.0
    game_data.mental = 100.0
    game_data.temperature = 100.0
    game_data.oxygen = 100.0

    game_data.bleeding = false
    game_data.fracture = false
    game_data.burn = false
    game_data.frostbite = false
    game_data.insanity = false
    game_data.poisoning = false
    game_data.rupture = false
    game_data.headshot = false


func get_description() -> String:
    return "Restores health, mental, temperature and oxygen to maximum values and removes afflictions."
