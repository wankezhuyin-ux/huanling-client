extends Node
class_name SuitManager




const SuitDatabase = preload("res://scripts/data/suit_database_detailed.gd")
const SuitEquipmentEnhance = preload("res://scripts/suit/suit_equipment_enhance.gd")


signal suit_equipped(suit_level: int, slot: String)
signal suit_unequipped(suit_level: int, slot: String)
signal suit_upgraded(from_level: int, to_level: int, slot: String)
signal set_bonus_changed(bonus: Dictionary)



var equipped_suits: Dictionary = {}


var dungeon_progress: Dictionary = {}


func _ready():
	pass

func _canonical_suit_body_slot(raw: String) -> String:
	var s: = str(raw).strip_edges().to_lower()
	match s:
		"weapon", "armor", "helmet", "boots", "accessory":
			return s
	return ""




func equip_suit(equipment: EquipmentManager.Equipment, player_cultivation: int, skip_cultivation_check: bool = false) -> bool:
	print("[SUIT_EQUIP] called: ", equipment.name if equipment else "null", ", is_suit: ", equipment.is_suit if equipment else "N/A", ", skip_check: ", skip_cultivation_check)

	if not equipment.is_suit:
		push_error("非套装装备不能使用 equip_suit")
		return false

	var suit_level: int = EquipmentManager.coerce_suit_id(equipment.suit_id)
	if suit_level <= 0:
		push_warning("[SUIT_EQUIP] 无效的 suit_id: ", equipment.suit_id, " — ", equipment.name)
		return false
	equipment.suit_id = suit_level

	var slot: = _canonical_suit_body_slot(str(equipment.suit_slot))
	if slot.is_empty():
		var fb: = _canonical_suit_body_slot(str(equipment.slot))
		if not fb.is_empty():
			slot = fb
	if slot.is_empty():
		push_warning("[SUIT_EQUIP] 套装缺少部位(suit_slot/slot): ", equipment.name)
		return false
	equipment.suit_slot = slot
	print("[SUIT_EQUIP] suit_level: ", suit_level, ", slot: ", slot)


	if not skip_cultivation_check:
		var required = SuitDatabase.get_required_cultivation(suit_level)
		if player_cultivation < required:
			push_warning("修行值不足，需要 %d，当前 %d" % [required, player_cultivation])
			return false


	unequip_slot(slot)


	if not equipped_suits.has(suit_level):
		equipped_suits[suit_level] = {}
	equipped_suits[suit_level][slot] = equipment

	print("[SUIT_EQUIP] equipped_suits after: ", equipped_suits)

	suit_equipped.emit(suit_level, slot)
	set_bonus_changed.emit(calculate_total_set_bonus())

	return true


func unequip_slot(slot: String) -> EquipmentManager.Equipment:
	var canon: = _canonical_suit_body_slot(slot)
	if canon.is_empty():
		canon = str(slot).strip_edges().to_lower()
	print("[SUIT_UNEQUIP] unequip_slot called: ", slot, " (canon: ", canon, ")")
	print("[SUIT_UNEQUIP] equipped_suits before: ", equipped_suits)


	for suit_level in equipped_suits.keys():
		var slots = equipped_suits[suit_level]
		print("[SUIT_UNEQUIP] Checking suit_level: ", suit_level, ", slots: ", slots)
		if slots.has(canon):
			var equipment = slots[canon]
			slots.erase(canon)


			if slots.is_empty():
				equipped_suits.erase(suit_level)

			print("[SUIT_UNEQUIP] equipped_suits after: ", equipped_suits)
			suit_unequipped.emit(suit_level, canon)
			set_bonus_changed.emit(calculate_total_set_bonus())
			return equipment

	print("[SUIT_UNEQUIP] Slot not found: ", canon)
	return null


func get_equipped_suit_by_slot(slot: String) -> Dictionary:
	var canon: = _canonical_suit_body_slot(slot)
	if canon.is_empty():
		canon = str(slot).strip_edges().to_lower()
	for suit_level in equipped_suits.keys():
		var slots = equipped_suits[suit_level]
		if slots.has(canon):
			return {
				"suit_level": suit_level, 
				"equipment": slots[canon]
			}
	return {}


func get_equipped_slots_by_suit(suit_level: int) -> Dictionary:
	return equipped_suits.get(suit_level, {})


func get_equipped_suit_count(suit_level: int) -> int:
	var slots = equipped_suits.get(suit_level, {})
	return slots.size()


func is_full_set_equipped(suit_level: int) -> bool:
	return get_equipped_suit_count(suit_level) >= 5




func calculate_suit_stats() -> Dictionary:
	var total = {
		"attack": 0, 
		"defense": 0, 
		"agility": 0, 
		"hp": 0, 
		"mp": 0
	}

	for suit_level in equipped_suits.keys():
		var suit_level_int = EquipmentManager.coerce_suit_id(suit_level)
		var slots = equipped_suits[suit_level]
		for slot in slots.keys():
			var stat_value = SuitDatabase.get_suit_piece_stats(suit_level_int, slot)
			var stat_name = SuitDatabase.get_slot_stat_name(slot)
			if stat_name and total.has(stat_name):
				total[stat_name] += stat_value

	return total


func calculate_total_set_bonus() -> Dictionary:
	var total_bonus = {
		"attack": 0, 
		"defense": 0, 
		"agility": 0, 
		"hp": 0, 
		"mp": 0
	}

	for suit_level in equipped_suits.keys():
		if is_full_set_equipped(suit_level):
			var slots: Dictionary = equipped_suits.get(suit_level, {})
			var min_enhance_lv: = 999
			var actual_stats: = {
				"attack": 0, 
				"defense": 0, 
				"agility": 0, 
				"hp": 0, 
				"mp": 0
			}
			for eq in slots.values():
				if eq == null:
					continue
				min_enhance_lv = mini(min_enhance_lv, SuitEquipmentEnhance.get_level_from_equipment(eq))
				actual_stats.attack += int(eq.attack)
				actual_stats.defense += int(eq.defense)
				actual_stats.agility += int(eq.agility)
				actual_stats.hp += int(eq.hp)
				actual_stats.mp += int(eq.mp)
			if min_enhance_lv == 999:
				min_enhance_lv = 0
			var bonus_percent: = SuitEquipmentEnhance.total_set_bonus_percent(min_enhance_lv)
			total_bonus.attack += int(round(float(actual_stats.attack) * bonus_percent))
			total_bonus.defense += int(round(float(actual_stats.defense) * bonus_percent))
			total_bonus.agility += int(round(float(actual_stats.agility) * bonus_percent))
			total_bonus.hp += int(round(float(actual_stats.hp) * bonus_percent))
			total_bonus.mp += int(round(float(actual_stats.mp) * bonus_percent))

	return total_bonus


func get_total_suit_stats() -> Dictionary:
	var base = calculate_suit_stats()
	var bonus = calculate_total_set_bonus()

	return {
		"attack": base.get("attack", 0) + bonus.get("attack", 0), 
		"defense": base.get("defense", 0) + bonus.get("defense", 0), 
		"agility": base.get("agility", 0) + bonus.get("agility", 0), 
		"hp": base.get("hp", 0) + bonus.get("hp", 0), 
		"mp": base.get("mp", 0) + bonus.get("mp", 0)
	}


func get_active_suit_sets() -> Array:
	var active_sets = []
	for suit_level in equipped_suits.keys():
		if is_full_set_equipped(suit_level):
			var suit_name = SuitDatabase.get_suit_name(EquipmentManager.coerce_suit_id(suit_level))
			active_sets.append(suit_name)
	return active_sets




func record_first_clear(suit_level: int):
	if not dungeon_progress.has(suit_level):
		dungeon_progress[suit_level] = {}
	dungeon_progress[suit_level]["first_clear"] = true


func is_first_cleared(suit_level: int) -> bool:
	return dungeon_progress.get(suit_level, {}).get("first_clear", false)


func get_daily_sweep_count(suit_level: int) -> int:
	return dungeon_progress.get(suit_level, {}).get("daily_sweep", 0)


func increment_sweep_count(suit_level: int):
	if not dungeon_progress.has(suit_level):
		dungeon_progress[suit_level] = {}
	if not dungeon_progress[suit_level].has("daily_sweep"):
		dungeon_progress[suit_level]["daily_sweep"] = 0
	dungeon_progress[suit_level]["daily_sweep"] += 1


func reset_daily_sweep():
	for suit_level in dungeon_progress.keys():
		dungeon_progress[suit_level]["daily_sweep"] = 0



func to_dict() -> Dictionary:
	var equipped_data = {}
	for suit_level in equipped_suits.keys():
		equipped_data[suit_level] = {}
		for slot in equipped_suits[suit_level].keys():
			equipped_data[suit_level][slot] = equipped_suits[suit_level][slot].to_dict()

	return {
		"equipped_suits": equipped_data, 
		"dungeon_progress": dungeon_progress
	}

func from_dict(data: Variant = {}):
	if data == null or not data is Dictionary:
		return



	if data.has("dungeon_progress"):
		dungeon_progress.clear()
		var progress = data["dungeon_progress"]
		if progress is Dictionary:
			dungeon_progress = progress.duplicate()




func get_equipped_suit_levels() -> Array:
	return equipped_suits.keys()


func get_collection_progress(suit_level: int) -> Dictionary:
	var equipped_count = get_equipped_suit_count(suit_level)
	return {
		"equipped": equipped_count, 
		"total": 5, 
		"is_full": equipped_count >= 5, 
		"missing_slots": _get_missing_slots(suit_level)
	}


func _get_missing_slots(suit_level: int) -> Array:
	var all_slots = ["weapon", "armor", "helmet", "boots", "accessory"]
	var equipped = equipped_suits.get(suit_level, {}).keys()
	var missing = []
	for slot in all_slots:
		if not equipped.has(slot):
			missing.append(slot)
	return missing
