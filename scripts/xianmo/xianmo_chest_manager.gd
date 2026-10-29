extends Node
class_name XianMoChestManager

var game_manager = null

var chests: Dictionary = {
	"bronze": 0, 
	"silver": 0, 
	"gold": 0
}

signal chest_added(chest_type: String, count: int)
signal chest_opened(chest_type: String, equipment: Dictionary)

func _normalize_chest_counts(raw: Dictionary) -> Dictionary:
	var normalized: = {
		"bronze": 0, 
		"silver": 0, 
		"gold": 0
	}
	for chest_type in normalized.keys():
		normalized[chest_type] = max(0, int(raw.get(chest_type, 0)))
	return normalized

func set_game_manager(gm):
	game_manager = gm

func add_chest(chest_type: String, count: int = 1):
	if chests.has(chest_type):
		chests[chest_type] += count
		chest_added.emit(chest_type, count)

func reset_chests():
	chests = {
		"bronze": 0, 
		"silver": 0, 
		"gold": 0
	}

func merge_chests_max(server_counts: Dictionary):
	var normalized = _normalize_chest_counts(server_counts)
	for chest_type in chests.keys():
		var local_count = int(chests.get(chest_type, 0))
		var merged_count = max(local_count, int(normalized.get(chest_type, 0)))
		chests[chest_type] = merged_count


func sync_chests_from_server(server_counts: Dictionary) -> void :
	var normalized = _normalize_chest_counts(server_counts)
	for chest_type in chests.keys():
		chests[chest_type] = int(normalized.get(chest_type, 0))

func get_chest_count(chest_type: String) -> int:
	return chests.get(chest_type, 0)

func get_all_chests() -> Dictionary:
	return chests.duplicate()

func open_chest(chest_type: String) -> Dictionary:
	var result = {
		"success": false, 
		"message": "", 
		"equipment": null
	}

	if not chests.has(chest_type):
		result.message = "无效的宝箱类型"
		return result

	if chests[chest_type] <= 0:
		result.message = "没有该类型的宝箱"
		return result

	chests[chest_type] -= 1
	result.success = true
	result.message = "宝箱已开启"
	chest_opened.emit(chest_type, {})
	return result

func to_dict() -> Dictionary:
	return {
		"chests": chests.duplicate()
	}

func from_dict(data: Dictionary):
	chests = _normalize_chest_counts(data.get("chests", {"bronze": 0, "silver": 0, "gold": 0}))
