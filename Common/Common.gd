# Part of https://github.com/rikkamus/vostok-scripts
extends Node

const VERSION := "1.2.0-SNAPSHOT"
const SUPPORTED_GAME_VERSION := "0.1.1.3"

const LOG_TAG := "Common"

const LOCAL_SCRIPT_ROOT_DIR_PATH := "rikkamus/"
const COMMON_SCRIPT_DIR_NAME := "Common"

enum ScriptLoadErrorLevel {
    OK = 0,
    WARNING = 1,
    ERROR = 2
}

var _load_error: ScriptLoadErrorLevel = ScriptLoadErrorLevel.OK


func _enter_tree() -> void:
    if ProjectSettings.get_setting("application/config/version") != SUPPORTED_GAME_VERSION:
        _load_error = ScriptLoadErrorLevel.ERROR
        log_script_error_message(LOG_TAG, "Rikkamus's Road to Vostok scripts v%s require Road to Vostok v%s." % [VERSION, SUPPORTED_GAME_VERSION])
        return

    var common_script_required_path: String = LOCAL_SCRIPT_ROOT_DIR_PATH.path_join(COMMON_SCRIPT_DIR_NAME)

    if not get_script().resource_path.begins_with("res://" + common_script_required_path):
        _load_error = ScriptLoadErrorLevel.ERROR
        log_script_error_message(LOG_TAG, "Common script must be placed in \"%s\"." % common_script_required_path)
        return

    log_script_info_message(LOG_TAG, "Loading Rikkamus's Road to Vostok scripts v%s..." % VERSION)
    _load_error = max(_load_error, _load_scripts())
    log_script_info_message(LOG_TAG, "Successfully loaded %d script(s)!" % get_child_count())


func _ready() -> void:
    _try_update_menu_message_list()
    get_tree().scene_changed.connect(_on_scene_changed)


func _on_scene_changed() -> void:
    _try_update_menu_message_list()


func _load_scripts() -> ScriptLoadErrorLevel:
    var error: ScriptLoadErrorLevel = ScriptLoadErrorLevel.OK

    var game_dir_path := OS.get_executable_path().get_base_dir()
    var script_root_dir_path := game_dir_path.path_join(LOCAL_SCRIPT_ROOT_DIR_PATH)
    var script_root_dir := DirAccess.open(script_root_dir_path)

    if script_root_dir == null:
        log_script_warning_message(LOG_TAG, "Could not open directory \"%s\"." % script_root_dir_path)
        error = max(error, ScriptLoadErrorLevel.WARNING)
        return error

    for script_dir_name in script_root_dir.get_directories():
        if script_dir_name != COMMON_SCRIPT_DIR_NAME:
            error = max(error, _load_main_script(script_dir_name.trim_suffix("/")))

    return error


func _load_main_script(script_name: String) -> ScriptLoadErrorLevel:
    var script_file_local_path: String = script_name.path_join("Main.gd")

    var main_script: Script = load_script(script_file_local_path)
    if main_script == null:
        return ScriptLoadErrorLevel.ERROR

    if not main_script.get_script_constant_map().has("VERSION"):
        log_script_error_message(LOG_TAG, "Script \"%s\" does not define a VERSION constant." % script_name)
        return ScriptLoadErrorLevel.ERROR

    var script_version = main_script.get_script_constant_map()["VERSION"]

    if script_version != VERSION:
        log_script_error_message(LOG_TAG, "Script \"%s\" has version \"%s\", but version \"%s\" was expected." % [script_name, script_version, VERSION])
        return ScriptLoadErrorLevel.ERROR

    if main_script.get_instance_base_type() != "Node":
        log_script_error_message(LOG_TAG, "Script \"%s\" does not directly extend Node." % script_name)
        return ScriptLoadErrorLevel.ERROR

    log_script_info_message(LOG_TAG, "Initializing script \"%s\"..." % script_name)

    var node: Node = Node.new()
    node.name = script_name
    node.set_script(main_script)

    var error: ScriptLoadErrorLevel = ScriptLoadErrorLevel.OK

    if main_script.get_script_property_list().any(func (property): return property["name"] == "common"):
        node.common = self
    else:
        error = max(error, ScriptLoadErrorLevel.WARNING)
        log_script_warning_message(LOG_TAG, "Common property not found in script \"%s\"." % script_name)

    add_child(node)
    return error


func load_script(local_path: String) -> Script:
    var game_dir_path := OS.get_executable_path().get_base_dir()
    var script_root_dir_path := game_dir_path.path_join(LOCAL_SCRIPT_ROOT_DIR_PATH)
    var script_absolute_path = script_root_dir_path.path_join(local_path)

    if not FileAccess.file_exists(script_absolute_path):
        log_script_error_message(LOG_TAG, "Requested script file \"%s\" does not exist." % script_absolute_path)
        return null

    var script = ResourceLoader.load(script_absolute_path, "Script")

    if script is not Script:
        log_script_error_message(LOG_TAG, "File \"%s\" is not a script." % script_absolute_path)
        return null

    return script


func _try_update_menu_message_list() -> void:
    var scene: Node = get_tree().current_scene

    if not scene.scene_file_path == "res://Scenes/Menu.tscn" or scene is not Control:
        return

    var message_box: VBoxContainer = null

    if not scene.has_node("RikkamusScriptMessageList"):
        message_box = VBoxContainer.new()
        message_box.name = "RikkamusScriptMessageList"
        message_box.custom_minimum_size = Vector2(300, 0)
        message_box.set_anchors_and_offsets_preset(Control.LayoutPreset.PRESET_TOP_RIGHT, Control.LayoutPresetMode.PRESET_MODE_KEEP_SIZE, 20)
        message_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
        message_box.grow_vertical = Control.GROW_DIRECTION_END
        scene.add_child(message_box)
    else:
        message_box = scene.get_node("RikkamusScriptMessageList")

    for label in message_box.get_children():
        label.queue_free()

    message_box.add_child(_create_message_label("Rikkamus's Vostok Scripts v%s:" % VERSION, Color.GREEN))

    if _load_error == ScriptLoadErrorLevel.ERROR:
        message_box.add_child(_create_message_label("An error occurred while loading one or more scripts. Check logs for more information.", Color.RED))
    elif _load_error == ScriptLoadErrorLevel.WARNING:
        message_box.add_child(_create_message_label("Warnings were reported while loading one or more scripts. Check logs for more information.", Color.ORANGE))

    if get_child_count() == 0:
        message_box.add_child(_create_message_label("No scripts loaded.", Color.WHITE))
    else:
        for script in get_children():
            if script.has_method("get_script_menu_messages"):
                var script_messages = script.get_script_menu_messages()

                if script_messages is not Array:
                    log_script_error_message(LOG_TAG, "Script \"%s\" returned invalid menu message list." % script.name)
                    continue

                for message in script_messages:
                    if message is not Dictionary or not message.has("message"):
                        log_script_error_message(LOG_TAG, "Script \"%s\" returned invalid menu message." % script.name)
                        continue

                    var message_text: String = message["message"]
                    var message_color: Color = Color.RED if message.has("type") and message["type"] == "error" else Color.GREEN

                    message_box.add_child(_create_message_label(message_text, message_color))


func _create_message_label(text: String, color: Color) -> Label:
    var label := Label.new()
    label.grow_horizontal = Control.GROW_DIRECTION_END
    label.grow_vertical = Control.GROW_DIRECTION_END
    label.size_flags_horizontal = Control.SIZE_FILL
    label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    label.text = text
    label.add_theme_color_override("font_color", color)

    return label


func log_script_info_message(script: String, message: String) -> void:
    print("[INFO][rikkamus.%s] %s" % [script, message])


func log_script_warning_message(script: String, message: String) -> void:
    print("[WARN][rikkamus.%s] %s" % [script, message])


func log_script_error_message(script: String, message: String) -> void:
    print("[ERROR][rikkamus.%s] %s" % [script, message])
