# Part of https://github.com/rikkamus/vostok-scripts
extends Node

const TOGGLE_KEY: Key = Key.KEY_QUOTELEFT

const VERSION := "1.2.0-SNAPSHOT"
const LOG_TAG := "Console"

var common = null
var overlay: CanvasLayer = null

var _commands: Dictionary[String, RefCounted]
var _command_load_full_success: bool = true


func _ready() -> void:
    if common == null:
        print("ERROR: Attempted to load Console script directly. Add the \"Common\" script as an autoload singleton instead. Visit \"https://github.com/rikkamus/vostok-scripts\" for more information.")
        set_process_input(false)
        queue_free()

    _command_load_full_success = common.load_scripts_in_dir("Console/Commands").all(register_command_with_constant_name)

    var overlay_scene: PackedScene = common.load_scene("Console/ConsoleOverlay.tscn")

    if overlay_scene != null:
        overlay = overlay_scene.instantiate()
        overlay.command_submitted.connect(_on_console_command_submitted)
        add_child(overlay)
    else:
        common.log_script_error_message(LOG_TAG, "Failed to load console overlay scene.")
        set_process_input(false)


func _input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event = event as InputEventKey

        if key_event.is_pressed() and not key_event.echo and key_event.physical_keycode == TOGGLE_KEY:
            overlay.toggle_console()
            get_tree().root.set_input_as_handled()


func get_script_menu_messages() -> Array:
    var messages: Array = []

    messages.append({
        "message": "Console",
        "type": "info" if overlay != null and _command_load_full_success else "error"
    })

    if overlay == null:
        messages.append({
            "message": "Failed to load console overlay.",
            "type": "error"
        })

    if not _command_load_full_success:
        messages.append({
            "message": "An error occurred while loading console commands.",
            "type": "error"
        })

    return messages


func register_command_with_constant_name(command_script: Script) -> bool:
    if command_script.get_script_constant_map().has("COMMAND_NAME"):
        var normalized_name: String = _normalize_command_name(command_script.get_script_constant_map()["COMMAND_NAME"])
        return register_command(normalized_name, command_script)
    else:
        common.log_script_error_message(LOG_TAG, "Command script \"%s\" does not define a COMMAND_NAME constant." % command_script.resource_path)
        return false


func register_command(command_name: String, command_script: Script) -> bool:
    var normalized_name = _normalize_command_name(command_name)

    if command_script.get_instance_base_type() != "RefCounted":
        common.log_script_error_message(LOG_TAG, "Script for command \"%s\" does not directly extend RefCounted." % command_name)
        return false

    if not command_script.get_script_method_list().any(func (method): return method["name"] == "_init" and method["args"].size() == 1 and method["args"][0]["type"] == TYPE_OBJECT):
        common.log_script_error_message(LOG_TAG, "Script for command \"%s\" does not define correct constructor." % command_name)
        return false

    if not command_script.get_script_method_list().any(func (method): return method["name"] == "execute" and method["args"].size() == 2 and method["args"][0]["type"] == TYPE_STRING and method["args"][1]["type"] == TYPE_PACKED_STRING_ARRAY):
        common.log_script_error_message(LOG_TAG, "Script for command \"%s\" does not correctly define execute method." % command_name)
        return false

    if _commands.has(normalized_name):
        common.log_script_error_message(LOG_TAG, "Duplicate command name: \"%s\"." % command_name)
        return false

    _commands[normalized_name] = command_script.new(self)
    return true


func get_command(command_name: String) -> RefCounted:
    var normalized_name = _normalize_command_name(command_name)
    return _commands.get(normalized_name)


func get_registered_commands() -> Array:
    return _commands.keys()


func _on_console_command_submitted(command_text: String) -> void:
    var optional_args: Variant = _parse_args(command_text)

    overlay.append_output_line("> " + command_text.strip_edges())

    if optional_args == null:
        overlay.append_output_line("ERROR: Invalid input.")
        return

    var args: PackedStringArray = optional_args as PackedStringArray

    if args.is_empty():
        return

    var normalized_name = _normalize_command_name(args[0])

    if _commands.has(normalized_name):
        _commands[normalized_name].execute(normalized_name, args.slice(1))
    else:
        overlay.append_output_line("ERROR: Unknown command: " + args[0].strip_edges())


func _normalize_command_name(command_name: String) -> String:
    return command_name.to_lower().strip_edges()


func _parse_args(command_text: String) -> Variant:
    var args: PackedStringArray

    var current_arg: String = ""

    var in_arg: bool = false
    var in_quotes: bool = false
    var escape: bool = false

    for c in command_text:
        if escape:
            current_arg += c
            escape = false
            continue

        if c == "\\":
            in_arg = true
            escape = true
            continue

        if c == "\"":
            in_arg = true
            in_quotes = not in_quotes
            continue

        if in_quotes:
            current_arg += c
            continue

        if c.strip_edges().is_empty():
            if in_arg:
                args.append(current_arg)
                current_arg = ""
                in_arg = false

            continue

        in_arg = true
        current_arg += c

    if in_quotes or escape:
        return null

    if in_arg:
        args.append(current_arg)

    return args
