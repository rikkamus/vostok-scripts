# Part of https://github.com/rikkamus/vostok-scripts
extends Node

const HEALTH_REGEN_PER_SEC: float = 0.2
const AFFLICTION_CLEAR_INTERVAL_SEC: float = 60.0

const VERSION := "1.2.0-SNAPSHOT"
const LOG_TAG := "ShelterHealthRegen"

var game_data = preload("res://Resources/GameData.tres")

var common = null
var _affliction_clear_timer: float = 0.0


func _ready() -> void:
    if common == null:
        print("ERROR: Attempted to load ShelterHealthRegen script directly. Add the \"Common\" script as an autoload singleton instead. Visit \"https://github.com/rikkamus/vostok-scripts\" for more information.")
        set_process(false)
        queue_free()


func get_script_menu_messages() -> Array:
    return [
        {
            "message": "ShelterHealthRegen",
            "type": "info"
        }
    ]


func _process(delta: float) -> void:
    if not game_data.shelter or game_data.isDead or game_data.isSleeping:
        _affliction_clear_timer = 0.0
        return

    if _has_affliction():
        _handle_affliction(delta)
    else:
        _affliction_clear_timer = 0.0
        _handle_heal(delta)



func _handle_affliction(delta: float) -> void:
    var healable_afflictions: Array[String] = _get_healable_afflictions()

    if healable_afflictions.is_empty():
        _affliction_clear_timer = 0.0
        return

    _affliction_clear_timer += delta

    if _affliction_clear_timer >= AFFLICTION_CLEAR_INTERVAL_SEC:
        _affliction_clear_timer = 0.0
        _heal_affliction(healable_afflictions[randi_range(0, healable_afflictions.size() - 1)])


func _handle_heal(delta: float) -> void:
    game_data.health = min(game_data.health + HEALTH_REGEN_PER_SEC * delta, 100.0)


func _has_affliction() -> bool:
    return (
        game_data.overweight or
        game_data.starvation or
        game_data.dehydration or
        game_data.bleeding or
        game_data.fracture or
        game_data.burn or
        game_data.frostbite or
        game_data.insanity or
        game_data.poisoning or
        game_data.rupture or
        game_data.headshot
    )


func _get_healable_afflictions() -> Array[String]:
    var afflictions: Array[String]

    if game_data.bleeding:
        afflictions.append("bleeding")

    if game_data.fracture:
        afflictions.append("fracture")

    if game_data.burn:
        afflictions.append("burn")

    if game_data.poisoning:
        afflictions.append("poisoning")

    if game_data.rupture:
        afflictions.append("rupture")

    if game_data.headshot:
        afflictions.append("headshot")

    return afflictions


func _heal_affliction(affliction: String) -> void:
    match affliction:
        "bleeding": game_data.bleeding = false
        "fracture": game_data.fracture = false
        "burn": game_data.burn = false
        "poisoning": game_data.poisoning = false
        "rupture": game_data.rupture = false
        "headshot": game_data.headshot = false
        _: common.log_script_error_message(LOG_TAG, "Unknown affliction: \"%s\"" % affliction)
