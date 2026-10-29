extends Node
class_name MonsterGenerator

const PetDatabase = preload("res://scripts/pet_data_complete.gd")
const MonsterGrowthData = preload("res://scripts/data/monster_growth_data.gd")


const BASE_STAT_MULTIPLIER = 1.5
const LEVEL_GROWTH_RATE = 0.15


static func generate_monster(pet_id: String, level: int, stat_multiplier: float = 1.0) -> Dictionary:
	print("[MonsterGenerator] 生成怪物: pet_id=", pet_id, ", level=", level)
	var pet_data = PetDatabase.PET_DATA.get(pet_id, {})
	if pet_data.is_empty():
		push_error("找不到宠物数据: " + pet_id)
		print("[MonsterGenerator] 错误: 找不到宠物数据 ", pet_id)
		return {}


	var growth_data = MonsterGrowthData.get_growth(pet_id)
	var growth = growth_data.get("growth", 3.8)
	var hp_growth = growth_data.get("hp_growth", 2.5)


	var base_attack = pet_data.get("attack", 5.0)
	var base_defense = pet_data.get("defense", 5.0)
	var base_agility = pet_data.get("agility", 5.0)
	var base_hp = pet_data.get("hp", 30.0)


	var level_multiplier = 1.0 + (level - 1) * LEVEL_GROWTH_RATE

	var final_attack = int(base_attack * BASE_STAT_MULTIPLIER * stat_multiplier * level_multiplier)
	var final_defense = int(base_defense * BASE_STAT_MULTIPLIER * stat_multiplier * level_multiplier)
	var final_agility = int(base_agility * BASE_STAT_MULTIPLIER * stat_multiplier * level_multiplier)
	var final_hp = int(base_hp * BASE_STAT_MULTIPLIER * stat_multiplier * level_multiplier)



	var exp_reward: int = level * 100
	var gold_reward: int = level * 50

	exp_reward = int(exp_reward * stat_multiplier)
	gold_reward = int(gold_reward * stat_multiplier)

	return {
		"name": pet_data.get("name", "未知怪物"), 
		"pet_id": pet_id, 
		"level": level, 
		"element": pet_data.get("element", "普通"), 
		"attack": final_attack, 
		"defense": final_defense, 
		"agility": final_agility, 
		"hp": final_hp, 
		"exp_reward": exp_reward, 
		"gold_reward": gold_reward, 
		"growth": growth, 
		"hp_growth": hp_growth
	}


static func get_monster_growth(pet_id: String) -> Dictionary:
	return MonsterGrowthData.get_growth(pet_id)
