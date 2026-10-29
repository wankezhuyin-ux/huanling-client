class_name PetEquipmentData

const GameData = preload("res://scripts/game_data.gd")

const SLOTS = {
	"pet_weapon": {"name": "武器", "stat": "attack", "icon": "weapon"}, 
	"pet_armor": {"name": "防具", "stat": "defense", "icon": "armor"}, 
	"pet_boots": {"name": "鞋子", "stat": "agility", "icon": "boots"}, 
	"pet_helmet": {"name": "头盔", "stat": "hp", "icon": "helmet"}, 
	"pet_accessory": {"name": "饰品", "stat": "hp", "icon": "accessory"}
}

const SLOT_MAPPING = {
	"weapon": "pet_weapon", 
	"armor": "pet_armor", 
	"boots": "pet_boots", 
	"helmet": "pet_helmet", 
	"accessory": "pet_accessory"
}

const STAT_NAMES = {
	"attack": "攻击", 
	"defense": "防御", 
	"agility": "敏捷", 
	"hp": "生命"
}

static func get_slot_name(slot: String) -> String:
	if SLOTS.has(slot):
		return SLOTS[slot].name
	return "未知"

static func get_slot_stat(slot: String) -> String:
	if SLOTS.has(slot):
		return SLOTS[slot].stat
	return ""

static func get_stat_name(stat: String) -> String:
	return STAT_NAMES.get(stat, stat)

static func get_pet_slot_from_equipment_slot(equipment_slot: String) -> String:
	return SLOT_MAPPING.get(equipment_slot, "")

static func get_equipment_slot_from_pet_slot(pet_slot: String) -> String:
	for equip_slot in SLOT_MAPPING.keys():
		if SLOT_MAPPING[equip_slot] == pet_slot:
			return equip_slot
	return ""

static func get_slot_icon(slot: String) -> String:
	if SLOTS.has(slot):
		return SLOTS[slot].icon
	return ""

static func get_all_slots() -> Array:
	return SLOTS.keys()
