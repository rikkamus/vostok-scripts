extends RefCounted

const COMMAND_NAME := "search"

var _console_main: Node = null


func _init(console_main: Node) -> void:
    self._console_main = console_main


func execute(command: String, args: PackedStringArray) -> void:
    if args.is_empty() or args.size() > 2:
        _console_main.overlay.append_output_line("Usage: %s <item> [limit]" % command)
        return

    var query: String = args[0]
    var limit: int = 5

    if args.size() >= 2:
        if not args[1].is_valid_int():
            _console_main.overlay.append_output_line("Invalid limit: \"%s\"" % args[1])
            return

        limit = int(args[1])

    if limit < 1:
        _console_main.overlay.append_output_line("Limit must be a positive integer.")
        return

    var result: Array[String] = _search_items(query, limit)

    _console_main.overlay.append_output_line("Closest %d matches:" % result.size())

    for item_id in result:
        _console_main.overlay.append_output_line(item_id)


func get_description() -> String:
    return "Looks up item IDs based on a partial item name."


func _search_items(query: String, limit: int) -> Array[String]:
    var items := Database.master.items

    var id_edit_distances: Array = items.map(func(item): return _edit_distance(query.to_lower(), item.file.to_lower()))
    var name_edit_distances: Array = items.map(func(item): return _edit_distance(query.to_lower(), item.name.to_lower()))

    var max_id_edit_distance: int = id_edit_distances.max()
    var max_name_edit_distance: int = name_edit_distances.max()

    var normalized_id_edit_distances: Array = id_edit_distances.map(func (distance): return float(distance) / max_id_edit_distance)
    var normalized_name_edit_distances: Array = name_edit_distances.map(func (distance): return float(distance) / max_name_edit_distance)

    var item_scores: Dictionary[String, float]

    for i in range(items.size()):
        var score: float = (1.0 - normalized_id_edit_distances[i]) * 0.25 + (1.0 - normalized_name_edit_distances[i]) * 0.25

        if items[i].file.containsn(query):
            score += 0.25

        if items[i].name.containsn(query):
            score += 0.25

        item_scores[items[i].file] = score

    var sorted_item_ids: Array = items.map(func (item): return item.file)
    sorted_item_ids.sort_custom(func (a, b): return item_scores[a] > item_scores[b])

    # Apply limit and convert Array to Array[String]
    var string_item_ids: Array[String]

    for i in range(min(sorted_item_ids.size(), limit)):
        string_item_ids.append(sorted_item_ids[i])

    return string_item_ids


func _edit_distance(a: String, b: String) -> int:
    var prev: PackedInt32Array
    var current: PackedInt32Array

    prev.resize(b.length() + 1)
    current.resize(b.length() + 1)

    for i in range(b.length() + 1):
        prev[i] = i

    for i in range(a.length()):
        current[0] = i + 1

        for j in range(b.length()):
            var deletion_cost: int = prev[j + 1] + 1
            var insertion_cost: int = current[j] + 1
            var substitution_cost: int = prev[j] if a[i] == b[j] else (prev[j] + 1)

            current[j + 1] = min(deletion_cost, insertion_cost, substitution_cost)

        for j in range(b.length() + 1):
            prev[j] = current[j]

    return current[b.length()]
