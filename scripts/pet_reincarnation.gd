extends RefCounted
class_name PetReincarnation

const GameData = preload("res://scripts/game_data.gd")

const MAX_REINCARNATION: = 50
const BRACKET_SIZE: = 10
const INHERIT_YUANBAO_COST: = 1000
const NON_EVO_BASE_MAX: = 1500
const EVO_BASE_MAX: = 1200
const NON_EVO_BONUS_PER_BRACKET: = 100
const EVO_BONUS_PER_BRACKET: = 50

const TOKEN_ELEMENTS: = ["金", "木", "水", "火", "土"]

static func is_sky_element(pet) -> bool:
	if pet == null:
		return false
	return str(pet.element) == GameData.ELEMENT_SKY

static func elements_compatible_for_inherit(source, target) -> bool:
	if source == null or target == null:
		return false
	var src_el: = str(source.element)
	var tgt_el: = str(target.element)
	if src_el == tgt_el:
		return true
	if src_el == GameData.ELEMENT_SKY or tgt_el == GameData.ELEMENT_SKY:
		return true
	return false

static func can_reincarnate(pet, pet_manager) -> Dictionary:
	var reason: = ""
	if pet.reincarnation_count >= MAX_REINCARNATION:
		return {"ok": false, "reason": "该宠物已达最大转生次数（50次）"}
	if pet.generation < 3:
		return {"ok": false, "reason": "需要三代及以上宠物才能转生"}
	if not pet.is_at_max_level():
		return {"ok": false, "reason": "宠物未达到满级（%d级），无法转生" % pet.get_effective_max_level()}
	if pet.is_evolution_pet:
		if pet.form != "终极":
			return {"ok": false, "reason": "可进化宠物需要终极形态才能转生"}
		if pet.total_growth < 80.0:
			return {"ok": false, "reason": "可进化宠物成长率需要达到80以上才能转生"}
	else:
		if pet.total_growth < 60.0:
			return {"ok": false, "reason": "不可进化宠物成长率需要达到60以上才能转生"}
	if pet_manager and not pet_manager.is_pet_normal_state(pet):
		return {"ok": false, "reason": "出战、锁定或宠物袋中的宠物无法转生"}
	return {"ok": true, "reason": ""}

static func get_token_name(pet) -> String:
	if pet == null:
		return "宠物转生令牌"

	if is_sky_element(pet):
		return ""
	return str(pet.element) + "宠物转生令牌"

static func get_token_name_for_element(element: String) -> String:
	return str(element) + "宠物转生令牌"

static func get_cost(reincarnation_count: int) -> Dictionary:
	var bracket: = reincarnation_count / BRACKET_SIZE
	return {
		"tokens": bracket + 1, 
		"gold": (bracket + 1) * 1000000000, 
		"bracket": bracket
	}

static func can_inherit(source, target, pet_manager) -> Dictionary:
	if pet_manager:
		if not pet_manager.is_pet_normal_state(source):
			return {"ok": false, "reason": "源宠物非正常状态（出战/锁定/宠物袋中）"}
		if not pet_manager.is_pet_normal_state(target):
			return {"ok": false, "reason": "目标宠物非正常状态（出战/锁定/宠物袋中）"}
	if source.reincarnation_count < 2 or source.reincarnation_count % 2 != 0:
		return {"ok": false, "reason": "源宠物转生次数需为偶数且至少2次"}
	if target.reincarnation_count != 0:
		return {"ok": false, "reason": "目标宠物转生次数必须为0"}
	var target_check: = can_reincarnate(target, pet_manager)
	if not target_check.ok:
		return {"ok": false, "reason": "目标宠物不满足转生条件：" + target_check.reason}
	if not elements_compatible_for_inherit(source, target):
		return {"ok": false, "reason": "两只宠物五行属性不一致"}
	if source.is_evolution_pet != target.is_evolution_pet:
		return {"ok": false, "reason": "两只宠物进化类型不一致"}
	return {"ok": true, "reason": ""}

static func get_inherited_count(source_count: int) -> int:
	return source_count / 2

static func calc_effective_max_level(base_max: int, is_evo: bool, rei_count: int) -> int:
	var bonus_per_bracket: = EVO_BONUS_PER_BRACKET if is_evo else NON_EVO_BONUS_PER_BRACKET
	return base_max + (rei_count / 10) * bonus_per_bracket
