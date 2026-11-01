extends RefCounted
class_name PetSkillBattle

const PetSkillConfig = preload("res://scripts/pet_skill_config.gd")

var _battle_state: Dictionary = {}

func reset_for_battle(pet: Pet = null) -> void :
	_battle_state.clear()
	if pet != null:
		_ensure_pet_state(pet)

func register_pet_for_battle(pet: Pet) -> void :
	if pet != null:
		_ensure_pet_state(pet)

func get_attack_skill_trigger(pet: Pet) -> Dictionary:
	var skill: = PetSkillConfig.get_best_skill_by_ids(pet, ["splash", "double_shot"])
	if skill.is_empty():
		return {}
	var config: Dictionary = skill.get("config", {})
	if not _roll(config.get("trigger_rate", 0.0)):
		return {}
	return {
		"skill_key": skill.get("skill_key", ""), 
		"skill_name": config.get("skill_name", ""), 
		"skill_id": config.get("skill_id", ""), 
		"config": config
	}

func try_trigger_divine_protect(pet: Pet) -> Dictionary:
	var state: = _ensure_pet_state(pet)
	var skill: = PetSkillConfig.get_skill_by_id(pet, "divine_protect")
	if skill.is_empty():
		return {}
	var config: Dictionary = skill.get("config", {})
	var max_use: int = maxi(1, int(config.get("max_use_per_battle", 5)))
	if int(state.get("divine_use_count", 0)) >= max_use:
		return {}
	if not _roll(config.get("trigger_rate", 0.0)):
		return {}
	state["divine_use_count"] = int(state.get("divine_use_count", 0)) + 1
	_battle_state[_get_pet_state_key(pet)] = state
	return {
		"skill_key": skill.get("skill_key", ""), 
		"skill_name": config.get("skill_name", ""), 
		"skill_id": "divine_protect", 
		"config": config
	}

func try_trigger_counter_attack(pet: Pet) -> Dictionary:
	var skill: = PetSkillConfig.get_skill_by_id(pet, "counter_attack")
	if skill.is_empty():
		return {}
	var config: Dictionary = skill.get("config", {})
	if not _roll(config.get("trigger_rate", 0.0)):
		return {}
	return {
		"skill_key": skill.get("skill_key", ""), 
		"skill_name": config.get("skill_name", ""), 
		"skill_id": "counter_attack", 
		"config": config
	}


func try_trigger_life_steal(pet: Pet, total_damage: int) -> Dictionary:
	if pet == null or total_damage <= 0:
		return {}
	var skill: = PetSkillConfig.get_skill_by_id(pet, "life_steal")
	if skill.is_empty():
		return {}
	var config: Dictionary = skill.get("config", {})
	if not _roll(config.get("trigger_rate", 0.0)):
		return {}
	var ratio: float = clampf(float(config.get("lifesteal_ratio", 0.0)), 0.0, 1.0)
	var heal_amount: int = maxi(1, int(floor(float(total_damage) * ratio)))
	return {
		"skill_key": skill.get("skill_key", ""), 
		"skill_name": config.get("skill_name", "吸血"), 
		"skill_id": "life_steal", 
		"config": config, 
		"heal_amount": heal_amount, 
		"lifesteal_ratio": ratio, 
	}

func try_trigger_chase(pet: Pet) -> Dictionary:
	var skill: = PetSkillConfig.get_skill_by_id(pet, "chase")
	if skill.is_empty():
		return {}
	var config: Dictionary = skill.get("config", {})
	if not _roll(config.get("chase_trigger_rate", 0.0)):
		return {}
	return {
		"skill_key": skill.get("skill_key", ""), 
		"skill_name": config.get("skill_name", "追击"), 
		"skill_id": "chase", 
		"config": config, 
		"chase_ratio": float(config.get("chase_ratio", 1.0)), 
	}

func try_trigger_taunt(pet: Pet) -> Dictionary:
	var skill: = PetSkillConfig.get_skill_by_id(pet, "taunt")
	if skill.is_empty():
		return {}
	var config: Dictionary = skill.get("config", {})
	if not _roll(config.get("trigger_rate", 0.0)):
		return {}
	return {
		"skill_key": skill.get("skill_key", ""), 
		"skill_name": config.get("skill_name", "嘲讽"), 
		"skill_id": "taunt", 
		"config": config, 
	}

func try_trigger_loyal(pet: Pet) -> Dictionary:
	var skill: = PetSkillConfig.get_skill_by_id(pet, "loyal")
	if skill.is_empty():
		return {}
	var config: Dictionary = skill.get("config", {})
	if not _roll(config.get("block_chance", 0.0)):
		return {}
	return {
		"skill_key": skill.get("skill_key", ""), 
		"skill_name": config.get("skill_name", "忠心"), 
		"skill_id": "loyal", 
		"config": config, 
	}

func try_trigger_armor_pierce(pet: Pet, extra_rate: float = 0.0) -> Dictionary:
	var skill: = PetSkillConfig.get_skill_by_id(pet, "armor_pierce")
	var config: Dictionary = {}
	var skill_rate: = 0.0
	if not skill.is_empty():
		config = skill.get("config", {})
		skill_rate = float(config.get("trigger_rate", 0.0))
	var rate: = clampf(skill_rate + extra_rate, 0.0, 1.0)
	if rate <= 0.0 or not _roll(rate):
		return {}
	return {
		"skill_key": skill.get("skill_key", ""), 
		"skill_name": config.get("skill_name", "破甲"), 
		"skill_id": "armor_pierce", 
		"config": config, 
	}

func try_trigger_guard(pet: Pet) -> Dictionary:
	var skill: = PetSkillConfig.get_skill_by_id(pet, "guard")
	if skill.is_empty():
		return {}
	var config: Dictionary = skill.get("config", {})
	if not _roll(config.get("trigger_rate", 0.0)):
		return {}
	var reduction: float = clampf(float(config.get("damage_reduction_ratio", 0.5)), 0.0, 1.0)
	return {
		"skill_key": skill.get("skill_key", ""), 
		"skill_name": config.get("skill_name", "格挡"), 
		"skill_id": "guard", 
		"config": config, 
		"damage_reduction_ratio": reduction, 
	}

func try_trigger_self_heal(pet: Pet) -> Dictionary:
	if pet == null or not pet.is_alive():
		return {}
	var skill: = PetSkillConfig.get_skill_by_id(pet, "self_heal")
	if skill.is_empty():
		return {}
	var config: Dictionary = skill.get("config", {})
	var ratio: float = clampf(float(config.get("heal_ratio", 0.0)), 0.0, 1.0)
	if ratio <= 0.0:
		return {}
	var max_hp: = float(pet.get_final_max_hp_with_equipment()) if pet.has_method("get_final_max_hp_with_equipment") else float(pet.max_hp)
	var heal_amount: int = maxi(1, int(floor(max_hp * ratio)))
	return {
		"skill_key": skill.get("skill_key", ""), 
		"skill_name": config.get("skill_name", "自愈"), 
		"skill_id": "self_heal", 
		"config": config, 
		"heal_amount": heal_amount, 
	}

func get_crit_rate_bonus(pet: Pet) -> float:
	var skill: = PetSkillConfig.get_skill_by_id(pet, "fatal")
	if skill.is_empty():
		return 0.0
	var config: Dictionary = skill.get("config", {})
	return float(config.get("crit_rate_bonus_percent", 0.0)) / 100.0

func get_crit_damage_bonus(pet: Pet) -> float:
	var skill: = PetSkillConfig.get_skill_by_id(pet, "fierce")
	if skill.is_empty():
		return 0.0
	var config: Dictionary = skill.get("config", {})
	return float(config.get("crit_damage_bonus_percent", 0.0)) / 100.0

func _roll(chance: float) -> bool:
	var rate: float = clampf(float(chance), 0.0, 1.0)
	if rate <= 0.0:
		return false
	if rate >= 1.0:
		return true
	return randf() <= rate

func _get_pet_state_key(pet: Pet) -> String:
	if pet == null:
		return ""
	if str(pet.pet_id).strip_edges() != "":
		return str(pet.pet_id)
	return str(pet.get_instance_id())

func _ensure_pet_state(pet: Pet) -> Dictionary:
	var key: = _get_pet_state_key(pet)
	if not _battle_state.has(key):
		_battle_state[key] = {
			"divine_use_count": 0
		}
	return _battle_state[key]
