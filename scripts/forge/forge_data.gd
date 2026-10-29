extends RefCounted
class_name ForgeData

const ForgeConfig = preload("res://scripts/forge/forge_config.gd")

var limit_equipments: Dictionary = {}

func _init():
	_init_limit_equipments()

func _init_limit_equipments():
	limit_equipments = {
		"weapon": {
			"id": "limit_weapon", 
			"name": "极限武器", 
			"slot": "weapon", 
			"rarity": "legendary", 
			"attack": ForgeConfig.LIMIT_VALUES.attack, 
			"defense": 0, 
			"agility": 0, 
			"hp": 0, 
			"mp": 0, 
			"is_limit": true, 
			"price": 10000000, 
			"description": "攻击达到极限的武器，可作为锻造材料", 
		}, 
		"armor": {
			"id": "limit_armor", 
			"name": "极限衣服", 
			"slot": "armor", 
			"rarity": "legendary", 
			"attack": 0, 
			"defense": ForgeConfig.LIMIT_VALUES.defense, 
			"agility": 0, 
			"hp": 0, 
			"mp": 0, 
			"is_limit": true, 
			"price": 10000000, 
			"description": "防御达到极限的衣服，可作为锻造材料", 
		}, 
		"boots": {
			"id": "limit_boots", 
			"name": "极限鞋子", 
			"slot": "boots", 
			"rarity": "legendary", 
			"attack": 0, 
			"defense": 0, 
			"agility": ForgeConfig.LIMIT_VALUES.agility, 
			"hp": 0, 
			"mp": 0, 
			"is_limit": true, 
			"price": 10000000, 
			"description": "敏捷达到极限的鞋子，可作为锻造材料", 
		}, 
		"helmet": {
			"id": "limit_helmet", 
			"name": "极限血佩", 
			"slot": "helmet", 
			"rarity": "legendary", 
			"attack": 0, 
			"defense": 0, 
			"agility": 0, 
			"hp": ForgeConfig.LIMIT_VALUES.hp, 
			"mp": 0, 
			"is_limit": true, 
			"price": 10000000, 
			"description": "生命达到极限的头饰，可作为锻造材料", 
		}, 
		"accessory": {
			"id": "limit_accessory", 
			"name": "极限内带", 
			"slot": "accessory", 
			"rarity": "legendary", 
			"attack": 0, 
			"defense": 0, 
			"agility": 0, 
			"hp": 0, 
			"mp": ForgeConfig.LIMIT_VALUES.mp, 
			"is_limit": true, 
			"price": 10000000, 
			"description": "内力达到极限的身饰，可作为锻造材料", 
		}, 
	}

func get_limit_equipment(slot: String) -> Dictionary:
	return limit_equipments.get(slot, {})

func get_all_limit_equipments() -> Dictionary:
	return limit_equipments.duplicate()

func get_limit_equipment_price(slot: String) -> int:
	var equip = limit_equipments.get(slot, {})
	return equip.get("price", 0)

func is_limit_equipment(equipment: Dictionary) -> bool:
	return equipment.get("is_limit", false)

func create_limit_equipment_instance(slot: String) -> Dictionary:
	var template = get_limit_equipment(slot)
	if template.is_empty():
		return {}

	var instance = template.duplicate()
	instance["id"] = "limit_%s_%d" % [slot, Time.get_ticks_msec()]
	return instance


const LIMIT_FORGE_MATERIAL_META: Dictionary = {
	"极限武器": {"slot": "weapon", "attr": "attack"}, 
	"极限衣服": {"slot": "armor", "attr": "defense"}, 
	"极限鞋子": {"slot": "boots", "attr": "agility"}, 
	"极限血佩": {"slot": "helmet", "attr": "hp"}, 
	"极限内带": {"slot": "accessory", "attr": "mp"}, 
}

static func normalize_limit_material_name(n: String) -> String:
	if n == "极限血配":
		return "极限血佩"
	return n

static func is_limit_forge_material_name(n: String) -> bool:
	return LIMIT_FORGE_MATERIAL_META.has(normalize_limit_material_name(n))

static func limit_material_slot_attr(n: String) -> Dictionary:
	return LIMIT_FORGE_MATERIAL_META.get(normalize_limit_material_name(n), {})
