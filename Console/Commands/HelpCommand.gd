extends RefCounted

const COMMAND_NAME := "help"

var _console_main: Node = null


func _init(console_main: Node) -> void:
    self._console_main = console_main


func execute(command: String, args: PackedStringArray) -> void:
    if not args.is_empty():
        _console_main.overlay.append_output_line("Usage: " + command)
        return

    var registered_commands: Array = _console_main.get_registered_commands()
    registered_commands.sort()

    var command_info: Array

    for command_name: String in registered_commands:
        var command_object: RefCounted = _console_main.get_command(command_name)

        var command_description: String = ""

        if command_object.has_method("get_description"):
            command_description = command_object.get_description()

        command_info.append([command_name, command_description])

    var name_column_length: int = command_info.map(func (info: Array): return info[0].length()).max() + 5

    for info: Array in command_info:
        var command_name: String = info[0]
        var command_description: String = info[1]

        _console_main.overlay.append_output_line(command_name.rpad(name_column_length) + command_description)


func get_description() -> String:
    return "Prints information about available commands."
