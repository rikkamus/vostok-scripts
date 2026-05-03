extends RefCounted

const COMMAND_NAME := "clear"

var _console_main: Node = null


func _init(console_main: Node) -> void:
    self._console_main = console_main


func execute(command: String, args: PackedStringArray) -> void:
    if args.is_empty():
        _console_main.overlay.clear_output()
    else:
        _console_main.overlay.append_output_line("Usage: " + command)
