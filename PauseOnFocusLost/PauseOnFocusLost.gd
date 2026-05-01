# Made for Road to Vostok version 0.1.1.3
# Part of https://github.com/rikkamus/vostok-scripts
extends Node

const VERSION = "1.0.0"


func _ready() -> void:
    print("Loaded PauseOnFocusLost script v%s by rikkamus" % VERSION)


func _process(_delta: float) -> void:
    var window: Window = get_tree().root

    if not window.has_focus() or window.mode == Window.Mode.MODE_MINIMIZED:
        if not get_tree().paused:
            var ui_manager = get_tree().current_scene.get_node_or_null("/root/Map/Core/UI")

            if is_instance_valid(ui_manager):
                ui_manager.PlayClick()
                ui_manager.ToggleSettings()
