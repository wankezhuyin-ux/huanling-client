extends Node
class_name PetEquipmentManager

const PetEquipmentData = preload("res://scripts/pet_equipment/pet_equipment_data.gd")
const PetEquipmentEnhance = preload("res://scripts/pet_equipment/pet_equipment_enhance.gd")

var equipped: Dictionary = {
	"pet_weapon": null, 
	"pet_armor": null, 
	"pet_boots": null, 
	"pet_helmet": null, 
	"pet_accessory": null
}

signal equipment_changed(slot: String, equipment: EquipmentManager.Equipment)
signal bonus_changed(bonus: Dictionary)

func _coerce_equipment_dict(raw: Variant) -> Dictionary:
	if raw == null:
		return {}
	if raw is Dictionary:
		return raw
	if raw is String:
		var t: String = String(raw).strip_edges()
		if t.is_empty():
			return {}
		var parsed = JSON.parse_string(t)
		if parsed is Dictionary:
			return parsed
	return {}

func _resolve_pet_equipped_target_slot(raw_dic: Dictionary, slot_key: Variant) -> String:
	var sk: = str(slot_key).strip_edges().to_lower()
	if equipped.has(sk):
		return sk
	var pet_via: = PetEquipmentData.get_pet_slot_from_equipment_slot(sk)
	if not pet_via.is_empty() and equipped.has(pet_via):
		return pet_via
	var from_eq: = str(raw_dic.get("slot", "")).strip_edges().to_lower()
	if from_eq.is_empty():
		return ""
	var p2: = PetEquipmentData.get_pet_slot_from_equipment_slot(from_eq)
	if not p2.is_empty() and equipped.has(p2):
		return p2
	return ""

func _ready():
	pass

func equip(equipment: EquipmentManager.Equipment) -> Dictionary:
	var result = {"success": false, "message": "", "unequipped": null}
	var game_manager = GameManager.instance
	if game_manager == null or (not game_manager.has_method("local_equipment_op") and (game_manager.network == null or not game_manager.network.is_logged_in())):
		result.message = "当前网络不可用，已阻止穿戴。"
		return result

	if not equipment.is_pet_equipment:
		result.message = "该装备不是宠物装备"
		return result

	var pet_slot = PetEquipmentData.get_pet_slot_from_equipment_slot(equipment.slot)

	if pet_slot.is_empty():
		result.message = "无法装备到宠物"
		return result

	if equipped.has(pet_slot) and equipped[pet_slot] != null:
		result.unequipped = equipped[pet_slot]

	equipment.equipped = true
	equipped[pet_slot] = equipment

	equipment_changed.emit(pet_slot, equipment)
	bonus_changed.emit(get_all_bonus())

	result.success = true
	result.message = "宠物装备成功：%s" % equipment.name
	return result

func unequip(pet_slot: String) -> EquipmentManager.Equipment:
	var game_manager = GameManager.instance
	if game_manager == null or (not game_manager.has_method("local_equipment_op") and (game_manager.network == null or not game_manager.network.is_logged_in())):
		return null
	if not equipped.has(pet_slot):
		return null

	var equipment = equipped[pet_slot]
	if equipment == null:
		return null

	equipment.equipped = false
	equipped[pet_slot] = null

	equipment_changed.emit(pet_slot, null)
	bonus_changed.emit(get_all_bonus())

	return equipment

func unequip_by_equipment_slot(equipment_slot: String) -> EquipmentManager.Equipment:
	var pet_slot = PetEquipmentData.get_pet_slot_from_equipment_slot(equipment_slot)
	if pet_slot.is_empty():
		return null
	return unequip(pet_slot)

func unequip_by_equipment(equipment: EquipmentManager.Equipment) -> Dictionary:
	var result = {"success": false, "message": "", "equipment": null}

	for slot in equipped.keys():
		if equipped[slot] == equipment:
			result.equipment = unequip(slot)
			if result.equipment != null:
				result.success = true
				result.message = "已卸下装备：%s" % result.equipment.name
			return result

	result.message = "未找到该装备"
	return result

func get_equipped(pet_slot: String) -> EquipmentManager.Equipment:
	return equipped.get(pet_slot, null)

func get_all_equipped() -> Dictionary:
	return equipped.duplicate()

func get_bonus(active_pet, stat_type: String) -> float:
	if active_pet == null:
		return 0.0

	var total = 0.0

	for pet_slot in equipped.keys():
		var equipment = equipped[pet_slot]
		if equipment == null:
			continue

		var slot_stat = PetEquipmentData.get_slot_stat(pet_slot)

		if slot_stat == stat_type:
			var lv: = PetEquipmentEnhance.get_level_from_equipment(equipment)
			match stat_type:
				"attack":
					total += PetEquipmentEnhance.effective_stat(equipment.attack, lv)
				"defense":
					total += PetEquipmentEnhance.effective_stat(equipment.defense, lv)
				"agility":
					total += PetEquipmentEnhance.effective_stat(equipment.agility, lv)
				"hp":
					total += PetEquipmentEnhance.effective_stat(equipment.hp, lv)

	return total

func get_all_bonus(active_pet = null) -> Dictionary:
	return {
		"attack": get_bonus(active_pet, "attack"), 
		"defense": get_bonus(active_pet, "defense"), 
		"agility": get_bonus(active_pet, "agility"), 
		"hp": get_bonus(active_pet, "hp")
	}

func has_equipment_in_slot(pet_slot: String) -> bool:
	return equipped.has(pet_slot) and equipped[pet_slot] != null

func to_dict() -> Dictionary:
	var equipped_data = {}
	for slot in equipped.keys():
		if equipped[slot] != null:
			equipped_data[slot] = equipped[slot].to_dict()

	return {
		"equipped": equipped_data
	}

func from_dict(data: Variant):
	if data == null or not data is Dictionary:
		return

	if data.has("equipped"):
		var equipped_data: Dictionary = {}
		var raw_container = data.get("equipped", null)
		if raw_container is Dictionary:
			equipped_data = raw_container


		for slot in equipped.keys():
			equipped[slot] = null

		if equipped_data.size() > 0:
			for slot_key in equipped_data.keys():
				var raw_slot: = _coerce_equipment_dict(equipped_data[slot_key])
				if raw_slot.is_empty():
					continue
				var target: = _resolve_pet_equipped_target_slot(raw_slot, slot_key)
				if target.is_empty():
					continue
				var equipment = EquipmentManager.Equipment.new()
				var hint: = PetEquipmentData.get_equipment_slot_from_pet_slot(target)
				equipment.from_dict(raw_slot, hint)
				if str(equipment.id).strip_edges().is_empty():
					continue
				equipped[target] = equipment

		bonus_changed.emit(get_all_bonus())
