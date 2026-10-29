extends Node
class_name CraftingManager

const GameData = preload("res://scripts/game_data.gd")

var inventory_manager: Node = null
var equipment_manager: Node = null

signal crafting_success(recipe_id: String, result)
signal crafting_failed(recipe_id: String, message: String)

func set_managers(inventory: Node, equipment: Node):
	inventory_manager = inventory
	equipment_manager = equipment

func get_available_recipes(realm: String) -> Dictionary:
	var realm_index = GameData.REALMS.find(realm)
	if realm_index == -1:
		realm_index = 0

	var available = {}
	for recipe_id in GameData.CRAFTING_RECIPES.keys():
		var recipe = GameData.CRAFTING_RECIPES[recipe_id]
		var req_realm = recipe.get("realm_req", "凡人")
		var req_index = GameData.REALMS.find(req_realm)
		if req_index == -1:
			req_index = 0

		if realm_index >= req_index:
			available[recipe_id] = recipe

	return available

func can_craft(recipe_id: String, realm: String) -> Dictionary:
	var result = {"can_craft": false, "message": ""}

	if not GameData.CRAFTING_RECIPES.has(recipe_id):
		result.message = "配方不存在"
		return result

	var recipe = GameData.CRAFTING_RECIPES[recipe_id]

	var req_realm = recipe.get("realm_req", "凡人")
	var realm_index = GameData.REALMS.find(realm)
	var req_index = GameData.REALMS.find(req_realm)

	if realm_index == -1:
		realm_index = 0
	if req_index == -1:
		req_index = 0

	if realm_index < req_index:
		result.message = "境界不足，需要达到【%s】境界" % req_realm
		return result

	var materials = recipe.get("materials", {})
	for material_name in materials.keys():
		var required_count = materials[material_name]
		var have_count = get_bag_material_count(str(material_name))
		if have_count < required_count:
			result.message = "材料不足：%s 需要%d个，已有%d个" % [material_name, required_count, have_count]
			return result

	result.can_craft = true
	result.message = "可以打造"
	return result

func craft(recipe_id: String, realm: String, player_level: int = 1, cultivation: int = 0) -> Dictionary:
	var result = {"success": false, "message": "", "item": null, "poem": ""}

	var can_result = can_craft(recipe_id, realm)
	if not can_result.can_craft:
		result.message = can_result.message
		crafting_failed.emit(recipe_id, result.message)
		return result

	var recipe = GameData.CRAFTING_RECIPES[recipe_id]
	var materials = recipe.get("materials", {})
	var success_rate = recipe.get("success_rate", 0.5)

	for material_name in materials.keys():
		var count = materials[material_name]
		_remove_material(material_name, count)

	if randf() > success_rate:
		result.message = "打造失败！材料已消耗..."
		crafting_failed.emit(recipe_id, result.message)
		return result

	var craft_type = recipe.get("type", "equipment")

	if craft_type == "equipment":
		if equipment_manager and equipment_manager.inventory.size() >= equipment_manager.max_inventory:
			result.message = "装备背包已满！无法打造"
			crafting_failed.emit(recipe_id, result.message)
			return result

		var slot = recipe.get("slot", "weapon")
		var rarity = recipe.get("rarity", "common")

		if randf() < 0.15:
			var rarity_order = ["common", "uncommon", "rare", "epic", "legendary", "mythic", "divine"]
			var rarity_index = rarity_order.find(rarity)
			if rarity_index != -1 and rarity_index < rarity_order.size() - 1:
				rarity = rarity_order[rarity_index + 1]

		var equipment = EquipmentManager.Equipment.generate(slot, rarity, cultivation)
		if equipment_manager:
			equipment_manager.add_to_inventory(equipment)

		var rarity_info = GameData.EQUIPMENT_RARITY.get(equipment.rarity, {})
		var rarity_name = rarity_info.get("name", "未知")

		var rarity_poems = {
			"epic": "炉火纯青，神工鬼斧，史诗现世，威震四方。", 
			"legendary": "天工开物，神匠降临，传说诞生，举世无双。", 
			"mythic": "神物天成，灵气所钟，神话降临，万古流芳。", 
			"divine": "天地为炉，造化为工，至尊神器，傲视苍穹。"
		}

		result.success = true
		result.message = "打造成功！获得【%s】%s" % [rarity_name, equipment.name]
		result.item = equipment
		if equipment.rarity in rarity_poems:
			result.poem = rarity_poems[equipment.rarity]
		crafting_success.emit(recipe_id, equipment)
		return result

	elif craft_type in ["pill", "special", "cultivation_pill"]:
		var result_name = recipe.get("result", "")
		if result_name != "" and inventory_manager:
			var add_result = inventory_manager.add_item(result_name, 1)
			if add_result.success:
				result.success = true
				result.message = "打造成功！获得【%s】" % result_name
				result.item = add_result.item
				crafting_success.emit(recipe_id, result.item)
				return result
			else:
				result.message = "获得【%s】但背包已满" % result_name
				crafting_failed.emit(recipe_id, result.message)
				return result

	result.message = "打造失败：未知配方类型"
	crafting_failed.emit(recipe_id, result.message)
	return result

func _remove_material(material_name: String, count: int):
	if not inventory_manager:
		return

	for i in range(inventory_manager.items.size() - 1, -1, -1):
		var item = inventory_manager.items[i]
		if item.name == material_name:
			if item.count <= count:
				count -= item.count
				inventory_manager.items.remove_at(i)
			else:
				item.count -= count
				count = 0
			if count <= 0:
				break

	inventory_manager.inventory_changed.emit()

func get_recipe_info(recipe_id: String) -> Dictionary:
	return GameData.CRAFTING_RECIPES.get(recipe_id, {})

func get_recipes_by_type(craft_type: String) -> Dictionary:
	var result = {}
	for recipe_id in GameData.CRAFTING_RECIPES.keys():
		var recipe = GameData.CRAFTING_RECIPES[recipe_id]
		if recipe.get("type", "") == craft_type:
			result[recipe_id] = recipe
	return result

func to_dict() -> Dictionary:
	return {}

func from_dict(_data: Variant = {}):
	pass

const PILL_BATCH_CRAFT_MAX: = 50

func get_max_batch_craft_count(recipe_id: String, realm: String) -> int:
	var can_result = can_craft(recipe_id, realm)
	if not can_result.can_craft:
		return 0
	if not GameData.CRAFTING_RECIPES.has(recipe_id):
		return 0
	var recipe = GameData.CRAFTING_RECIPES[recipe_id]
	var materials = recipe.get("materials", {})
	var max_count: = 2147483647
	for material_name in materials.keys():
		var required_count: int = maxi(1, int(materials[material_name]))
		var have_count: int = get_bag_material_count(str(material_name))
		max_count = mini(max_count, have_count / required_count)
	return mini(maxi(0, max_count), PILL_BATCH_CRAFT_MAX)

func get_bag_material_count(material_name: String) -> int:
	if inventory_manager == null or material_name.is_empty():
		return 0
	var items = inventory_manager.items
	if items == null:
		return 0
	var total: = 0
	for item in items:
		if item == null:
			continue
		if str(item.name) != material_name:
			continue
		total += maxi(0, int(item.count))
	return total
