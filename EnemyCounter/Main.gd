# Part of https://github.com/rikkamus/vostok-scripts
extends Node

const VERSION := "1.2.0-SNAPSHOT"

var common = null


func _ready() -> void:
    if common == null:
        print("ERROR: Attempted to load EnemyCounter script directly. Add the \"Common\" script as an autoload singleton instead. Visit \"https://github.com/rikkamus/vostok-scripts\" for more information.")
        set_process(false)
        queue_free()


func get_script_menu_messages() -> Array:
    return [
        {
            "message": "EnemyCounter",
            "type": "info"
        }
    ]


func _process(_delta: float) -> void:
    if get_tree().current_scene == null:
        return

    var hud_info = get_tree().current_scene.get_node_or_null("/root/Map/Core/UI/HUD/Info")

    if hud_info == null:
        return

    var enemy_counter_value_label: Label = hud_info.get_node_or_null("EnemyCounter/Value")

    if enemy_counter_value_label == null:
        var enemy_counter_hbox: HBoxContainer = HBoxContainer.new()
        enemy_counter_hbox.name = "EnemyCounter"

        var enemy_counter_title_label: Label = Label.new()
        enemy_counter_title_label.name = "Title"
        enemy_counter_title_label.text = "Enemies Alive: "

        enemy_counter_value_label = Label.new()
        enemy_counter_value_label.name = "Value"
        enemy_counter_value_label.label_settings = LabelSettings.new()
        _update_enemy_counter_value_label_text(enemy_counter_value_label, null, false, false)

        hud_info.add_child(enemy_counter_hbox)
        enemy_counter_hbox.add_child(enemy_counter_title_label)
        enemy_counter_hbox.add_child(enemy_counter_value_label)

    var ai_spawner = get_tree().current_scene.get_node_or_null("/root/Map/AI")

    if ai_spawner != null:
        _update_enemy_counter_value_label_text(enemy_counter_value_label, ai_spawner.activeAgents, ai_spawner.APool.get_child_count() > 0, ai_spawner.BPool.get_child_count() > 0)
    else:
        _update_enemy_counter_value_label_text(enemy_counter_value_label, null, false, false)


func _update_enemy_counter_value_label_text(enemy_counter_value_label: Label, count: Variant, enemy_can_spawn: bool, boss_can_spawn: bool) -> void:
    if count == null:
        enemy_counter_value_label.text = "N/A"
        enemy_counter_value_label.label_settings.font_color = Color.DIM_GRAY
    else:
        enemy_counter_value_label.text = str(count)

        if count > 0:
            enemy_counter_value_label.label_settings.font_color = Color.RED
        elif enemy_can_spawn:
            enemy_counter_value_label.label_settings.font_color = Color.ORANGE
        elif boss_can_spawn:
            enemy_counter_value_label.label_settings.font_color = Color.YELLOW
        else:
            enemy_counter_value_label.label_settings.font_color = Color.GREEN
