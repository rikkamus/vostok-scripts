extends RefCounted

const COMMAND_NAME := "feed"

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
        _console_main.overlay.append_output_line("Cannot feed at the moment.")
        return

    game_data.energy = 100.0
    game_data.hydration = 100.0

    game_data.starvation = false
    game_data.dehydration = false
