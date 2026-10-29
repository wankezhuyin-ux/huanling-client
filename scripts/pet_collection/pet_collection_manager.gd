


class_name PetCollectionManager
extends Node

const PetCollectionData = preload("res://scripts/pet_collection/pet_collection_data.gd")
const GameData = preload("res://scripts/game_data.gd")


signal collection_updated(pet_id: String, new_count: int)
signal bonus_changed(bonus_type: String, new_value: float)
signal total_bonuses_updated(bonuses: Dictionary)




var _collection_progress: Dictionary = {}


var _mutation_progress: Dictionary = {}


var _total_bonuses: Dictionary = {
	"attack": 0.0, 
	"defense": 0.0, 
	"agility": 0.0, 
	"hp": 0.0
}


var _pet_data: Dictionary = {}


var _event_pet_order: Dictionary = {}
var _soul_reward_pet_order: Dictionary = {}
var _world_boss_pet_order: Dictionary = {}

func _is_soul_reward_pet_id(pet_id: String) -> bool:
	var pet_info: Dictionary = _pet_data.get(pet_id, {})
	if pet_info.is_empty():
		return false
	if bool(pet_info.get("is_soul_reward_pet", false)):
		return true
	return not str(pet_info.get("soul_reward_pool", "")).strip_edges().is_empty()

func _is_world_boss_pet_id(pet_id: String) -> bool:
	var pet_info: Dictionary = _pet_data.get(pet_id, {})
	if pet_info.is_empty():
		return false
	if bool(pet_info.get("is_world_boss_pet", false)):
		return true
	return not str(pet_info.get("world_boss_pool", "")).strip_edges().is_empty()

func _is_event_only_display_pet(pet_id: String) -> bool:
	return _is_collection_display_only_pet(pet_id) and not _is_soul_reward_pet_id(pet_id) and not _is_world_boss_pet_id(pet_id)

func _is_collection_display_only_pet(pet_id: String) -> bool:
	var pet_info: Dictionary = _pet_data.get(pet_id, {})
	if pet_info.is_empty():
		return false
	return bool(pet_info.get("collection_disabled", false) or pet_info.get("collection_display_only", false))


func _ready():
	_pet_data = GameData.PET_DATA
	print("[PetCollectionManager] Initialized with %d pets" % _pet_data.size())




func get_collection_info(pet_id: String) -> Dictionary:
	var count = int(_collection_progress.get(pet_id, 0))
	var mut_count = PetCollectionData.clamp_mutation_count(int(_mutation_progress.get(pet_id, 0)))
	var bonus_type = PetCollectionData.get_bonus_type(pet_id)
	var normal_bonus = PetCollectionData.get_bonus_value(count)
	var mutation_bonus = PetCollectionData.get_mutation_bonus_value(mut_count)
	var current_bonus = normal_bonus + mutation_bonus
	var next_bonus = current_bonus
	var bonus_increase = 0.0
	if count < 50:
		next_bonus = PetCollectionData.get_next_bonus_value(count) + mutation_bonus
		bonus_increase = PetCollectionData.get_bonus_increase(count)
	elif mut_count < PetCollectionData.MUTATION_MAX:
		bonus_increase = PetCollectionData.MUTATION_BONUS_PER
		next_bonus = current_bonus + bonus_increase

	return {
		"pet_id": pet_id, 
		"count": count, 
		"max_count": 50, 
		"mutation_count": mut_count, 
		"mutation_max": PetCollectionData.MUTATION_MAX, 
		"is_normal_max": count >= 50, 
		"is_mutation_max": mut_count >= PetCollectionData.MUTATION_MAX, 
		"is_max": count >= 50 and mut_count >= PetCollectionData.MUTATION_MAX, 
		"has_mutation": mut_count > 0, 
		"bonus_type": bonus_type, 
		"bonus_type_name": PetCollectionData.get_bonus_type_name(bonus_type), 
		"current_bonus": current_bonus, 
		"normal_bonus": normal_bonus, 
		"mutation_bonus": mutation_bonus, 
		"next_bonus": next_bonus, 
		"bonus_increase": bonus_increase
	}


func get_count(pet_id: String) -> int:
	return int(_collection_progress.get(pet_id, 0))

func get_mutation_count(pet_id: String) -> int:
	return PetCollectionData.clamp_mutation_count(int(_mutation_progress.get(pet_id, 0)))


func can_activate(pet_id: String) -> bool:
	if _is_collection_display_only_pet(pet_id):
		return false
	var count = int(_collection_progress.get(pet_id, 0))
	return count < 50

func can_invest_mutation(pet_id: String) -> bool:
	if _is_collection_display_only_pet(pet_id):
		return false
	if int(_collection_progress.get(pet_id, 0)) < 50:
		return false
	return get_mutation_count(pet_id) < PetCollectionData.MUTATION_MAX


func can_manual_invest(pet_id: String, pet_mutation_count: int = 0) -> bool:
	if _is_collection_display_only_pet(pet_id):
		return false
	if can_activate(pet_id):
		return true
	return can_invest_mutation(pet_id) and int(pet_mutation_count) >= 1


func activate_collection(pet_id: String, pet_instance) -> Dictionary:
	var result = {
		"success": false, 
		"message": "", 
		"old_count": 0, 
		"new_count": 0, 
		"bonus_type": "", 
		"bonus_increase": 0.0
	}


	if _is_collection_display_only_pet(pet_id):
		result.message = "该宠物为活动限定，仅展示在图鉴中，无法投入激活"
		return result
	var current_count = int(_collection_progress.get(pet_id, 0))
	if current_count >= 50:
		result.message = "该宠物图鉴已满级"
		return result


	if pet_instance == null:
		result.message = "无效的宠物"
		return result

	if pet_instance.pet_id != pet_id:
		result.message = "宠物ID不匹配"
		return result


	var new_count = current_count + 1
	_collection_progress[pet_id] = new_count


	var bonus_type = PetCollectionData.get_bonus_type(pet_id)
	var bonus_increase = PetCollectionData.get_bonus_increase(current_count)


	_total_bonuses[bonus_type] += bonus_increase


	collection_updated.emit(pet_id, new_count)
	bonus_changed.emit(bonus_type, _total_bonuses[bonus_type])
	total_bonuses_updated.emit(_total_bonuses.duplicate())

	result.success = true
	result.old_count = current_count
	result.new_count = new_count
	result.bonus_type = bonus_type
	result.bonus_increase = bonus_increase
	result.message = "图鉴升级成功！%s %s" % [
		PetCollectionData.get_bonus_type_name(bonus_type), 
		PetCollectionData.format_bonus_percent_signed(bonus_increase)
	]

	if current_count == 0 and GameManager.instance and GameManager.instance.quest_manager:
		GameManager.instance.quest_manager.on_pet_collection_activated()

	return result


func apply_species_progress_from_save(pet_id: String, normal_count: int, mutation_count: int = -1) -> void :
	var sid: = str(pet_id)
	if sid.is_empty():
		return
	var n: = clampi(int(normal_count), 0, 50)
	if n > 0:
		_collection_progress[sid] = n
	elif _collection_progress.has(sid):
		_collection_progress.erase(sid)
	if mutation_count >= 0:
		var m: = PetCollectionData.clamp_mutation_count(int(mutation_count))
		if m > 0:
			_mutation_progress[sid] = m
		elif _mutation_progress.has(sid):
			_mutation_progress.erase(sid)
	_recalculate_all_bonuses()
	collection_updated.emit(sid, n)
	total_bonuses_updated.emit(_total_bonuses.duplicate())


func get_total_bonuses() -> Dictionary:
	return _total_bonuses.duplicate()


func get_bonus_by_type(bonus_type: String) -> float:
	return _total_bonuses.get(bonus_type, 0.0)


func get_all_collection_progress() -> Dictionary:
	return _collection_progress.duplicate()


func get_activated_count() -> int:
	return _collection_progress.size()


func get_maxed_count() -> int:
	var count = 0
	for pet_id in _collection_progress:
		if _collection_progress[pet_id] >= 50:
			count += 1
	return count


func debug_max_all_collections() -> Dictionary:
	var max_count = 50
	var success_count = 0

	for pet_id in _pet_data.keys():
		if _is_collection_display_only_pet(pet_id):
			if _collection_progress.has(pet_id):
				_collection_progress.erase(pet_id)
			continue
		var current_count = get_count(pet_id)
		if current_count < max_count:
			_collection_progress[pet_id] = max_count
			success_count += 1

	_recalculate_all_bonuses()

	return {
		"success_count": success_count, 
		"total_bonuses": _total_bonuses.duplicate()
	}




func to_dict() -> Dictionary:
	return {
		"progress": _collection_progress.duplicate(), 
		"mutation_progress": _mutation_progress.duplicate(), 
		"bonuses": _total_bonuses.duplicate()
	}


func from_dict(data: Dictionary):
	if data == null or not data is Dictionary:
		return

	if data.has("progress"):
		_collection_progress.clear()
		var progress = data.get("progress", {})
		if progress is Dictionary:
			for pet_id in progress:
				var count = int(progress[pet_id])
				if count > 0:
					_collection_progress[pet_id] = clampi(count, 0, 50)

	_mutation_progress.clear()
	if data.has("mutation_progress"):
		var mut_prog = data.get("mutation_progress", {})
		if mut_prog is Dictionary:
			for pet_id in mut_prog:
				var m = PetCollectionData.clamp_mutation_count(int(mut_prog[pet_id]))
				if m > 0:
					_mutation_progress[pet_id] = m

	if data.has("progress") or data.has("mutation_progress"):
		_recalculate_all_bonuses()
		total_bonuses_updated.emit(_total_bonuses.duplicate())


func _recalculate_all_bonuses():
	_total_bonuses = {
		"attack": 0.0, 
		"defense": 0.0, 
		"agility": 0.0, 
		"hp": 0.0
	}

	var all_ids: = {}
	for pet_id in _collection_progress:
		all_ids[pet_id] = true
	for pet_id in _mutation_progress:
		all_ids[pet_id] = true
	for pet_id in all_ids:
		if _is_collection_display_only_pet(pet_id):
			continue
		var count = int(_collection_progress.get(pet_id, 0))
		var mut_count = get_mutation_count(pet_id)
		var bonus_type = PetCollectionData.get_bonus_type(pet_id)
		var bonus_value = PetCollectionData.get_species_total_bonus(count, mut_count)
		_total_bonuses[bonus_type] += bonus_value




func get_pet_base_data(pet_id: String) -> Dictionary:
	if _pet_data.is_empty():
		_pet_data = GameData.PET_DATA
	return _pet_data.get(pet_id, {})


func has_pet_data(pet_id: String) -> bool:
	return _pet_data.has(pet_id)

func _ensure_event_pet_order() -> void :
	if not _event_pet_order.is_empty():
		return
	var idx: = 0
	for pet_id in GameData.EVENT_PET_LIBRARY.keys():
		_event_pet_order[pet_id] = idx
		idx += 1

func _get_event_pet_order_index(pet_id: String) -> int:
	_ensure_event_pet_order()
	return int(_event_pet_order.get(pet_id, -1))

func _ensure_soul_reward_pet_order() -> void :
	if not _soul_reward_pet_order.is_empty():
		return
	var idx: = 0
	for pet_id in GameData.SOUL_REWARD_PET_LIBRARY.keys():
		_soul_reward_pet_order[pet_id] = idx
		idx += 1

func _get_soul_reward_pet_order_index(pet_id: String) -> int:
	_ensure_soul_reward_pet_order()
	return int(_soul_reward_pet_order.get(pet_id, -1))

func _ensure_world_boss_pet_order() -> void :
	if not _world_boss_pet_order.is_empty():
		return
	var idx: = 0
	for pet_id in GameData.WORLD_BOSS_PET_LIBRARY.keys():
		_world_boss_pet_order[pet_id] = idx
		idx += 1

func _get_world_boss_pet_order_index(pet_id: String) -> int:
	_ensure_world_boss_pet_order()
	return int(_world_boss_pet_order.get(pet_id, -1))

func _collection_sort_tier(pet_id: String) -> int:
	if _is_event_only_display_pet(pet_id):
		return 0
	if _is_soul_reward_pet_id(pet_id):
		return 1
	if _is_world_boss_pet_id(pet_id):
		return 2
	return 3

func _compare_pet_ids_for_collection(a: String, b: String, original_order: Dictionary) -> bool:
	var a_tier: = _collection_sort_tier(a)
	var b_tier: = _collection_sort_tier(b)
	if a_tier != b_tier:
		return a_tier < b_tier

	if a_tier == 0:
		var a_idx: = _get_event_pet_order_index(a)
		var b_idx: = _get_event_pet_order_index(b)
		if a_idx >= 0 and b_idx >= 0:
			return a_idx < b_idx
		if a_idx >= 0:
			return true
		if b_idx >= 0:
			return false

	if a_tier == 1:
		var a_soul: = _get_soul_reward_pet_order_index(a)
		var b_soul: = _get_soul_reward_pet_order_index(b)
		if a_soul >= 0 and b_soul >= 0:
			return a_soul < b_soul
		if a_soul >= 0:
			return true
		if b_soul >= 0:
			return false

	if a_tier == 2:
		var a_wb: = _get_world_boss_pet_order_index(a)
		var b_wb: = _get_world_boss_pet_order_index(b)
		if a_wb >= 0 and b_wb >= 0:
			return a_wb < b_wb
		if a_wb >= 0:
			return true
		if b_wb >= 0:
			return false

	return int(original_order.get(a, 0)) < int(original_order.get(b, 0))


func get_all_pet_ids() -> Array:
	if _pet_data.is_empty():
		print("[PetCollectionManager] _pet_data is empty, reloading from GameData")
		_pet_data = GameData.PET_DATA
		print("[PetCollectionManager] Loaded %d pets" % _pet_data.size())
	var keys = _pet_data.keys()
	var original_order: Dictionary = {}
	for i in range(keys.size()):
		original_order[keys[i]] = i
	keys.sort_custom( func(a, b): return _compare_pet_ids_for_collection(a, b, original_order))
	print("[PetCollectionManager] get_all_pet_ids returning %d pets" % keys.size())
	return keys



func get_pet_ids_by_element(element: String, include_display_only: bool = false) -> Array:
	var result = []
	for pet_id in _pet_data:
		var pet_info = _pet_data[pet_id]
		if pet_info.get("element", "") != element:
			continue
		if not include_display_only and _is_collection_display_only_pet(pet_id):
			continue
		result.append(pet_id)
	return result


func get_pet_image_path(pet_id: String) -> String:
	return "res://assets/pets/%s.png" % pet_id


func add_to_collection(pet_instance) -> Dictionary:
	var result = {
		"success": false, 
		"message": "", 
		"bonus_type": "", 
		"bonus_value": 0.0
	}

	if pet_instance == null:
		result.message = "无效的宠物"
		return result


	var gm = GameManager.instance
	if gm == null or gm.pet_manager == null:
		result.message = "宠物系统未初始化"
		return result
	var pet_manager = gm.pet_manager
	if not pet_manager.pets.has(pet_instance):
		result.message = "宠物已不存在或已被处理，请刷新列表后重试"
		return result
	if pet_manager.active_pet != null and pet_manager.active_pet.id == pet_instance.id:
		result.message = "出战宠物不能加入图鉴"
		return result
	if pet_instance.locked:
		result.message = "锁定宠物不能加入图鉴"
		return result

	var pet_id = pet_instance.pet_id
	if pet_id.is_empty():
		result.message = "宠物ID为空"
		return result
	if _is_collection_display_only_pet(pet_id):
		result.message = "活动限定宠物无法加入图鉴"
		return result
	if not can_activate(pet_id):
		result.message = "该宠物图鉴已满级"
		return result


	var activate_result = activate_collection(pet_id, pet_instance)

	if activate_result.success:

		var removal_result = pet_manager.remove_pet_by_id(str(pet_instance.id))
		if not removal_result.success:

			print("[PetCollection] Warning: failed to remove pet after collection activation: ", removal_result.message)

		result.success = true
		result.bonus_type = activate_result.bonus_type
		result.bonus_value = activate_result.bonus_increase
		result.message = activate_result.message
	else:
		result.message = activate_result.message

	return result

func get_element_collection_count(element: String, include_display_only: bool = false) -> int:
	var count = 0
	var pet_ids = get_pet_ids_by_element(element, include_display_only)
	for pet_id in pet_ids:
		if _collection_progress.get(pet_id, 0) > 0:
			count += 1
	return count

func get_all_element_collection_counts(include_display_only: bool = false) -> Dictionary:
	var counts = {}
	for element in ["金", "木", "水", "火", "土"]:
		counts[element] = get_element_collection_count(element, include_display_only)
	return counts
