extends RefCounted
class_name PetEquipmentEnhance


const PET_LOOT_SOURCE_BSG: = "bsg_chest"

const FRAGMENT_ITEM: = "宠装碎片"
const STONE_ITEM: = "宠装强化石"
const MAX_LEVEL: = 9
const FRAGMENTS_PER_STONE: = 10

const ENHANCE_BONUS_BY_LEVEL: = [
	0.0, 
	0.04, 
	0.09, 
	0.15, 
	0.23, 
	0.33, 
	0.46, 
	0.62, 
	0.8, 
	1.0, 
]

const PetEquipmentChestLootNames = preload("res://scripts/pet_equipment/pet_equipment_chest_loot_names.gd")


static func chest_open_channel_to_pet_tier(open_key: String) -> String:
	match str(open_key).strip_edges().to_lower():
		"bronze_chest", "bronze":
			return "bronze"
		"silver_chest", "silver":
			return "silver"
		"gold_chest", "gold":
			return "gold"
		_:
			return ""

static func stone_cost_for_next_level(current_level: int) -> int:
	if current_level < 0 or current_level >= MAX_LEVEL:
		return 0
	return current_level + 1

static func success_rate_for_next_level(current_level: int) -> float:
	if current_level < 0 or current_level >= MAX_LEVEL:
		return 0.0
	var target: = current_level + 1

	var t: = float(target - 1) / float(MAX_LEVEL - 1)
	return lerpf(1.0, 0.3, t)

static func stat_multiplier(level: int) -> float:
	var lv: int = clampi(level, 0, MAX_LEVEL)
	return 1.0 + float(ENHANCE_BONUS_BY_LEVEL[lv])

static func effective_stat(base: int, level: int) -> int:
	if base <= 0:
		return 0
	return int(round(float(base) * stat_multiplier(level)))

static func resolve_quality_tier(eq) -> String:
	var raws: Array = []
	if eq is Dictionary:
		raws = [eq.get("pet_chest_tier", ""), eq.get("quality", ""), eq.get("rarity", "")]
	elif eq != null:
		if "pet_chest_tier" in eq:
			raws.append(eq.pet_chest_tier)
		if "quality" in eq:
			raws.append(eq.quality)
		if "rarity" in eq:
			raws.append(eq.rarity)
	for raw in raws:
		var s: = str(raw).strip_edges().to_lower()
		match s:
			"bronze", "青铜":
				return "bronze"
			"silver", "白银":
				return "silver"
			"gold", "黄金":
				return "gold"
	return ""

static func roll_cap_for_quality(tier: String) -> int:
	var base: = int(PetEquipment.BASE_STATS.get(tier, 0))
	if base <= 0:
		return 0
	return int(floor(float(base) * 1.2))

static func format_stat_with_cap(label: String, current: int, cap: int = 0) -> String:
	if current <= 0:
		return ""
	if cap > 0:
		return "%s+%d（上限%d）" % [label, current, maxi(cap, current)]
	return "%s+%d" % [label, current]

static func format_effective_stats_line(eq) -> String:
	var lv: = get_level_from_equipment(eq)
	var atk: = 0
	var def: = 0
	var agi: = 0
	var hp: = 0
	if eq is Dictionary:
		atk = int(eq.get("attack", 0))
		def = int(eq.get("defense", 0))
		agi = int(eq.get("agility", 0))
		hp = int(eq.get("hp", 0))
	elif eq != null:
		atk = int(eq.attack) if "attack" in eq else 0
		def = int(eq.defense) if "defense" in eq else 0
		agi = int(eq.agility) if "agility" in eq else 0
		hp = int(eq.hp) if "hp" in eq else 0
	var cap: = 0
	if lv <= 0:
		cap = roll_cap_for_quality(resolve_quality_tier(eq))
	var parts: Array[String] = []
	var atk_s: = format_stat_with_cap("攻击", effective_stat(atk, lv), cap if atk > 0 else 0)
	var def_s: = format_stat_with_cap("防御", effective_stat(def, lv), cap if def > 0 else 0)
	var agi_s: = format_stat_with_cap("敏捷", effective_stat(agi, lv), cap if agi > 0 else 0)
	var hp_s: = format_stat_with_cap("生命", effective_stat(hp, lv), cap if hp > 0 else 0)
	if not atk_s.is_empty():
		parts.append(atk_s)
	if not def_s.is_empty():
		parts.append(def_s)
	if not agi_s.is_empty():
		parts.append(agi_s)
	if not hp_s.is_empty():
		parts.append(hp_s)
	return " ".join(parts)

static func format_display_name(base_name: String, level: int) -> String:
	var lv: int = clampi(level, 0, MAX_LEVEL)
	var n: = str(base_name).strip_edges()
	if lv <= 0:
		return n
	return "%s+%d" % [n, lv]

static func get_level_from_dict(d: Dictionary) -> int:
	return clampi(int(d.get("pet_enhance_level", 0)), 0, MAX_LEVEL)

static func get_level_from_equipment(eq) -> int:
	if eq == null:
		return 0
	if eq is Dictionary:
		return get_level_from_dict(eq)
	return clampi(int(eq.pet_enhance_level), 0, MAX_LEVEL)


static func dismantle_fragment_count(d: Dictionary) -> int:
	var tier: = str(d.get("pet_chest_tier", "")).strip_edges().to_lower()
	match tier:
		"bronze":
			return 1
		"silver":
			return 2
		"gold":
			return 3
	var base: = PetEquipmentChestLootNames.normalize_base_name(str(d.get("name", d.get("equip_name", ""))))
	var by_name: = PetEquipmentChestLootNames.fragment_count_by_base_name(base)
	if by_name >= 1:
		return by_name
	var q: = str(d.get("quality", d.get("chest_type", ""))).strip_edges().to_lower()
	match q:
		"silver":
			return 2
		"gold":
			return 3
		"bronze":
			return 1
	var r: = str(d.get("rarity", "")).strip_edges().to_lower()
	match r:
		"common":
			return 1
		"rare":
			return 2
		"epic":
			return 3
		_:
			return 1

static func can_dismantle(equipment_variant) -> bool:
	var d: Dictionary = {}
	if equipment_variant is Dictionary:
		d = equipment_variant
	elif equipment_variant != null and equipment_variant.has_method("to_dict"):
		d = equipment_variant.to_dict()
	else:
		return false
	if not bool(d.get("is_pet_equipment", false)):
		return false
	if str(d.get("pet_loot_source", "")) == PET_LOOT_SOURCE_BSG:
		return true
	var tier: = str(d.get("pet_chest_tier", "")).strip_edges().to_lower()
	if tier == "bronze" or tier == "silver" or tier == "gold":
		return true
	var base: = PetEquipmentChestLootNames.normalize_base_name(str(d.get("name", d.get("equip_name", ""))))
	if PetEquipmentChestLootNames.fragment_count_by_base_name(base) >= 1:
		return true
	var q: = str(d.get("quality", d.get("chest_type", ""))).strip_edges().to_lower()
	if q == "bronze" or q == "silver" or q == "gold":
		return true
	var r: = str(d.get("rarity", "")).strip_edges().to_lower()
	return r == "common" or r == "rare" or r == "epic"
