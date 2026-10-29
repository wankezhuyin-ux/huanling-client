class_name PetAssistBonus
extends RefCounted





const GameData = preload("res://scripts/game_data.gd")
const GameManagerClass = preload("res://scripts/game_manager.gd")

const MAX_SLOTS: = 10
const SLOT_ELEMENTS: = ["水", "火", "土", "金", "木", "水", "火", "土", "金", "木"]

const SLOT_UNLOCK_NOBLE: PackedInt32Array = [3, 6, 9, 12, 15, 0, 0, 0, 0, 0]
const DEFAULT_BASE_RATE: = 0.01
const DEFAULT_SPECIAL_TYPE_RATE: = 0.02
const DEFAULT_SPONSOR_CUSTOM_RATE: = 0.05
const DEFAULT_MUTATION_RATE_PER_COUNT: = 0.01

static var _runtime_rates: Dictionary = {}

static func apply_runtime_config(cfg: Dictionary) -> void :
	if cfg == null or cfg.is_empty():
		_runtime_rates.clear()
		return
	_runtime_rates = {
		"baseRate": clampf(float(cfg.get("baseRate", DEFAULT_BASE_RATE)), 0.0, 1.0), 
		"specialTypeRate": clampf(float(cfg.get("specialTypeRate", DEFAULT_SPECIAL_TYPE_RATE)), 0.0, 1.0), 
		"sponsorCustomRate": clampf(float(cfg.get("sponsorCustomRate", DEFAULT_SPONSOR_CUSTOM_RATE)), 0.0, 1.0), 
		"mutationRatePerCount": clampf(float(cfg.get("mutationRatePerCount", DEFAULT_MUTATION_RATE_PER_COUNT)), 0.0, 1.0), 
	}

static func _get_rates() -> Dictionary:
	if not _runtime_rates.is_empty():
		return _runtime_rates
	var gm = GameManagerClass.instance
	if gm != null and gm.gameplay_runtime_config is Dictionary:
		var pa: Variant = gm.gameplay_runtime_config.get("petAssist", {})
		if pa is Dictionary and not (pa as Dictionary).is_empty():
			apply_runtime_config(pa)
			if not _runtime_rates.is_empty():
				return _runtime_rates
	return {
		"baseRate": DEFAULT_BASE_RATE, 
		"specialTypeRate": DEFAULT_SPECIAL_TYPE_RATE, 
		"sponsorCustomRate": DEFAULT_SPONSOR_CUSTOM_RATE, 
		"mutationRatePerCount": DEFAULT_MUTATION_RATE_PER_COUNT, 
	}

static func player_noble_level() -> int:
	var gm = GameManagerClass.instance
	if gm != null:
		return maxi(0, int(gm.noble_level))
	return 0

static func slot_unlock_noble(index: int) -> int:
	if index < 0 or index >= MAX_SLOTS:
		return 0
	return int(SLOT_UNLOCK_NOBLE[index])

static func is_slot_unlocked(index: int, reincarnation: int, noble_level: int = -1) -> bool:
	if index < 0 or index >= MAX_SLOTS:
		return false
	if int(reincarnation) >= slot_unlock_reincarnation(index):
		return true
	var noble: = noble_level if noble_level >= 0 else player_noble_level()
	var need_n: = slot_unlock_noble(index)
	return need_n > 0 and noble >= need_n

static func unlocked_slot_count(reincarnation: int, noble_level: int = -1) -> int:
	var noble: = noble_level if noble_level >= 0 else player_noble_level()
	var n: = 0
	for i in range(MAX_SLOTS):
		if is_slot_unlocked(i, reincarnation, noble):
			n += 1
	return n

static func slot_element(index: int) -> String:
	if index < 0 or index >= MAX_SLOTS:
		return ""
	return SLOT_ELEMENTS[index]

static func slot_unlock_reincarnation(index: int) -> int:
	if index < 0 or index >= MAX_SLOTS:
		return 999999
	return (index + 1) * 100

static func _species_meta(pet_id: String) -> Dictionary:
	var pid: = str(pet_id).strip_edges()
	if pid.is_empty():
		return {}
	var meta: Dictionary = {}
	if GameData.PET_DATA.has(pid):
		var d = GameData.PET_DATA[pid]
		if d is Dictionary:
			meta = d
	if str(meta.get("collection_flavor", "")).strip_edges().is_empty():
		for lib in [GameData.EVENT_PET_LIBRARY, GameData.SOUL_REWARD_PET_LIBRARY, GameData.WORLD_BOSS_PET_LIBRARY]:
			if lib.has(pid):
				var ev = lib[pid]
				if ev is Dictionary:
					if meta.is_empty():
						meta = ev
					else:
						meta = meta.duplicate()
						for k in ev.keys():
							if not meta.has(k) or str(meta.get(k, "")).strip_edges().is_empty():
								meta[k] = ev[k]
					break
	return meta

static func _collection_flavor(meta: Dictionary) -> String:
	return str(meta.get("collection_flavor", "")).strip_edges()

static func is_sponsor_custom_meta(meta: Dictionary) -> bool:
	var flavor: = _collection_flavor(meta)
	return flavor.find("旧岁遗珍") >= 0 or flavor.find("私藏") >= 0

static func is_noble10_exclusive_meta(meta: Dictionary) -> bool:
	return _collection_flavor(meta).find("贵族10专属") >= 0

static func is_special_plus1_meta(meta: Dictionary) -> bool:
	if bool(meta.get("is_festival_pet", false)):
		return true
	if bool(meta.get("is_world_boss_pet", false)):
		return true
	if bool(meta.get("is_soul_reward_pet", false)):
		return true
	if is_noble10_exclusive_meta(meta):
		return true
	return false

static func type_extra_rate(meta: Dictionary) -> float:
	var rates: = _get_rates()

	if is_sponsor_custom_meta(meta):
		return float(rates.get("sponsorCustomRate", DEFAULT_SPONSOR_CUSTOM_RATE))
	if is_special_plus1_meta(meta):
		return float(rates.get("specialTypeRate", DEFAULT_SPECIAL_TYPE_RATE))
	return 0.0

static func mutation_extra_rate(mutation_count: int) -> float:
	var mc: = clampi(int(mutation_count), 0, 2)
	if mc <= 0:
		return 0.0
	var rates: = _get_rates()
	return float(mc) * float(rates.get("mutationRatePerCount", DEFAULT_MUTATION_RATE_PER_COUNT))

static func _pet_display_name(pet) -> String:
	if pet == null:
		return ""
	if pet is Dictionary:
		return str(pet.get("pet_name", pet.get("name", pet.get("petName", "")))).strip_edges()
	var n: = ""
	if "pet_name" in pet:
		n = str(pet.pet_name).strip_edges()
	if n.is_empty() and "name" in pet:
		n = str(pet.name).strip_edges()
	return n

static func _species_meta_by_name(pet_name: String) -> Dictionary:
	var want: = str(pet_name).strip_edges()
	if want.is_empty():
		return {}
	for lib in [GameData.PET_DATA, GameData.EVENT_PET_LIBRARY, GameData.SOUL_REWARD_PET_LIBRARY, GameData.WORLD_BOSS_PET_LIBRARY]:
		for pid in lib.keys():
			var row = lib[pid]
			if row is Dictionary and str(row.get("name", "")).strip_edges() == want:
				return row
	return {}

static func rate_for_pet(pet) -> float:
	if pet == null:
		return 0.0
	var pet_id: = ""
	var mutation_count: = 0
	if pet is Dictionary:
		pet_id = str(pet.get("pet_id", "")).strip_edges()
		mutation_count = int(pet.get("mutation_count", pet.get("mutationCount", 0)))
	else:
		pet_id = str(pet.pet_id).strip_edges() if "pet_id" in pet else ""
		mutation_count = int(pet.mutation_count) if "mutation_count" in pet else 0
	var meta: = _species_meta(pet_id)
	if meta.is_empty() or str(meta.get("collection_flavor", "")).strip_edges().is_empty():
		var by_name: = _species_meta_by_name(_pet_display_name(pet))
		if not by_name.is_empty():
			if meta.is_empty():
				meta = by_name
			else:
				meta = meta.duplicate()
				for k in by_name.keys():
					if not meta.has(k) or str(meta.get(k, "")).strip_edges().is_empty():
						meta[k] = by_name[k]
	var rates: = _get_rates()
	return float(rates.get("baseRate", DEFAULT_BASE_RATE)) + type_extra_rate(meta) + mutation_extra_rate(mutation_count)

static func _pet_base_stat(pet, stat_key: String) -> float:
	if pet == null:
		return 0.0
	var key: = "max_hp" if stat_key == "hp" else stat_key
	if pet is Dictionary:
		return maxf(0.0, float(pet.get(key, pet.get(stat_key, 0))))
	match key:
		"attack":
			return maxf(0.0, float(pet.attack))
		"defense":
			return maxf(0.0, float(pet.defense))
		"agility":
			return maxf(0.0, float(pet.agility))
		"max_hp":
			return maxf(0.0, float(pet.max_hp))
		_:
			return 0.0

static func flat_bonus_from_assist_pet(pet, stat_key: String) -> float:
	return _pet_base_stat(pet, stat_key) * rate_for_pet(pet)

static func total_flat_bonus(assist_pets: Array, stat_key: String) -> float:
	var total: = 0.0
	for pet in assist_pets:
		if pet == null:
			continue
		total += flat_bonus_from_assist_pet(pet, stat_key)
	return total
