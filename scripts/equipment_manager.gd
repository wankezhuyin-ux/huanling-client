extends Node
class_name EquipmentManager


const GameData = preload("res://scripts/game_data.gd")
const SuitDatabase = preload("res://scripts/data/suit_database_detailed.gd")
const EquipmentGenerationNameTable = preload("res://scripts/equipment_generation_name_table.gd")


var equipped: Dictionary = {
	"weapon": null, 
	"armor": null, 
	"helmet": null, 
	"boots": null, 
	"accessory": null
}


var inventory: Array = []
var max_inventory: int = 56


signal equipment_changed(slot: String, equipment: Equipment)
signal inventory_changed
signal equipment_dropped(equipment: Equipment)

func _normalize_body_equip_slot_name(s: String) -> String:
	return normalize_suit_body_slot(s)


static func normalize_suit_body_slot(raw: Variant) -> String:
	var s: = str(raw).strip_edges().to_lower()
	match s:
		"weapon", "wep", "武器":
			return "weapon"
		"armor", "chest", "body", "护甲", "防具", "衣服":
			return "armor"
		"helmet", "head", "hat", "cap", "hood", "头", "头部", "帽子", "头盔":
			return "helmet"
		"boots", "boot", "shoe", "shoes", "靴", "靴子", "鞋":
			return "boots"
		"accessory", "ring", "necklace", "amulet", "饰品", "配饰":
			return "accessory"
	return ""


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

func _resolve_body_equipped_target_slot(raw_dic: Dictionary, slot_key: Variant) -> String:
	var from_key: = _normalize_body_equip_slot_name(str(slot_key))
	if not from_key.is_empty():
		return from_key
	return _normalize_body_equip_slot_name(str(raw_dic.get("slot", "")))


static func coerce_suit_id(v: Variant) -> int:
	if v == null:
		return 0
	match typeof(v):
		TYPE_INT:
			return v
		TYPE_FLOAT:
			return int(round(v))
		_:
			var s: = str(v).strip_edges()
			if s.is_empty():
				return 0
			if s.is_valid_float():
				return int(round(float(s)))
			if s.is_valid_int():
				return s.to_int()
			return 0


static func infer_suit_id_from_name(equipment_name: Variant) -> int:
	var n: = str(equipment_name).strip_edges()
	if n.is_empty():
		return 0
	for lvl in SuitDatabase.get_all_suit_levels():
		var sid: = int(lvl)
		var suit_name: = str(SuitDatabase.get_suit_name(sid)).strip_edges()
		if not suit_name.is_empty() and n.find(suit_name) >= 0:
			return sid
	return 0


func equip(equipment: Equipment) -> bool:
	var slot: = _normalize_body_equip_slot_name(str(equipment.slot))
	if slot.is_empty():
		push_warning("[EQUIP] 无效装备部位: ", equipment.slot, ", name=", equipment.name)
		return false
	equipment.slot = slot


	if not equipment.is_suit:
		if str(equipment.rarity).strip_edges().to_lower() == "suit" or str(equipment.name).find("套装") >= 0:
			equipment.is_suit = true


	if equipment.is_suit:
		equipment.suit_id = coerce_suit_id(equipment.suit_id)
		if equipment.suit_id <= 0:
			equipment.suit_id = infer_suit_id_from_name(equipment.name)
		var canon_suit_slot: = normalize_suit_body_slot(equipment.suit_slot)
		if canon_suit_slot.is_empty():
			canon_suit_slot = slot
		equipment.suit_slot = canon_suit_slot
		equipment.slot = canon_suit_slot
		slot = canon_suit_slot


	if equipment.is_suit:
		var game_manager = null
		if owner is GameManager:
			game_manager = owner
		elif get_parent() is GameManager:
			game_manager = get_parent()
		else:
			game_manager = get_node_or_null("/root/GameManager")

		if game_manager and game_manager.player:
			var SuitDatabase = load("res://scripts/data/suit_database_detailed.gd")
			var required = SuitDatabase.get_required_cultivation(equipment.suit_id)
			if game_manager.player.cultivation < required:
				print("[EQUIP] 修行值不足，无法装备套装: ", equipment.name, ", 需要: ", required, ", 当前: ", game_manager.player.cultivation)
				return false

	var previous_equipment: Equipment = equipped[slot]


	if equipped[slot] != null:
		unequip(slot)


	inventory.erase(equipment)


	equipment.equipped = true
	equipped[slot] = equipment


	var suit_sync_ok: = true
	if equipment.is_suit:
		var game_manager = null
		if owner is GameManager:
			game_manager = owner
		elif get_parent() is GameManager:
			game_manager = get_parent()
		else:
			game_manager = get_node_or_null("/root/GameManager")

		if game_manager and game_manager.suit_manager:
			var player_cultivation = game_manager.player.cultivation if game_manager.player else 0
			suit_sync_ok = game_manager.suit_manager.equip_suit(equipment, player_cultivation)


	if not suit_sync_ok:
		push_warning("[EQUIP] 套装登记失败，回滚穿戴: ", equipment.name, ", suit_id=", equipment.suit_id, ", suit_slot=", equipment.suit_slot)
		equipment.equipped = false
		equipped[slot] = null
		if not inventory.has(equipment):
			inventory.append(equipment)

		if previous_equipment != null and inventory.has(previous_equipment):
			inventory.erase(previous_equipment)
			previous_equipment.equipped = true
			equipped[slot] = previous_equipment

			if previous_equipment.is_suit:
				var game_manager_restore = null
				if owner is GameManager:
					game_manager_restore = owner
				elif get_parent() is GameManager:
					game_manager_restore = get_parent()
				else:
					game_manager_restore = get_node_or_null("/root/GameManager")
				if game_manager_restore and game_manager_restore.suit_manager:
					var restore_cultivation = game_manager_restore.player.cultivation if game_manager_restore.player else 0
					game_manager_restore.suit_manager.equip_suit(previous_equipment, restore_cultivation, true)

		equipment_changed.emit(slot, equipped[slot])
		inventory_changed.emit()
		return false

	equipment_changed.emit(slot, equipment)
	inventory_changed.emit()
	return true

func unequip(slot: String) -> Equipment:
	var equipment = equipped[slot]

	if equipment == null:
		return null

	var equip_count = 0
	for e in inventory:
		if not e.is_pet_equipment:
			equip_count += 1

	var game_manager = null
	if owner is GameManager:
		game_manager = owner
	elif get_parent() is GameManager:
		game_manager = get_parent()
	else:
		game_manager = get_node_or_null("/root/GameManager")

	if game_manager and game_manager.inventory_manager:
		for item in game_manager.inventory_manager.items:
			if item.item_type == "sealed_suit":
				equip_count += 1

	if equip_count >= max_inventory:
		print("[UNEQUIP] 背包已满，无法卸下装备: ", equipment.name)
		return null

	equipment.equipped = false
	equipped[slot] = null

	if equipment.is_suit:
		if game_manager and game_manager.suit_manager:
			game_manager.suit_manager.unequip_slot(slot)

	inventory.append(equipment)

	equipment_changed.emit(slot, null)
	inventory_changed.emit()
	return equipment

func add_to_inventory(equipment: Equipment) -> bool:

	if equipment.is_pet_equipment:
		push_error("宠物装备不能添加到人物装备栏，请使用 InventoryManager.add_pet_equipment()")
		return false

	if inventory.size() >= max_inventory:
		return false

	inventory.append(equipment)
	inventory_changed.emit()
	return true

func remove_from_inventory(equipment: Equipment) -> bool:
	if equipment.locked:
		return false
	inventory.erase(equipment)
	inventory_changed.emit()
	return true

func remove_from_inventory_online(equipment: Equipment) -> Dictionary:
	var result: = {"success": false, "message": ""}
	if equipment == null:
		result.message = "装备不存在"
		return result
	if equipment.locked:
		result.message = "装备已锁定"
		return result
	var game_manager = null
	if owner is GameManager:
		game_manager = owner
	elif get_parent() is GameManager:
		game_manager = get_parent()
	else:
		game_manager = get_node_or_null("/root/GameManager")
	if game_manager == null or game_manager.network == null or not game_manager.network.is_logged_in():
		result.message = "当前网络不可用，无法丢弃人物装备"
		return result
	var op_id: = "equipment_drop_%s_%d_%s" % [str(equipment.id), Time.get_ticks_usec(), str(randi())]
	var state: = {"done": false, "ok": false, "message": ""}
	var on_success = func(data: Dictionary):
		state.done = true
		state.ok = true
		state.message = str(data.get("message", "人物装备已丢弃"))
		if game_manager and data.has("saveData") and data.get("saveData") is Dictionary:
			var sd: Dictionary = data.get("saveData")
			var apply_opts: = {}
			if sd.has("inventoryData"):
				apply_opts["authoritative_equipment_inventory"] = true
			game_manager.apply_cloud_save(sd, apply_opts)
	var on_failed = func(error: String):
		state.done = true
		state.ok = false
		state.message = error
	game_manager.network.equipment_drop_success.connect(on_success, CONNECT_ONE_SHOT)
	game_manager.network.equipment_drop_failed.connect(on_failed, CONNECT_ONE_SHOT)
	game_manager.network.request_equipment_drop(str(equipment.id), op_id)
	var deadline: = Time.get_ticks_msec() + 15000
	while not bool(state.done) and Time.get_ticks_msec() < deadline and game_manager.is_inside_tree():
		await game_manager.get_tree().process_frame
	if game_manager.network.equipment_drop_success.is_connected(on_success):
		game_manager.network.equipment_drop_success.disconnect(on_success)
	if game_manager.network.equipment_drop_failed.is_connected(on_failed):
		game_manager.network.equipment_drop_failed.disconnect(on_failed)
	if not bool(state.done):
		result.message = "服务器响应超时，请稍后重试"
		push_warning("[EQUIP] 丢弃人物装备等待超时: %s" % str(equipment.id))
		return result
	result.success = bool(state.ok)
	result.message = str(state.message)
	if not bool(state.ok):
		push_warning("[EQUIP] 丢弃人物装备失败: %s" % str(state.message))
	return result

func get_equipment_by_id(equip_id: String) -> Equipment:
	for slot in equipped.keys():
		var e = equipped[slot]
		if e and e.id == equip_id:
			return e
	for e in inventory:
		if e.id == equip_id:
			return e
	return null


func create_equipment_from_data(equip_data: Dictionary) -> Equipment:
	var equipment = Equipment.new()
	equipment.id = equip_data.get("id", equipment.generate_id())
	equipment.name = equip_data.get("name", "未知装备")
	equipment.slot = equip_data.get("slot", "weapon")
	equipment.rarity = equip_data.get("rarity", "common")
	equipment.attack = equip_data.get("attack", 0)
	equipment.defense = equip_data.get("defense", 0)
	equipment.hp = equip_data.get("hp", 0)
	equipment.mp = equip_data.get("mp", 0)
	equipment.agility = equip_data.get("agility", 0)
	equipment.cultivation_req = equip_data.get("cultivation_req", 0)
	equipment.base_cultivation_req = equip_data.get("base_cultivation_req", equipment.cultivation_req)
	equipment.forge_count = equip_data.get("forge_count", 0)
	equipment.forge_attr_counts = equip_data.get("forge_attr_counts", {})
	equipment.locked = equip_data.get("locked", false)

	equipment.is_suit = equip_data.get("is_suit", false)
	equipment.suit_id = coerce_suit_id(equip_data.get("suit_id", 0))
	equipment.suit_slot = normalize_suit_body_slot(equip_data.get("suit_slot", ""))

	equipment.is_sealed = equip_data.get("is_sealed", false)
	equipment.sealed_data = equip_data.get("sealed_data", {})
	if equipment.is_sealed and equipment.sealed_data is Dictionary:
		var sealed_level: = coerce_suit_id(equipment.sealed_data.get("suit_level", equipment.sealed_data.get("suit_id", 0)))
		if sealed_level > 0:
			equipment.suit_id = sealed_level
			equipment.sealed_data["suit_level"] = sealed_level
		var sealed_slot: = normalize_suit_body_slot(equipment.sealed_data.get("slot", ""))
		if not sealed_slot.is_empty():
			equipment.suit_slot = sealed_slot
			equipment.slot = sealed_slot
		equipment.sealed_data["slot"] = equipment.suit_slot
	equipment.suit_enhance_level = clampi(int(equip_data.get("suit_enhance_level", 0)), 0, 9)
	var rolls_raw = equip_data.get("suit_enhance_rolls", [])
	equipment.suit_enhance_rolls = rolls_raw if rolls_raw is Array else []
	equipment.sanitize_loaded_equipment_fields("")
	return equipment


func roll_equipment_drop(cultivation: int, realm: String) -> Equipment:

	if randf() > 0.0:
		return null


	var rarity = _determine_rarity(cultivation, realm)






	var slot = GameData.EQUIPMENT_SLOTS.keys()[randi() % GameData.EQUIPMENT_SLOTS.size()]
	return Equipment.generate(slot, rarity, cultivation)


func generate_pet_equipment(equip_rarity: String, cultivation: int) -> Equipment:
	const PetEquipmentData = preload("res://scripts/pet_equipment/pet_equipment_data.gd")
	var pet_slots = PetEquipmentData.get_all_slots()
	var pet_slot = pet_slots[randi() % pet_slots.size()]

	var equip_slot = PetEquipmentData.get_equipment_slot_from_pet_slot(pet_slot)
	if equip_slot.is_empty():
		equip_slot = "weapon"

	var equipment = Equipment.generate(equip_slot, equip_rarity, cultivation)
	equipment.is_pet_equipment = true
	if not equipment.name.ends_with("（宠）"):
		equipment.name = equipment.name + "（宠）"
	return equipment

func generate_xianmo_chest_equipment(chest_type: String) -> Dictionary:
	const PetEquipmentData = preload("res://scripts/pet_equipment/pet_equipment_data.gd")

	var result = {
		"success": false, 
		"message": "", 
		"equipment": null
	}

	var rarity_map = {
		"bronze": "common", 
		"silver": "rare", 
		"gold": "epic"
	}

	var rarity_name_map = {
		"bronze": "青铜", 
		"silver": "白银", 
		"gold": "黄金"
	}

	var rarity = rarity_map.get(chest_type, "common")

	var pet_slots = PetEquipmentData.get_all_slots()
	var pet_slot = pet_slots[randi() % pet_slots.size()]

	var equip_slot = PetEquipmentData.get_equipment_slot_from_pet_slot(pet_slot)
	if equip_slot.is_empty():
		equip_slot = "weapon"

	var equipment = Equipment.generate(equip_slot, rarity, 0)
	equipment.is_pet_equipment = true

	var variation = 0.2
	if equipment.attack > 0:
		var original = equipment.attack
		var multiplier = 1.0 + randf_range( - variation, variation)
		equipment.attack = max(1, int(original * multiplier))
	if equipment.defense > 0:
		var original = equipment.defense
		var multiplier = 1.0 + randf_range( - variation, variation)
		equipment.defense = max(1, int(original * multiplier))
	if equipment.hp > 0:
		var original = equipment.hp
		var multiplier = 1.0 + randf_range( - variation, variation)
		equipment.hp = max(1, int(original * multiplier))
	if equipment.mp > 0:
		var original = equipment.mp
		var multiplier = 1.0 + randf_range( - variation, variation)
		equipment.mp = max(1, int(original * multiplier))
	if equipment.agility > 0:
		var original = equipment.agility
		var multiplier = 1.0 + randf_range( - variation, variation)
		equipment.agility = max(1, int(original * multiplier))

	const PetEquipment = preload("res://scripts/xianmo/pet_equipment.gd")
	var template_base: = PetEquipment.get_template_base_name(chest_type, equip_slot)
	if not template_base.is_empty():
		equipment.name = template_base + "（宠）"
	elif not equipment.name.ends_with("（宠）"):
		equipment.name = equipment.name + "（宠）"

	var PetEquipmentEnhance = preload("res://scripts/pet_equipment/pet_equipment_enhance.gd")
	equipment.pet_loot_source = PetEquipmentEnhance.PET_LOOT_SOURCE_BSG
	equipment.pet_chest_tier = str(chest_type).strip_edges().to_lower()

	result.success = true
	result.message = "从%s宝箱获得: %s" % [rarity_name_map.get(chest_type, "青铜"), equipment.name]
	result.equipment = equipment

	return result

func create_suit_equipment(suit_level: int, suit_slot: String) -> Equipment:
	var equipment = Equipment.new()
	equipment.is_suit = true
	equipment.suit_id = coerce_suit_id(suit_level)
	equipment.suit_slot = normalize_suit_body_slot(suit_slot)
	if equipment.suit_slot.is_empty():
		equipment.suit_slot = "weapon"
	equipment.slot = equipment.suit_slot
	equipment.rarity = "suit"


	var suit_data = SuitDatabase.get_suit_data(equipment.suit_id)
	equipment.name = suit_data.get("name", "未知套装") + "·" + SuitDatabase.get_slot_name(equipment.suit_slot)
	equipment.cultivation_req = suit_data.get("required_cultivation", 0)


	var stat_value = SuitDatabase.get_suit_piece_stats(equipment.suit_id, equipment.suit_slot)
	match equipment.suit_slot:
		"weapon":
			equipment.attack = stat_value
		"armor":
			equipment.defense = stat_value
		"helmet":
			equipment.hp = stat_value
		"boots":
			equipment.agility = stat_value
		"accessory":
			equipment.mp = stat_value

	return equipment




func create_sealed_suit_equipment(sealed_data: Dictionary) -> Equipment:
	var equipment = Equipment.new()
	equipment.is_suit = true
	equipment.is_sealed = true
	equipment.sealed_data = sealed_data.duplicate()
	equipment.suit_id = coerce_suit_id(equipment.sealed_data.get("suit_level", 1))
	if equipment.sealed_data is Dictionary:
		equipment.sealed_data["suit_level"] = equipment.suit_id
	equipment.suit_slot = normalize_suit_body_slot(sealed_data.get("slot", "weapon"))
	if equipment.suit_slot.is_empty():
		equipment.suit_slot = "weapon"
	equipment.slot = equipment.suit_slot
	equipment.rarity = "suit"
	equipment.name = sealed_data.get("name", "未知封印套装")


	return equipment


func unseal_suit_equipment(equipment: Equipment, inventory_manager, game_manager) -> Dictionary:
	if not equipment.is_suit or not equipment.is_sealed:
		return {"success": false, "message": "该装备不需要解封"}

	var SuitDatabaseDetailed = load("res://scripts/data/suit_database_detailed.gd")


	var stone_name = SuitDatabaseDetailed.get_seal_stone_name(equipment.suit_id)
	if not inventory_manager.has_item(stone_name, 1):
		return {"success": false, "message": "缺少 %s" % stone_name}


	var unseal_cost = SuitDatabaseDetailed.get_unseal_cost()
	if game_manager.player.gold < unseal_cost.gold:
		return {"success": false, "message": "金币不足，需要 %d 万金币" % (unseal_cost.gold / 10000)}


	var remove_result = inventory_manager.remove_item_by_name(stone_name, 1)
	if not remove_result.success:
		return {"success": false, "message": "扣除解封石失败"}

	game_manager.player.gold -= unseal_cost.gold
	game_manager.gold_changed.emit(game_manager.player.gold)


	var success = randf() < unseal_cost.success_rate

	if success:

		equipment.is_sealed = false


		var base_stats = equipment.sealed_data.get("base_stats", {})
		var variation_min = SuitDatabaseDetailed.STAT_VARIATION["min"]
		var variation_max = SuitDatabaseDetailed.STAT_VARIATION["max"]


		match equipment.suit_slot:
			"weapon":
				equipment.attack = int(base_stats.get("attack", 0) * randf_range(variation_min, variation_max))
			"armor":
				equipment.defense = int(base_stats.get("defense", 0) * randf_range(variation_min, variation_max))
			"helmet":
				equipment.hp = int(base_stats.get("hp", 0) * randf_range(variation_min, variation_max))
			"boots":
				equipment.agility = int(base_stats.get("agility", 0) * randf_range(variation_min, variation_max))
			"accessory":
				equipment.mp = int(base_stats.get("mp", 0) * randf_range(variation_min, variation_max))


		var original_name = equipment.sealed_data.get("name", equipment.name)
		equipment.name = original_name.replace("(封印)", "").replace("（封印）", "")


		if not add_to_inventory(equipment):
			return {"success": false, "message": "装备背包已满，无法添加解封后的装备"}

		return {"success": true, "message": "解封成功！%s" % equipment.name}
	else:

		return {"success": false, "message": "解封失败！解封石和金币已消耗"}

func _determine_rarity(cultivation: int, realm: String) -> String:
	var roll = randf()


	var divine_chance = min(0.001 * (cultivation / 100000.0), 0.01)
	var mythic_chance = min(0.003 * (cultivation / 50000.0), 0.03)
	var legendary_chance = min(0.01 * (cultivation / 10000.0), 0.05)
	var epic_chance = min(0.04 * (cultivation / 5000.0), 0.1)
	var rare_chance = min(0.1 * (cultivation / 2000.0), 0.2)
	var uncommon_chance = 0.25

	if roll < divine_chance:
		return "divine"
	elif roll < divine_chance + mythic_chance:
		return "mythic"
	elif roll < divine_chance + mythic_chance + legendary_chance:
		return "legendary"
	elif roll < divine_chance + mythic_chance + legendary_chance + epic_chance:
		return "epic"
	elif roll < divine_chance + mythic_chance + legendary_chance + epic_chance + rare_chance:
		return "rare"
	elif roll < divine_chance + mythic_chance + legendary_chance + epic_chance + rare_chance + uncommon_chance:
		return "uncommon"
	else:
		return "common"


func get_total_stats() -> Dictionary:
	var stats = {
		"attack": 0, 
		"defense": 0, 
		"hp": 0, 
		"mp": 0, 
		"agility": 0
	}

	for slot in equipped.keys():
		var equipment = equipped[slot]
		if equipment:
			stats.attack += equipment.attack
			stats.defense += equipment.defense
			stats.hp += equipment.hp
			stats.mp += equipment.mp
			stats.agility += equipment.agility

	return stats


func to_dict() -> Dictionary:
	var equipped_data = {}
	for slot in equipped.keys():
		if equipped[slot]:
			equipped_data[slot] = equipped[slot].to_dict()

	var inventory_data = []
	for equipment in inventory:
		inventory_data.append(equipment.to_dict())

	return {
		"equipped": equipped_data, 
		"inventory": inventory_data
	}

func from_dict(data: Variant = {}):
	if data == null or not data is Dictionary:
		return

	if data.has("equipped"):
		for slot in equipped.keys():
			equipped[slot] = null

		var equipped_src: Dictionary = {}
		var raw_eq = data.get("equipped", null)
		if raw_eq is Dictionary:
			equipped_src = raw_eq

		for slot_key in equipped_src.keys():
			var raw_slot: = _coerce_equipment_dict(equipped_src[slot_key])
			if raw_slot.is_empty():
				continue
			var target: = _resolve_body_equipped_target_slot(raw_slot, slot_key)
			if target.is_empty() or not equipped.has(target):
				continue
			var equipment = Equipment.new()
			equipment.from_dict(raw_slot, target)
			if str(equipment.id).strip_edges().is_empty():
				continue
			equipped[target] = equipment

	if data.has("inventory"):
		inventory.clear()
		var inventory_data = data.get("inventory", [])
		if inventory_data == null or not inventory_data is Array:
			inventory_data = []
		for equipment_dict in inventory_data:
			var raw_inv: = _coerce_equipment_dict(equipment_dict)
			if raw_inv.is_empty():
				continue
			var equipment = Equipment.new()
			equipment.from_dict(raw_inv)
			if inventory.size() < max_inventory:
				inventory.append(equipment)
			else:
				print("[LOAD] 背包已满，跳过装备: ", equipment.name)

	_sync_equipped_suits_to_manager()

const _NAMED_BODY_SLOTS_RESTORE: Array = ["weapon", "armor", "helmet", "boots", "accessory"]



func restore_named_equipped_from_saved_snapshot(local_equipment_dict: Dictionary) -> void :
	if local_equipment_dict == null or not local_equipment_dict is Dictionary or local_equipment_dict.is_empty():
		return
	var equipped_src: Variant = local_equipment_dict.get("equipped", {})
	if equipped_src == null or not equipped_src is Dictionary:
		return
	for slot in _NAMED_BODY_SLOTS_RESTORE:
		if equipped.get(slot) != null:
			continue
		if not (equipped_src as Dictionary).has(slot):
			continue
		var raw_slot: = _coerce_equipment_dict((equipped_src as Dictionary)[slot])
		if raw_slot.is_empty():
			continue
		var nm: = str(raw_slot.get("name", "")).strip_edges()
		if nm.is_empty():
			continue
		var equipment = Equipment.new()
		equipment.from_dict(raw_slot, slot)
		if str(equipment.id).strip_edges().is_empty():
			continue
		equipped[slot] = equipment
		equipment.equipped = true
		equipment_changed.emit(slot, equipment)
	inventory_changed.emit()
	_sync_equipped_suits_to_manager()


func _sync_equipped_suits_to_manager():

	var game_manager = null
	if owner is GameManager:
		game_manager = owner
	elif get_parent() is GameManager:
		game_manager = get_parent()
	else:
		game_manager = get_node_or_null("/root/GameManager")

	print("[SUIT_SYNC] game_manager = ", game_manager, ", suit_manager = ", game_manager.suit_manager if game_manager else "N/A")

	if not game_manager or not game_manager.suit_manager:
		print("[SUIT_SYNC] game_manager or suit_manager is null, will retry later")

		call_deferred("_sync_equipped_suits_to_manager_deferred")
		return

	_sync_equipped_suits_to_manager_internal(game_manager)

func _sync_equipped_suits_to_manager_deferred():
	var game_manager = get_node_or_null("/root/GameManager")
	if not game_manager or not game_manager.suit_manager:
		print("[SUIT_SYNC] Deferred retry failed, game_manager or suit_manager still null")
		return
	_sync_equipped_suits_to_manager_internal(game_manager)

func _sync_equipped_suits_to_manager_internal(game_manager):
	print("[SUIT_SYNC] Syncing equipped suits to manager (skip cultivation check)")

	game_manager.suit_manager.equipped_suits.clear()

	for slot in equipped.keys():
		var equipment = equipped[slot]
		print("[SUIT_SYNC] Checking slot: ", slot, ", equipment: ", equipment.name if equipment else "null", ", is_suit: ", equipment.is_suit if equipment else "N/A")
		if equipment:
			if not equipment.is_suit and (str(equipment.rarity).strip_edges().to_lower() == "suit" or str(equipment.name).find("套装") >= 0):
				equipment.is_suit = true
		if equipment and equipment.is_suit:
			equipment.suit_id = coerce_suit_id(equipment.suit_id)
			if equipment.suit_id <= 0:
				equipment.suit_id = infer_suit_id_from_name(equipment.name)
			equipment.suit_slot = normalize_suit_body_slot(equipment.suit_slot)
			if equipment.suit_slot.is_empty():
				equipment.suit_slot = normalize_suit_body_slot(equipment.slot)
			print("[SUIT_SYNC] Syncing suit: ", equipment.name, ", suit_id: ", equipment.suit_id, ", suit_slot: ", equipment.suit_slot)
			if equipment.suit_slot.is_empty():
				push_warning("[SUIT_SYNC] Skip suit due to invalid slot: ", equipment.name, ", raw_slot=", equipment.slot)
				continue
			var result = game_manager.suit_manager.equip_suit(equipment, 0, true)
			print("[SUIT_SYNC] equip_suit result: ", result)
			if not result:
				push_warning("[SUIT_SYNC] equip_suit failed: name=", equipment.name, ", suit_id=", equipment.suit_id, ", suit_slot=", equipment.suit_slot, ", slot=", equipment.slot)

	var sync_summary: Dictionary = {}
	for suit_level in game_manager.suit_manager.equipped_suits.keys():
		var lv = coerce_suit_id(suit_level)
		sync_summary[lv] = game_manager.suit_manager.get_equipped_suit_count(lv)
	print("[SUIT_SYNC] Summary counts: ", sync_summary)


class Equipment:
	var id: String
	var name: String
	var slot: String
	var rarity: String
	var attack: int = 0
	var defense: int = 0
	var hp: int = 0
	var mp: int = 0
	var agility: int = 0
	var cultivation_req: int = 0
	var base_cultivation_req: int = 0
	var forge_count: int = 0
	var forge_attr_counts: Dictionary = {}
	var equipped: bool = false
	var locked: bool = false


	var is_suit: bool = false
	var suit_id: int = 0
	var suit_slot: String = ""


	var is_sealed: bool = false
	var sealed_data: Dictionary = {}


	var is_pet_equipment: bool = false
	var pet_enhance_level: int = 0
	var suit_enhance_level: int = 0
	var suit_enhance_rolls: Array = []

	var pet_loot_source: String = ""

	var pet_chest_tier: String = ""

	func _init():
		id = generate_id()

	func generate_id() -> String:
		var chars = "abcdefghijklmnopqrstuvwxyz0123456789"
		var result = ""
		for i in range(8):
			result += chars[randi() % chars.length()]
		return result

	static func generate(equip_slot: String, equip_rarity: String, cultivation: int) -> Equipment:
		var equipment = Equipment.new()
		equipment.slot = equip_slot
		equipment.rarity = equip_rarity
		equipment.cultivation_req = cultivation
		equipment.base_cultivation_req = cultivation


		equipment.name = _generate_name(equip_slot, equip_rarity)


		var multiplier = GameData.EQUIPMENT_RARITY[equip_rarity].multiplier
		var base_stats = _get_base_stats_for_slot(equip_slot)

		equipment.attack = int(base_stats.attack * multiplier * randf_range(0.8, 1.2))
		equipment.defense = int(base_stats.defense * multiplier * randf_range(0.8, 1.2))
		equipment.hp = int(base_stats.hp * multiplier * randf_range(0.8, 1.2))
		equipment.mp = int(base_stats.mp * multiplier * randf_range(0.8, 1.2))
		equipment.agility = int(base_stats.agility * multiplier * randf_range(0.8, 1.2))

		return equipment

	static func _generate_name(equip_slot: String, equip_rarity: String) -> String:
		return EquipmentGenerationNameTable.pick_random_name(equip_slot, equip_rarity)

	static func _get_base_stats_for_slot(equip_slot: String) -> Dictionary:
		var base = {
			"weapon": {"attack": 10, "defense": 0, "hp": 0, "mp": 0, "agility": 0}, 
			"armor": {"attack": 0, "defense": 10, "hp": 0, "mp": 0, "agility": 0}, 
			"helmet": {"attack": 0, "defense": 0, "hp": 30, "mp": 0, "agility": 0}, 
			"boots": {"attack": 0, "defense": 0, "hp": 0, "mp": 0, "agility": 10}, 
			"accessory": {"attack": 0, "defense": 0, "hp": 0, "mp": 20, "agility": 0}
		}
		return base.get(equip_slot, base["weapon"])

	func get_rarity_name() -> String:
		if rarity == "suit":
			return "套装"
		return GameData.EQUIPMENT_RARITY.get(rarity, {}).get("name", "普通")

	func get_rarity_color() -> Color:
		if rarity == "suit":
			return Color(1, 0.6, 0)
		return GameData.EQUIPMENT_RARITY.get(rarity, {}).get("color", Color.WHITE)

	func get_slot_name() -> String:
		return GameData.EQUIPMENT_SLOTS.get(slot, "未知")

	func to_dict() -> Dictionary:
		return {
			"id": id, 
			"name": name, 
			"slot": slot, 
			"rarity": rarity, 
			"attack": attack, 
			"defense": defense, 
			"hp": hp, 
			"mp": mp, 
			"agility": agility, 
			"cultivation_req": cultivation_req, 
			"base_cultivation_req": base_cultivation_req, 
			"forge_count": forge_count, 
			"forge_attr_counts": forge_attr_counts, 
			"equipped": equipped, 
			"locked": locked, 
			"is_suit": is_suit, 
			"suit_id": suit_id, 
			"suit_slot": suit_slot, 
			"is_sealed": is_sealed, 
			"sealed_data": sealed_data, 
			"is_pet_equipment": is_pet_equipment, 
			"pet_enhance_level": pet_enhance_level, 
			"suit_enhance_level": suit_enhance_level, 
			"suit_enhance_rolls": suit_enhance_rolls.duplicate() if suit_enhance_rolls is Array else [], 
			"pet_loot_source": pet_loot_source, 
			"pet_chest_tier": pet_chest_tier
		}


	func sanitize_loaded_equipment_fields(equipment_slot_hint: String = "") -> void :
		var id_s: = str(id).strip_edges()
		if id_s.is_empty():
			id = generate_id()
		else:
			id = id_s

		var nm: = str(name).strip_edges()
		if nm.is_empty():
			if sealed_data is Dictionary:
				nm = str(sealed_data.get("name", "")).strip_edges()
			if nm.is_empty():
				name = "未知装备(%s)" % id
			else:
				name = nm
		else:
			name = nm

		var sl: = str(slot).strip_edges()
		if sl.is_empty():
			var hint: = str(equipment_slot_hint).strip_edges()
			if not hint.is_empty():
				slot = hint
			else:
				var suit_s: = str(suit_slot).strip_edges()
				if not suit_s.is_empty():
					slot = suit_s
				else:
					slot = "weapon"
		else:
			slot = sl
		var canon_slot: = EquipmentManager.normalize_suit_body_slot(slot)
		if not canon_slot.is_empty():
			slot = canon_slot

		var rar: = str(rarity).strip_edges()
		if rar.is_empty():
			rarity = "common"
		else:
			rarity = rar

		if not is_suit and (str(rarity).strip_edges().to_lower() == "suit" or str(name).find("套装") >= 0):
			is_suit = true

		if is_suit and suit_id > 0 and str(suit_slot).strip_edges().is_empty():
			var rs2: = EquipmentManager.normalize_suit_body_slot(slot)
			if rs2.is_empty() and is_sealed and sealed_data is Dictionary:
				rs2 = EquipmentManager.normalize_suit_body_slot(sealed_data.get("slot", ""))
			if not rs2.is_empty():
				suit_slot = rs2
		if is_suit:
			suit_id = EquipmentManager.coerce_suit_id(suit_id)
			if suit_id <= 0:
				suit_id = EquipmentManager.infer_suit_id_from_name(name)
			var canon_suit_slot: = EquipmentManager.normalize_suit_body_slot(suit_slot)
			if canon_suit_slot.is_empty() and is_sealed and sealed_data is Dictionary:
				canon_suit_slot = EquipmentManager.normalize_suit_body_slot(sealed_data.get("slot", ""))
			if canon_suit_slot.is_empty():
				canon_suit_slot = EquipmentManager.normalize_suit_body_slot(slot)
			suit_slot = canon_suit_slot
			if not suit_slot.is_empty():
				slot = suit_slot

	func from_dict(data: Dictionary, equipment_slot_hint: String = ""):
		if data.has("id") and data["id"] != null and str(data["id"]).strip_edges() != "":
			id = str(data["id"]).strip_edges()
		else:
			id = generate_id()
		name = data.get("name", "未知装备")
		slot = data.get("slot", "weapon")
		rarity = data.get("rarity", "common")
		attack = data.get("attack", 0)
		defense = data.get("defense", 0)
		hp = data.get("hp", 0)
		mp = data.get("mp", 0)
		agility = data.get("agility", 0)
		cultivation_req = data.get("cultivation_req", 0)
		base_cultivation_req = data.get("base_cultivation_req", cultivation_req)
		forge_count = data.get("forge_count", 0)
		forge_attr_counts = data.get("forge_attr_counts", {})
		equipped = data.get("equipped", false)
		locked = data.get("locked", false)
		is_suit = data.get("is_suit", false)
		suit_id = EquipmentManager.coerce_suit_id(data.get("suit_id", 0))
		suit_slot = EquipmentManager.normalize_suit_body_slot(data.get("suit_slot", ""))

		if is_suit and suit_id > 0 and str(suit_slot).strip_edges().is_empty():
			var rs: = EquipmentManager.normalize_suit_body_slot(slot)
			if not rs.is_empty():
				suit_slot = rs
		is_sealed = data.get("is_sealed", false)
		sealed_data = data.get("sealed_data", {})
		if sealed_data is Dictionary and sealed_data.has("suit_level"):
			sealed_data["suit_level"] = EquipmentManager.coerce_suit_id(sealed_data.get("suit_level", 0))
		is_pet_equipment = data.get("is_pet_equipment", false)
		pet_enhance_level = int(data.get("pet_enhance_level", 0))
		suit_enhance_level = clampi(int(data.get("suit_enhance_level", 0)), 0, 9)
		var rolls_raw = data.get("suit_enhance_rolls", [])
		suit_enhance_rolls = rolls_raw if rolls_raw is Array else []
		pet_loot_source = str(data.get("pet_loot_source", ""))
		pet_chest_tier = str(data.get("pet_chest_tier", ""))


		if is_suit and not is_sealed:
			name = name.replace("(封印)", "").replace("（封印）", "")


		if is_suit and suit_id > 0 and not suit_slot.is_empty():
			if is_sealed and sealed_data is Dictionary:
				var _sl = int(sealed_data.get("suit_level", suit_id))
				var _slt = str(sealed_data.get("slot", suit_slot))
				sealed_data["base_stats"] = SuitDatabase.get_piece_stats(_sl, _slt)
			elif not is_sealed:
				if suit_slot == "armor" and hp > 0 and defense == 0:
					defense = hp
					hp = 0
				elif suit_slot == "helmet" and defense > 0 and hp == 0:
					hp = defense
					defense = 0

		sanitize_loaded_equipment_fields(equipment_slot_hint)
