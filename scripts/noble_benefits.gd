extends RefCounted
class_name NobleBenefits




const NOBLE_START_TIME: = "2026-04-17 11:51:16"


const THRESHOLDS: Array[int] = [
	1000, 2000, 5000, 8000, 11000, 15000, 20000, 
	26000, 43000, 51000, 60000, 70000, 81000, 93000, 106000
]


const RANK_NAMES: Array[String] = [
	"平民", 
	"一等贵族", "二等贵族", "三等贵族", "四等贵族", "五等贵族", "六等贵族", 
	"七等贵族", "八等贵族", "九等贵族", "亲王", 
	"郡王", "亲公", "国公", "皇帝"
]


const MERGE_BONUS: Array[int] = [0, 2, 4, 6, 8, 9, 10, 16, 23, 30, 37, 43, 50, 57, 63, 70]


const MARTIAL_BONUS: Array[int] = [0, 3, 7, 10, 13, 17, 20, 23, 27, 30, 33, 37, 40, 43, 47, 50]


const PET_DAMAGE: Array[int] = [0, 0, 0, 0, 0, 0, 3, 5, 7, 10, 13, 16, 19, 22, 25, 30]

const EXP_BONUS: Array[int] = PET_DAMAGE


const EXTREME_EQUIP: Array[int] = [0, 0, 0, 0, 1, 2, 3, 4, 5, 5, 5, 5, 5, 5, 5, 5]


enum ClaimType{
	EXTREME_EQUIP = 0, 
	SPECIAL_PET_10 = 1, 
	SPECIAL_PET_15 = 2
}

const CLAIM_TYPE_NAMES: Dictionary = {
	ClaimType.EXTREME_EQUIP: "extreme_equip", 
	ClaimType.SPECIAL_PET_10: "special_pet_10", 
	ClaimType.SPECIAL_PET_15: "special_pet_15"
}


static func compute_level(consumed: int) -> int:
	var lv: = 0
	for t in THRESHOLDS:
		if consumed >= t:
			lv += 1
		else:
			break
	return clampi(lv, 0, 15)


static func get_next_threshold(level: int) -> int:
	if level <= 0 or level > THRESHOLDS.size():
		return -1
	return THRESHOLDS[level - 1]


static func get_current_threshold(level: int) -> int:
	if level <= 1:
		return 0
	if level > THRESHOLDS.size():
		return THRESHOLDS[-1]
	return THRESHOLDS[level - 2]


static func get_rank_name(level: int) -> String:
	var idx: = clampi(level, 0, RANK_NAMES.size() - 1)
	return RANK_NAMES[idx]


static func get_brother_tower_clear_bonus(level: int) -> int:
	var lv: = clampi(level, 0, 15)
	var per_level: = 1
	if GameManager.instance and GameManager.instance.has_method("get_brother_tower_runtime_config"):
		var cfg: Dictionary = GameManager.instance.get_brother_tower_runtime_config()
		per_level = maxi(0, int(cfg.get("nobleClearBonusPerLevel", 1)))
	return lv * per_level


static func get_benefits(level: int) -> Dictionary:
	var lv: = clampi(level, 0, 15)
	return {
		"mergeBonus": MERGE_BONUS[lv], 
		"martialBonus": MARTIAL_BONUS[lv], 
		"petDamage": PET_DAMAGE[lv], 
		"expBonus": EXP_BONUS[lv], 
		"extremeEquip": EXTREME_EQUIP[lv], 
		"brotherTowerClearBonus": get_brother_tower_clear_bonus(lv), 
		"canClaimExtremeEquip": lv >= 4, 
		"canClaimSpecialPet10": lv >= 10, 
		"canClaimSpecialPet15": lv >= 15, 
		"hasCollectionUnlock": lv >= 11
	}


static func format_progress(consumed: int, next_threshold: int) -> String:
	if next_threshold <= 0:
		return "%d/已满级" % consumed
	return "%d/%d" % [consumed, next_threshold]


static func get_progress_percent(consumed: int, current_level: int) -> float:
	var next_thresh: = get_next_threshold(current_level + 1)
	if next_thresh <= 0:
		return 100.0
	var current_thresh: = get_current_threshold(current_level)
	if current_thresh >= next_thresh:
		return 100.0
	var range_val: = next_thresh - current_thresh
	if range_val <= 0:
		return 100.0
	var progress: = float(consumed - current_thresh) / float(range_val) * 100.0
	return clampf(progress, 0.0, 100.0)


static func get_benefit_list(level: int) -> Array[Dictionary]:
	var benefits: = get_benefits(level)
	var items: Array[Dictionary] = []

	if benefits["mergeBonus"] > 0:
		items.append({
			"icon": "✨", 
			"text": "幻化完美概率 +%d%%" % benefits["mergeBonus"], 
			"type": "merge"
		})

	if benefits["martialBonus"] > 0:
		items.append({
			"icon": "⚔️", 
			"text": "自创武功成功率 +%d%%" % benefits["martialBonus"], 
			"type": "martial"
		})

	if benefits.get("brotherTowerClearBonus", 0) > 0:
		items.append({
			"icon": "🏰", 
			"text": "兄弟天关每日通关 +%d 次" % int(benefits["brotherTowerClearBonus"]), 
			"type": "brother_tower"
		})

	if level >= 3:
		items.append({
			"icon": "🤝", 
			"text": "解锁助战槽1（无需投胎 100 次）", 
			"type": "assist_slot1"
		})
	if level >= 5:
		items.append({
			"icon": "🗺️", 
			"text": "可进困难地图（无需投胎 100 次）", 
			"type": "map_hard"
		})
	if level >= 6:
		items.append({
			"icon": "🤝", 
			"text": "解锁助战槽2（无需投胎 200 次）", 
			"type": "assist_slot2"
		})
	if level >= 9:
		items.append({
			"icon": "🤝", 
			"text": "解锁助战槽3（无需投胎 300 次）", 
			"type": "assist_slot3"
		})
	if level >= 10:
		items.append({
			"icon": "🗺️", 
			"text": "可进地狱地图（无需投胎 200 次）", 
			"type": "map_hell"
		})
	if level >= 12:
		items.append({
			"icon": "🤝", 
			"text": "解锁助战槽4（无需投胎 400 次）", 
			"type": "assist_slot4"
		})
	if level >= 15:
		items.append({
			"icon": "🤝", 
			"text": "解锁助战槽5（无需投胎 500 次）", 
			"type": "assist_slot5"
		})
		items.append({
			"icon": "🗺️", 
			"text": "可进史诗地图（无需投胎 300 次）", 
			"type": "map_epic"
		})

	if benefits["petDamage"] > 0:
		items.append({
			"icon": "🐾", 
			"text": "出战宠物攻防敏 +%d%%" % benefits["petDamage"], 
			"type": "damage"
		})

	if int(benefits.get("expBonus", 0)) > 0:
		items.append({
			"icon": "📘", 
			"text": "经验加成 +%d%%" % int(benefits["expBonus"]), 
			"type": "exp"
		})

	if benefits["extremeEquip"] > 0:
		items.append({
			"icon": "🎁", 
			"text": "极限装备锦囊 x%d" % benefits["extremeEquip"], 
			"type": "equip"
		})

	if benefits["hasCollectionUnlock"]:
		items.append({
			"icon": "📖", 
			"text": "全宠物图鉴激活（联系群主）", 
			"type": "collection", 
			"special": true
		})

	if level >= 10 and level < 15:
		items.append({
			"icon": "🎉", 
			"text": "特殊宠物：9.9哪吒（变异1，溅射lv1）", 
			"type": "pet10"
		})

	if level >= 15:
		items.append({
			"icon": "👑", 
			"text": "联系群主私人定制13.9变异2图档宠(自带宠物技能溅射Iv2)", 
			"type": "pet15", 
			"special": true
		})

	return items


static func can_claim(claims_data: Dictionary, claim_type: ClaimType) -> bool:
	var type_str: String = CLAIM_TYPE_NAMES.get(claim_type, "")
	if type_str.is_empty():
		return false

	if claims_data.has(type_str):
		return false

	match claim_type:
		ClaimType.EXTREME_EQUIP:
			var level: int = int(claims_data.get("nobleLevel", 0))
			return level >= 4
		ClaimType.SPECIAL_PET_10:
			var level: int = int(claims_data.get("nobleLevel", 0))
			return level >= 10
		ClaimType.SPECIAL_PET_15:
			var level: int = int(claims_data.get("nobleLevel", 0))
			return level >= 15
		_:
			return false


static func get_level_color(level: int) -> Color:
	if level >= 15:
		return Color(1.0, 0.5, 0.0)
	elif level >= 10:
		return Color(1.0, 0.84, 0.0)
	elif level >= 7:
		return Color(0.3, 0.9, 0.3)
	elif level >= 4:
		return Color(0.4, 0.7, 1.0)
	elif level >= 1:
		return Color(0.7, 0.7, 0.7)
	else:
		return Color(0.5, 0.5, 0.5)


static func validate_server_data(data: Dictionary) -> bool:
	var required_keys: = ["nobleLevel", "nobleName", "totalConsumed", "benefits"]
	for key in required_keys:
		if not data.has(key):
			push_warning("[NobleBenefits] Missing key in server data: %s" % key)
			return false

	var benefits = data.get("benefits", {})
	var benefit_keys: = ["mergeBonus", "martialBonus", "petDamage", "extremeEquip"]
	for key in benefit_keys:
		if not benefits.has(key):
			push_warning("[NobleBenefits] Missing benefit key: %s" % key)
			return false

	return true
