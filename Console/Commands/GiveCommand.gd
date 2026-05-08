extends RefCounted

const COMMAND_NAME := "give"

var game_data = preload("res://Resources/GameData.tres")

var _console_main: Node = null


func _init(console_main: Node) -> void:
    self._console_main = console_main


func execute(command: String, args: PackedStringArray) -> void:
    if args.is_empty() or args.size() > 2:
        _console_main.overlay.append_output_line("Usage: %s <item> [count]" % command)
        return

    var item_name: String = args[0]
    var item_count: int = 1

    if args.size() >= 2:
        if not args[1].is_valid_int():
            _console_main.overlay.append_output_line("Invalid item count: \"%s\"" % args[1])
            return

        item_count = int(args[1])

    if item_count < 1:
        _console_main.overlay.append_output_line("Item count must be a positive integer.")
        return

    var interface: Node = null

    if _console_main.get_tree().current_scene != null:
        interface = _console_main.get_tree().current_scene.get_node_or_null("/root/Map/Core/UI/Interface")

    var can_give: bool = _console_main.common.is_in_level() and not (
        not is_instance_valid(interface) or
        not interface.is_node_ready() or
        game_data.isDead or
        game_data.isCaching or
        game_data.isTransitioning
    )

    if not can_give:
        _console_main.overlay.append_output_line("Cannot give item at the moment.")
        return

    var item: ItemData = _find_item(item_name)

    if item == null:
        _console_main.overlay.append_output_line("Invalid item: \"%s\"." % item_name)
        return

    var slot_data := SlotData.new()
    slot_data.itemData = item

    var amount_to_give: int = max(min(item_count, item.maxAmount), 1) if item.stackable else 1
    slot_data.amount = amount_to_give

    if _add_item_to_inventory(interface, slot_data):
        _console_main.overlay.append_output_line("Gave %d \"%s\"." % [amount_to_give, item.name])
    else:
        _console_main.overlay.append_output_line("No space in inventory.")


func get_description() -> String:
    return "Gives an item to the player."


func _find_item(item_name: String) -> ItemData:
    var index: int = Database.master.items.find_custom(func (item: ItemData): return item.file == item_name)

    if index != -1:
        return Database.master.items[index]
    else:
        return null


func _add_item_to_inventory(interface: Node, slot_data: SlotData) -> bool:
    if interface.AutoStack(slot_data, interface.inventoryGrid):
        interface.UpdateStats(false)
        return true
    elif interface.Create(slot_data, interface.inventoryGrid, false):
        interface.UpdateStats(false)
        return true
    else:
        return false
