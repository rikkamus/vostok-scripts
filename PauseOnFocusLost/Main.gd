# Part of https://github.com/rikkamus/vostok-scripts
extends Node

const VERSION := "1.1.0"

var common = null


func _ready() -> void:
    if common == null:
        print("ERROR: Attempted to load PauseOnFocusLost script directly. Add the \"Common\" script as an autoload singleton instead. Visit \"https://github.com/rikkamus/vostok-scripts\" for more information.")
        set_process(false)
        queue_free()


func get_script_menu_messages() -> Array:
    return [
        {
            "message": "PauseOnFocusLost",
            "type": "info"
        }
    ]


func _process(_delta: float) -> void:
    var window: Window = get_tree().root

    if not window.has_focus() or window.mode == Window.Mode.MODE_MINIMIZED:
        try_pause()


func try_pause() -> void:
    if get_tree().paused:
        return

    var ui_manager = get_tree().current_scene.get_node_or_null("/root/Map/Core/UI")
    if not is_instance_valid(ui_manager) or not ui_manager.is_node_ready():
        return

    var game_data = ui_manager.gameData
    var interface = ui_manager.interface

    var can_pause: bool = not (
        game_data.isDead or
        game_data.isCaching or
        game_data.isTransitioning or
        game_data.isReloading or
        game_data.isInserting or
        game_data.isChecking or
        game_data.isPlacing or
        game_data.isSleeping or
        (interface.container and game_data.isOccupied) or
        interface.isCrafting or
        game_data.isInspecting
    )

    if not can_pause:
        return

    ui_manager.PlayClick()

    if game_data.interface:
        ui_manager.Return()

    ui_manager.ToggleSettings()
