extends RefCounted

const COMMAND_NAME := "shelter"

var game_data = preload("res://Resources/GameData.tres")

var _console_main: Node = null


func _init(console_main: Node) -> void:
    self._console_main = console_main


func execute(command: String, args: PackedStringArray) -> void:
    if not args.is_empty():
        _console_main.overlay.append_output_line("Usage: " + command)
        return

    var can_teleport: bool = _console_main.common.is_in_level() and not (
        _console_main.get_tree().paused or
        game_data.shelter or
        game_data.isDead or
        game_data.isCaching or
        game_data.isTransitioning or
        game_data.isPlacing or
        game_data.isSleeping or
        game_data.interface
    )

    if not can_teleport:
        _console_main.overlay.append_output_line("Cannot teleport to shelter at the moment.")
        return

    var shelter: String = Loader.ValidateShelter()

    if shelter.is_empty():
        _console_main.overlay.append_output_line("Could not determine last visited shelter.")
        return

    game_data.currentMap = shelter
    game_data.previousMap = ""

    Loader.LoadScene(shelter)
    Loader.SaveCharacter()
    Loader.SaveWorld()


func get_description() -> String:
    return "Teleports the player to the last visited shelter."
