extends RefCounted
class_name PetSkillConfig

const SKILL_DEFINITIONS: = {
	"splash_lv1": {
		"skill_id": "splash", 
		"skill_name": "溅墨", 
		"trigger_rate": 0.5, 
		"target_count": 2, 
		"damage_ratio": 0.8, 
		"priority": 100
	}, 
	"splash_lv2": {
		"skill_id": "splash", 
		"skill_name": "溅墨", 
		"trigger_rate": 1.0, 
		"target_count": 2, 
		"damage_ratio": 1.0, 
		"priority": 100
	}, 
	"splash_lv3": {
		"skill_id": "splash", 
		"skill_name": "溅墨", 
		"trigger_rate": 1.0, 

		"target_count": 3, 
		"damage_ratio": 1.0, 
		"priority": 100
	}, 
	"double_shot_lv1": {
		"skill_id": "double_shot", 
		"skill_name": "连笔", 
		"trigger_rate": 0.2, 
		"hit_count": 3, 
		"damage_ratio_per_hit": 0.6, 
		"priority": 10
	}, 
	"double_shot_lv2": {
		"skill_id": "double_shot", 
		"skill_name": "连笔", 
		"trigger_rate": 0.3, 
		"hit_count": 3, 
		"damage_ratio_per_hit": 0.8, 
		"priority": 10
	}, 
	"double_shot_lv3": {
		"skill_id": "double_shot", 
		"skill_name": "连笔", 
		"trigger_rate": 0.5, 
		"hit_count": 3, 
		"damage_ratio_per_hit": 1.0, 
		"priority": 10
	}, 
	"divine_protect_lv1": {
		"skill_id": "divine_protect", 
		"skill_name": "护墨", 
		"trigger_rate": 0.2, 
		"hp_restore_ratio": 0.5, 
		"max_use_per_battle": 5
	}, 
	"divine_protect_lv2": {
		"skill_id": "divine_protect", 
		"skill_name": "护墨", 
		"trigger_rate": 0.3, 
		"hp_restore_ratio": 0.5, 
		"max_use_per_battle": 5
	}, 
	"divine_protect_lv3": {
		"skill_id": "divine_protect", 
		"skill_name": "护墨", 
		"trigger_rate": 0.5, 
		"hp_restore_ratio": 1.0, 
		"max_use_per_battle": 5
	}, 
	"counter_attack_lv1": {
		"skill_id": "counter_attack", 
		"skill_name": "逆锋", 
		"trigger_rate": 0.2, 
		"damage_ratio": 0.5
	}, 
	"counter_attack_lv2": {
		"skill_id": "counter_attack", 
		"skill_name": "逆锋", 
		"trigger_rate": 0.3, 
		"damage_ratio": 0.8
	}, 
	"counter_attack_lv3": {
		"skill_id": "counter_attack", 
		"skill_name": "逆锋", 
		"trigger_rate": 0.5, 
		"damage_ratio": 1.0
	}, 

	"fortify_lv1": {
		"skill_id": "fortify", 
		"skill_name": "固色", 
		"level": 1, 
		"defense_bonus_percent": 70
	}, 
	"fortify_lv2": {
		"skill_id": "fortify", 
		"skill_name": "固色", 
		"level": 2, 
		"defense_bonus_percent": 140
	}, 
	"fortify_lv3": {
		"skill_id": "fortify", 
		"skill_name": "固色", 
		"level": 3, 
		"defense_bonus_percent": 210
	}, 

	"life_steal_lv1": {
		"skill_id": "life_steal", 
		"skill_name": "吮墨", 
		"trigger_rate": 0.1, 
		"lifesteal_ratio": 0.1, 
		"priority": 5
	}, 
	"life_steal_lv2": {
		"skill_id": "life_steal", 
		"skill_name": "吮墨", 
		"trigger_rate": 0.2, 
		"lifesteal_ratio": 0.15, 
		"priority": 5
	}, 
	"life_steal_lv3": {
		"skill_id": "life_steal", 
		"skill_name": "吮墨", 
		"trigger_rate": 0.3, 
		"lifesteal_ratio": 0.2, 
		"priority": 5
	}, 
	"splash_lv4": {"skill_id": "splash", "skill_name": "溅墨", "trigger_rate": 1.0, "target_count": 4, "damage_ratio": 1.0, "priority": 100}, 
	"splash_lv5": {"skill_id": "splash", "skill_name": "溅墨", "trigger_rate": 1.0, "target_count": 5, "damage_ratio": 1.0, "priority": 100}, 
	"double_shot_lv4": {"skill_id": "double_shot", "skill_name": "连笔", "trigger_rate": 0.6, "hit_count": 3, "damage_ratio_per_hit": 1.0, "priority": 10}, 
	"double_shot_lv5": {"skill_id": "double_shot", "skill_name": "连笔", "trigger_rate": 0.7, "hit_count": 4, "damage_ratio_per_hit": 1.0, "priority": 10}, 
	"divine_protect_lv4": {"skill_id": "divine_protect", "skill_name": "护墨", "trigger_rate": 0.6, "hp_restore_ratio": 1.0, "max_use_per_battle": 5}, 
	"divine_protect_lv5": {"skill_id": "divine_protect", "skill_name": "护墨", "trigger_rate": 0.7, "hp_restore_ratio": 1.0, "max_use_per_battle": 6}, 
	"counter_attack_lv4": {"skill_id": "counter_attack", "skill_name": "逆锋", "trigger_rate": 0.6, "damage_ratio": 1.0}, 
	"counter_attack_lv5": {"skill_id": "counter_attack", "skill_name": "逆锋", "trigger_rate": 0.7, "damage_ratio": 1.2}, 
	"fortify_lv4": {"skill_id": "fortify", "skill_name": "固色", "level": 4, "defense_bonus_percent": 230}, 
	"fortify_lv5": {"skill_id": "fortify", "skill_name": "固色", "level": 5, "defense_bonus_percent": 250}, 
	"life_steal_lv4": {"skill_id": "life_steal", "skill_name": "吮墨", "trigger_rate": 0.4, "lifesteal_ratio": 0.25, "priority": 5}, 
	"life_steal_lv5": {"skill_id": "life_steal", "skill_name": "吮墨", "trigger_rate": 0.5, "lifesteal_ratio": 0.3, "priority": 5}, 
	"swift_lv1": {"skill_id": "swift", "skill_name": "疾笔", "level": 1, "agility_bonus_percent": 5}, 
	"swift_lv2": {"skill_id": "swift", "skill_name": "疾笔", "level": 2, "agility_bonus_percent": 10}, 
	"swift_lv3": {"skill_id": "swift", "skill_name": "疾笔", "level": 3, "agility_bonus_percent": 15}, 
	"swift_lv4": {"skill_id": "swift", "skill_name": "疾笔", "level": 4, "agility_bonus_percent": 20}, 
	"swift_lv5": {"skill_id": "swift", "skill_name": "疾笔", "level": 5, "agility_bonus_percent": 25}, 
	"longevity_lv1": {"skill_id": "longevity", "skill_name": "寿墨", "level": 1, "hp_bonus_percent": 5}, 
	"longevity_lv2": {"skill_id": "longevity", "skill_name": "寿墨", "level": 2, "hp_bonus_percent": 10}, 
	"longevity_lv3": {"skill_id": "longevity", "skill_name": "寿墨", "level": 3, "hp_bonus_percent": 15}, 
	"longevity_lv4": {"skill_id": "longevity", "skill_name": "寿墨", "level": 4, "hp_bonus_percent": 20}, 
	"longevity_lv5": {"skill_id": "longevity", "skill_name": "寿墨", "level": 5, "hp_bonus_percent": 25}, 
	"mighty_lv1": {"skill_id": "mighty", "skill_name": "壮笔", "level": 1, "attack_bonus_percent": 5}, 
	"mighty_lv2": {"skill_id": "mighty", "skill_name": "壮笔", "level": 2, "attack_bonus_percent": 10}, 
	"mighty_lv3": {"skill_id": "mighty", "skill_name": "壮笔", "level": 3, "attack_bonus_percent": 15}, 
	"mighty_lv4": {"skill_id": "mighty", "skill_name": "壮笔", "level": 4, "attack_bonus_percent": 20}, 
	"mighty_lv5": {"skill_id": "mighty", "skill_name": "壮笔", "level": 5, "attack_bonus_percent": 25}, 
	"fierce_lv1": {"skill_id": "fierce", "skill_name": "烈墨", "level": 1, "crit_damage_bonus_percent": 5}, 
	"fierce_lv2": {"skill_id": "fierce", "skill_name": "烈墨", "level": 2, "crit_damage_bonus_percent": 10}, 
	"fierce_lv3": {"skill_id": "fierce", "skill_name": "烈墨", "level": 3, "crit_damage_bonus_percent": 15}, 
	"fierce_lv4": {"skill_id": "fierce", "skill_name": "烈墨", "level": 4, "crit_damage_bonus_percent": 20}, 
	"fierce_lv5": {"skill_id": "fierce", "skill_name": "烈墨", "level": 5, "crit_damage_bonus_percent": 25}, 
	"fatal_lv1": {"skill_id": "fatal", "skill_name": "断锋", "level": 1, "crit_rate_bonus_percent": 5}, 
	"fatal_lv2": {"skill_id": "fatal", "skill_name": "断锋", "level": 2, "crit_rate_bonus_percent": 10}, 
	"fatal_lv3": {"skill_id": "fatal", "skill_name": "断锋", "level": 3, "crit_rate_bonus_percent": 15}, 
	"fatal_lv4": {"skill_id": "fatal", "skill_name": "断锋", "level": 4, "crit_rate_bonus_percent": 20}, 
	"fatal_lv5": {"skill_id": "fatal", "skill_name": "断锋", "level": 5, "crit_rate_bonus_percent": 25}, 
	"self_heal_lv1": {"skill_id": "self_heal", "skill_name": "回润", "level": 1, "heal_ratio": 0.05}, 
	"self_heal_lv2": {"skill_id": "self_heal", "skill_name": "回润", "level": 2, "heal_ratio": 0.1}, 
	"self_heal_lv3": {"skill_id": "self_heal", "skill_name": "回润", "level": 3, "heal_ratio": 0.15}, 
	"self_heal_lv4": {"skill_id": "self_heal", "skill_name": "回润", "level": 4, "heal_ratio": 0.2}, 
	"self_heal_lv5": {"skill_id": "self_heal", "skill_name": "回润", "level": 5, "heal_ratio": 0.25}, 
	"chase_lv1": {"skill_id": "chase", "skill_name": "续笔", "level": 1, "chase_trigger_rate": 0.4, "chase_ratio": 1.0}, 
	"chase_lv2": {"skill_id": "chase", "skill_name": "续笔", "level": 2, "chase_trigger_rate": 0.7, "chase_ratio": 1.0}, 
	"chase_lv3": {"skill_id": "chase", "skill_name": "续笔", "level": 3, "chase_trigger_rate": 0.8, "chase_ratio": 1.0}, 
	"chase_lv4": {"skill_id": "chase", "skill_name": "续笔", "level": 4, "chase_trigger_rate": 0.9, "chase_ratio": 1.0}, 
	"chase_lv5": {"skill_id": "chase", "skill_name": "续笔", "level": 5, "chase_trigger_rate": 1.0, "chase_ratio": 1.0}, 
	"loyal_lv1": {"skill_id": "loyal", "skill_name": "守纸", "level": 1, "block_chance": 0.05}, 
	"loyal_lv2": {"skill_id": "loyal", "skill_name": "守纸", "level": 2, "block_chance": 0.1}, 
	"loyal_lv3": {"skill_id": "loyal", "skill_name": "守纸", "level": 3, "block_chance": 0.15}, 
	"loyal_lv4": {"skill_id": "loyal", "skill_name": "守纸", "level": 4, "block_chance": 0.2}, 
	"loyal_lv5": {"skill_id": "loyal", "skill_name": "守纸", "level": 5, "block_chance": 0.25}, 
	"taunt_lv1": {"skill_id": "taunt", "skill_name": "引锋", "level": 1, "trigger_rate": 0.2}, 
	"taunt_lv2": {"skill_id": "taunt", "skill_name": "引锋", "level": 2, "trigger_rate": 0.4}, 
	"taunt_lv3": {"skill_id": "taunt", "skill_name": "引锋", "level": 3, "trigger_rate": 0.6}, 
	"taunt_lv4": {"skill_id": "taunt", "skill_name": "引锋", "level": 4, "trigger_rate": 0.8}, 
	"taunt_lv5": {"skill_id": "taunt", "skill_name": "引锋", "level": 5, "trigger_rate": 1.0}, 
	"armor_pierce_lv1": {"skill_id": "armor_pierce", "skill_name": "破纸", "level": 1, "trigger_rate": 0.01}, 
	"armor_pierce_lv2": {"skill_id": "armor_pierce", "skill_name": "破纸", "level": 2, "trigger_rate": 0.02}, 
	"armor_pierce_lv3": {"skill_id": "armor_pierce", "skill_name": "破纸", "level": 3, "trigger_rate": 0.03}, 
	"armor_pierce_lv4": {"skill_id": "armor_pierce", "skill_name": "破纸", "level": 4, "trigger_rate": 0.04}, 
	"armor_pierce_lv5": {"skill_id": "armor_pierce", "skill_name": "破纸", "level": 5, "trigger_rate": 0.05}, 
	"guard_lv1": {"skill_id": "guard", "skill_name": "收锋", "level": 1, "trigger_rate": 0.1, "damage_reduction_ratio": 0.5}, 
	"guard_lv2": {"skill_id": "guard", "skill_name": "收锋", "level": 2, "trigger_rate": 0.2, "damage_reduction_ratio": 0.6}, 
	"guard_lv3": {"skill_id": "guard", "skill_name": "收锋", "level": 3, "trigger_rate": 0.3, "damage_reduction_ratio": 0.7}, 
	"guard_lv4": {"skill_id": "guard", "skill_name": "收锋", "level": 4, "trigger_rate": 0.4, "damage_reduction_ratio": 0.8}, 
	"guard_lv5": {"skill_id": "guard", "skill_name": "收锋", "level": 5, "trigger_rate": 0.5, "damage_reduction_ratio": 0.9}, 
}

static var _runtime_overrides: Dictionary = {}

static func apply_runtime_definitions(defs: Dictionary) -> void :
	_runtime_overrides = defs.duplicate(true) if defs is Dictionary else {}

static func get_skill_definition(skill_key: String) -> Dictionary:
	if _runtime_overrides.has(skill_key):
		return (_runtime_overrides[skill_key] as Dictionary).duplicate(true)
	return (SKILL_DEFINITIONS.get(skill_key, {}) as Dictionary).duplicate(true)

static func get_pet_skill_entries(pet: Pet) -> Array:
	if pet == null:
		return []
	if pet.has_method("normalize_skill_slots"):
		pet.normalize_skill_slots()
	var result: Array = []
	var slots: Array = pet.skill_slots if pet.skill_slots is Array else []
	for entry in slots:
		if not (entry is Dictionary):
			continue
		var row: Dictionary = entry
		var skill_key: = str(row.get("skill_key", "")).strip_edges()
		if skill_key.is_empty():
			continue
		var config: = get_skill_definition(skill_key)
		if config.is_empty():
			continue
		var merged: = row.duplicate(true)
		merged["skill_key"] = skill_key
		merged["config"] = config
		result.append(merged)
	return result

static func get_best_skill_by_ids(pet: Pet, skill_ids: Array) -> Dictionary:
	var best: Dictionary = {}
	for entry in get_pet_skill_entries(pet):
		var config: Dictionary = entry.get("config", {})
		var skill_id: = str(config.get("skill_id", ""))
		if not skill_ids.has(skill_id):
			continue
		if best.is_empty() or int(config.get("priority", 0)) > int((best.get("config", {}) as Dictionary).get("priority", 0)):
			best = entry
	return best

static func get_skill_by_id(pet: Pet, skill_id: String) -> Dictionary:
	for entry in get_pet_skill_entries(pet):
		var config: Dictionary = entry.get("config", {})
		if str(config.get("skill_id", "")) == skill_id:
			return entry
	return {}

const MUTEX_GROUPS: = {
	"attack_style": ["splash", "double_shot"], 
	"splash_chase": ["splash", "chase"], 
	"fortify_guard": ["fortify", "guard"], 
}

static func get_mutex_group(skill_id: String) -> Array:
	var out: Array = []
	for group in MUTEX_GROUPS.values():
		if group.has(skill_id):
			for sid in group:
				if not out.has(sid):
					out.append(sid)
	if out.is_empty():
		return [skill_id]
	return out

static func get_mutex_group_for_skill_key(skill_key: String) -> Array:
	var def: = get_skill_definition(skill_key)
	if def.is_empty():
		return []
	var skill_id: = str(def.get("skill_id", ""))
	if skill_id.is_empty():
		return []
	return get_mutex_group(skill_id)
