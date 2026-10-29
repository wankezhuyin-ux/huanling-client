class_name PetEquipment

enum EquipSlot{WEAPON, ARMOR, ACCESSORY, BOOTS, HELMET}

var equip_id: String = ""
var equip_name: String = ""
var slot: int = EquipSlot.WEAPON
var quality: String = "bronze"
var attack: int = 0
var defense: int = 0
var agility: int = 0
var hp: int = 0
var equipped_pet_id: String = ""

const SLOT_NAMES = {
	EquipSlot.WEAPON: "武器", 
	EquipSlot.ARMOR: "防具", 
	EquipSlot.ACCESSORY: "饰品", 
	EquipSlot.BOOTS: "靴子", 
	EquipSlot.HELMET: "头盔"
}

const QUALITY_NAMES = {
	"bronze": "青铜", 
	"silver": "白银", 
	"gold": "黄金"
}

const BASE_STATS = {
	"bronze": 300, 
	"silver": 500, 
	"gold": 1000
}

const EQUIPMENT_TEMPLATES = {
	"bronze": {
		EquipSlot.WEAPON: {"name": "青铜爪", "stat": "attack"}, 
		EquipSlot.ARMOR: {"name": "青铜甲", "stat": "defense"}, 
		EquipSlot.ACCESSORY: {"name": "青铜坠", "stat": "hp"}, 
		EquipSlot.BOOTS: {"name": "青铜靴", "stat": "agility"}, 
		EquipSlot.HELMET: {"name": "青铜盔", "stat": "hp"}
	}, 
	"silver": {
		EquipSlot.WEAPON: {"name": "银月爪", "stat": "attack"}, 
		EquipSlot.ARMOR: {"name": "银月甲", "stat": "defense"}, 
		EquipSlot.ACCESSORY: {"name": "银月坠", "stat": "hp"}, 
		EquipSlot.BOOTS: {"name": "银月靴", "stat": "agility"}, 
		EquipSlot.HELMET: {"name": "银月盔", "stat": "hp"}
	}, 
	"gold": {
		EquipSlot.WEAPON: {"name": "金鳞爪", "stat": "attack"}, 
		EquipSlot.ARMOR: {"name": "金鳞甲", "stat": "defense"}, 
		EquipSlot.ACCESSORY: {"name": "金鳞坠", "stat": "hp"}, 
		EquipSlot.BOOTS: {"name": "金鳞靴", "stat": "agility"}, 
		EquipSlot.HELMET: {"name": "金鳞盔", "stat": "hp"}
	}
}

func _init():
	pass

func to_dict() -> Dictionary:
	return {
		"equip_id": equip_id, 
		"equip_name": equip_name, 
		"slot": slot, 
		"quality": quality, 
		"attack": attack, 
		"defense": defense, 
		"agility": agility, 
		"hp": hp, 
		"equipped_pet_id": equipped_pet_id
	}

func from_dict(data: Dictionary):
	equip_id = data.get("equip_id", "")
	equip_name = data.get("equip_name", "")
	slot = data.get("slot", EquipSlot.WEAPON)
	quality = data.get("quality", "bronze")
	attack = data.get("attack", 0)
	defense = data.get("defense", 0)
	agility = data.get("agility", 0)
	hp = data.get("hp", 0)
	equipped_pet_id = data.get("equipped_pet_id", "")

func get_slot_name() -> String:
	return SLOT_NAMES.get(slot, "未知")

func get_quality_name() -> String:
	return QUALITY_NAMES.get(quality, "未知")

func get_full_name() -> String:
	return get_quality_name() + equip_name

func is_equipped() -> bool:
	return not equipped_pet_id.is_empty()



static func equip_slot_string_to_equip_slot_enum(equip_slot_str: String) -> int:
	match str(equip_slot_str).strip_edges().to_lower():
		"weapon":
			return EquipSlot.WEAPON
		"armor":
			return EquipSlot.ARMOR
		"accessory":
			return EquipSlot.ACCESSORY
		"boots":
			return EquipSlot.BOOTS
		"helmet":
			return EquipSlot.HELMET
		_:
			return EquipSlot.WEAPON



static func get_template_base_name(quality: String, equip_slot_str: String) -> String:
	var q: = str(quality).strip_edges().to_lower()
	var tmpl: Variant = EQUIPMENT_TEMPLATES.get(q)
	if not tmpl is Dictionary:
		return ""
	var idx: = equip_slot_string_to_equip_slot_enum(equip_slot_str)
	var piece: Variant = tmpl.get(idx)
	if piece is Dictionary:
		return str(piece.get("name", "")).strip_edges()
	return ""


static func create_random_equipment(quality: String) -> PetEquipment:
	var equip = PetEquipment.new()
	equip.quality = quality
	equip.slot = randi() % 5

	var template = EQUIPMENT_TEMPLATES.get(quality, EQUIPMENT_TEMPLATES.bronze)
	var slot_template = template.get(equip.slot, template[EquipSlot.WEAPON])

	equip.equip_name = slot_template.name
	var base_stat = BASE_STATS.get(quality, 300)
	var actual_stat = int(base_stat * (0.8 + randf() * 0.4))

	match slot_template.stat:
		"attack": equip.attack = actual_stat
		"defense": equip.defense = actual_stat
		"agility": equip.agility = actual_stat
		"hp": equip.hp = actual_stat

	equip.equip_id = "%s_%s_%d" % [quality, slot_template.name, Time.get_ticks_msec()]

	return equip

static func create_equipment(quality: String, slot: int) -> PetEquipment:
	var equip = PetEquipment.new()
	equip.quality = quality
	equip.slot = slot

	var template = EQUIPMENT_TEMPLATES.get(quality, EQUIPMENT_TEMPLATES.bronze)
	var slot_template = template.get(slot, template[EquipSlot.WEAPON])

	equip.equip_name = slot_template.name
	var base_stat = BASE_STATS.get(quality, 300)
	var actual_stat = int(base_stat * (0.8 + randf() * 0.4))

	match slot_template.stat:
		"attack": equip.attack = actual_stat
		"defense": equip.defense = actual_stat
		"agility": equip.agility = actual_stat
		"hp": equip.hp = actual_stat

	equip.equip_id = "%s_%s_%d" % [quality, slot_template.name, Time.get_ticks_msec()]

	return equip

func get_stat_description() -> String:
	var stats = []
	if attack > 0:
		stats.append("攻击+%d" % attack)
	if defense > 0:
		stats.append("防御+%d" % defense)
	if agility > 0:
		stats.append("敏捷+%d" % agility)
	if hp > 0:
		stats.append("生命+%d" % hp)
	return "  ".join(stats)
