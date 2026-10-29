extends Node
class_name Pet

const GameData = preload("res://scripts/game_data.gd")
const EvolutionDataClass = preload("res://scripts/evolution_data.gd")
const GameManagerClass = preload("res://scripts/game_manager.gd")
const FabaoStatBonus = preload("res://scripts/fabao/fabao_stat_bonus.gd")
const ELEMENT_NORMAL: = "普通"
const PET_TYPE_BALANCED: = "普通型"
const UNKNOWN_PET_NAME: = "未知宠物"
const FORM_JUVENILE: = "幼年"
const FORM_STAGE_1: = "一进"
const FORM_STAGE_2: = "二进"
const FORM_FINAL: = "终极"
const FORM_NON_EVOLVABLE: = "不可进化"


var id: String
var pet_name: String
var original_name: String
var pet_id: String
var level: int = 1
var experience: int = 0
var element: String = ELEMENT_NORMAL
var pet_type: String = PET_TYPE_BALANCED


var attack: float = 5.0
var defense: float = 5.0
var agility: float = 5.0
var hp: float = 30.0
var max_hp: float = 30.0


const LEVEL_TOTAL_GROWTH_INITIAL_BASELINE: float = 6.0
const LEVEL_TOTAL_GROWTH_INITIAL_COEFF: float = 0.001

const LINEAGE_SEED_SAVE_FALLBACK: float = 3.0

var growth_rates = {
	"attack": 1.0, 
	"defense": 1.0, 
	"agility": 1.0, 
	"hp": 1.0
}
var total_growth: float = 3.0

var lineage_seed_growth: float = 3.0


var base_stats = {
	"attack": 5.0, 
	"defense": 5.0, 
	"agility": 5.0, 
	"hp": 30.0
}
var stat_ratio = {
	"attack": 33.33, 
	"defense": 33.33, 
	"agility": 33.34
}

var capture_map: String = ""
var is_elite: bool = false
var form: String = FORM_JUVENILE
var generation: int = 0
var locked: bool = false

var pet_raise_race_used: bool = false
var medal_counts: Dictionary = {
	"brave": 0, 
	"calm": 0, 
	"bold": 0
}
var pending_medal_sync: bool = false
var pending_medal_sync_reason: String = ""
var pending_skill_learn_sync: bool = false
var pending_skill_learn_prev_level: int = 0
var last_max_level_skill_learn_cap: int = 0

var last_max_level_medal_cap: int = 0
const SKILL_SLOT_COUNT: = 3
const SKILL_SLOT_COUNT_MAX: = 5
var skill_slots: Array = []


var evolution_stage: int = 0
var is_mutant: bool = false
var mutation_count: int = 0
var is_evolution_pet: bool = false
var evolution_origin: String = ""
var max_level: int = 1500
var reincarnation_count: int = 0


signal level_up(new_level: int)
signal exp_changed(new_exp: int, required_exp: int)

static func _normalize_form_text(value: String) -> String:
	match value:
		"", "??":
			return FORM_JUVENILE
		"????":
			return FORM_NON_EVOLVABLE
		_:
			return value


static func get_skill_slot_count_for_pet_id(pet_id_value: String) -> int:
	var pid: = str(pet_id_value).strip_edges()
	if pid.is_empty():
		return SKILL_SLOT_COUNT
	var gm = GameManager.instance
	if gm == null:
		return SKILL_SLOT_COUNT
	var cfg: Variant = gm.gameplay_runtime_config.get("petSkillSlots", {}) if gm.gameplay_runtime_config is Dictionary else {}
	if not (cfg is Dictionary):
		return SKILL_SLOT_COUNT
	var d: Dictionary = cfg
	var feature_on: = bool(d.get("featureEnabled", false))
	var five_ids: Variant = d.get("fiveSlotPetIds", [])
	var in_checked: = false
	if five_ids is Array:
		for row in five_ids:
			if str(row).strip_edges() == pid:
				in_checked = true
				break
	if feature_on:
		if in_checked:
			return SKILL_SLOT_COUNT_MAX
		var sponsor_ids: Variant = d.get("sponsorCustomPetIds", [])
		if sponsor_ids is Array:
			for row in sponsor_ids:
				if str(row).strip_edges() == pid:
					return 4
		return 3
	if in_checked:
		return 4
	var ids: Variant = d.get("fourSlotPetIds", [])
	if not (ids is Array):
		return SKILL_SLOT_COUNT
	for row in ids:
		if str(row).strip_edges() == pid:
			return 4
	return SKILL_SLOT_COUNT

func _count_occupied_skill_slots() -> int:
	var n: = 0
	if not (skill_slots is Array):
		return 0
	for entry in skill_slots:
		var d: Dictionary = entry if entry is Dictionary else {}
		if not str(d.get("skill_key", "")).strip_edges().is_empty():
			n += 1
			continue
		if not str(d.get("skill_id", "")).strip_edges().is_empty():
			n += 1
			continue
		var nm: = str(d.get("skill_name", "")).strip_edges()
		if not nm.is_empty() and nm != "无":
			n += 1
	return n

func get_skill_slot_count() -> int:
	var rule: = get_skill_slot_count_for_pet_id(str(pet_id))
	var occupied: = _count_occupied_skill_slots()
	return clampi(maxi(rule, occupied), 1, SKILL_SLOT_COUNT_MAX)

func _init():
	id = _generate_id()
	skill_slots = _build_empty_skill_slots_with_count(SKILL_SLOT_COUNT)

static func _build_empty_skill_slots_with_count(count: int) -> Array:
	var n: = clampi(count, 1, SKILL_SLOT_COUNT_MAX)
	var slots: Array = []
	for i in range(n):
		slots.append({
			"slot": i + 1, 
			"skill_key": "", 
			"skill_id": "", 
			"skill_name": "", 
			"level": 0
		})
	return slots

static func _build_empty_skill_slots() -> Array:
	return _build_empty_skill_slots_with_count(SKILL_SLOT_COUNT)


static func _infer_skill_key_from_skill_id_level(skill_id: String, level: int) -> String:
	var sid: = skill_id.strip_edges()
	if sid.is_empty() or level < 1:
		return ""
	for k in GameData.PET_SKILLS.keys():
		var cfg: Dictionary = GameData.PET_SKILLS[k]
		if str(cfg.get("skill_id", "")).strip_edges() == sid and int(cfg.get("level", 0)) == level:
			return str(k)
	return ""

static func _normalize_skill_slot_entry(raw: Variant, index: int) -> Dictionary:
	var fallback = {
		"slot": index + 1, 
		"skill_key": "", 
		"skill_id": "", 
		"skill_name": "", 
		"level": 0
	}
	if not (raw is Dictionary):
		return fallback
	var d: Dictionary = raw
	var skill_key: = str(d.get("skill_key", "")).strip_edges()
	var skill_id: = str(d.get("skill_id", "")).strip_edges()
	var skill_name: = str(d.get("skill_name", "")).strip_edges()
	var level: = maxi(0, int(d.get("level", 0)))
	if skill_key.is_empty():
		skill_key = _infer_skill_key_from_skill_id_level(skill_id, level)
	if not skill_key.is_empty():
		var cfg_fill: Dictionary = GameData.PET_SKILLS.get(skill_key, {})
		if skill_id.is_empty():
			skill_id = str(cfg_fill.get("skill_id", "")).strip_edges()
		var catalog_name: = str(cfg_fill.get("name", "")).strip_edges()
		if not catalog_name.is_empty():
			skill_name = catalog_name
	var out: = {
		"slot": int(d.get("slot", index + 1)), 
		"skill_key": skill_key, 
		"skill_id": skill_id, 
		"skill_name": skill_name, 
		"level": level
	}
	if d.has("locked_level"):
		out["locked_level"] = maxi(0, int(d.get("locked_level", 0)))
	if d.has("book_refunds"):
		out["book_refunds"] = _normalize_book_refunds(d.get("book_refunds"))
	if d.has("slot_locked") and bool(d.get("slot_locked", false)):
		out["slot_locked"] = true
	return out

static func _normalize_book_refunds(raw: Variant) -> Array:
	var out: Array = []
	if not (raw is Array):
		return out
	for item in raw:
		var n: = str(item).strip_edges()
		if not n.is_empty() and GameData.PET_SKILL_BOOKS.has(n):
			out.append(n)
	return out

func normalize_skill_slots() -> void :
	var slot_count: = get_skill_slot_count()
	var normalized: Array = _build_empty_skill_slots_with_count(slot_count)
	if skill_slots is Array:
		for i in range(mini(slot_count, skill_slots.size())):
			normalized[i] = _normalize_skill_slot_entry(skill_slots[i], i)
	skill_slots = normalized

func set_skill_to_slot(slot_index: int, skill_info: Dictionary) -> bool:
	var slot_count: = get_skill_slot_count()
	if slot_index < 0 or slot_index >= slot_count:
		return false
	normalize_skill_slots()
	var entry = _normalize_skill_slot_entry(skill_info, slot_index)
	entry["slot"] = slot_index + 1
	skill_slots[slot_index] = entry
	return true

func get_skill_slot(slot_index: int) -> Dictionary:
	normalize_skill_slots()
	var slot_count: = get_skill_slot_count()
	if slot_index < 0 or slot_index >= slot_count:
		return {}
	return (skill_slots[slot_index] as Dictionary).duplicate(true)

func get_skill_by_key(skill_key: String) -> Dictionary:
	normalize_skill_slots()
	var key: = skill_key.strip_edges()
	if key.is_empty():
		return {}
	for entry in skill_slots:
		var d: Dictionary = entry if entry is Dictionary else {}
		if str(d.get("skill_key", "")).strip_edges() == key:
			return d.duplicate(true)
	return {}

func is_skill_slot_locked(slot_index: int) -> bool:
	normalize_skill_slots()
	if slot_index < 0 or slot_index >= skill_slots.size():
		return false
	var d: Dictionary = skill_slots[slot_index] if skill_slots[slot_index] is Dictionary else {}
	return bool(d.get("slot_locked", false))

func can_unlearn_skill_slot(slot_index: int, is_festival: bool) -> bool:
	normalize_skill_slots()
	if slot_index < 0 or slot_index >= skill_slots.size():
		return false
	var d: Dictionary = skill_slots[slot_index] if skill_slots[slot_index] is Dictionary else {}
	var skill_name: = str(d.get("skill_name", "")).strip_edges()
	var skill_level: = int(d.get("level", 0))
	if skill_level <= 0 or skill_name.is_empty() or skill_name == "无":
		return false
	var refunds: Array = _normalize_book_refunds(d.get("book_refunds")) if d.has("book_refunds") else []
	if refunds.size() > 0:
		return true
	if d.has("locked_level") or d.has("book_refunds"):
		return false
	if is_festival:
		return false
	return true

func _generate_id() -> String:
	var chars = "abcdefghijklmnopqrstuvwxyz0123456789"
	var result = ""
	for i in range(8):
		result += chars[randi() % chars.length()]
	return result


func get_required_exp() -> int:
	return GameData.get_pet_required_exp(level)


static func ensure_lineage_seed_growth_dictionary(pet_data: Dictionary) -> float:
	if pet_data == null or not pet_data is Dictionary:
		return LINEAGE_SEED_SAVE_FALLBACK
	if pet_data.has("lineage_seed_growth"):
		var raw_ls = pet_data.get("lineage_seed_growth")
		if raw_ls != null:
			return float(raw_ls)
	if pet_data.has("initial_total_growth"):
		var raw_i = pet_data.get("initial_total_growth")
		if raw_i != null:
			var f_i: = float(raw_i)
			pet_data["lineage_seed_growth"] = f_i
			push_warning("[Pet] 存档缺 lineage_seed_growth，已用 initial_total_growth 补全")
			return f_i
	pet_data["lineage_seed_growth"] = LINEAGE_SEED_SAVE_FALLBACK
	push_warning("[Pet] 存档缺 lineage_seed_growth 与 initial_total_growth，已用默认值 %.1f 补全（未使用 total_growth）" % LINEAGE_SEED_SAVE_FALLBACK)
	return LINEAGE_SEED_SAVE_FALLBACK

static func roll_level_total_growth_delta(generation: int, lineage_seed_growth_at_level1: float = 3.0, mutation_count_arg: int = 0, is_evolution_pet_arg: bool = false) -> float:
	var max_growth: = 0.003 + float(generation) * 0.001
	var initial_bonus_growth: = maxf(0.0, lineage_seed_growth_at_level1 - LEVEL_TOTAL_GROWTH_INITIAL_BASELINE)
	var lineage_base: = sqrt(initial_bonus_growth) * LEVEL_TOTAL_GROWTH_INITIAL_COEFF
	var lineage_mult: = _resolve_level_up_lineage_multiplier(mutation_count_arg, is_evolution_pet_arg)
	max_growth += lineage_base * lineage_mult
	return randf_range(-0.001, max_growth)

static func _resolve_level_up_lineage_multiplier(mutation_count_arg: int, is_evolution_pet_arg: bool) -> float:
	var gm = GameManagerClass.instance
	if gm == null or not gm.has_method("is_pet_mutation_feature_enabled") or not gm.is_pet_mutation_feature_enabled():
		return 1.0
	var cfg: Dictionary = {}
	if gm.has_method("get_pet_mutation_runtime_config"):
		cfg = gm.get_pet_mutation_runtime_config()
	var lu: Variant = cfg.get("lineageLevelUp", {})
	var evolvable_mult: = 1.0
	var nonevo_mult: = 1.0
	var mut0: = 1.0
	var mut1: = 1.0
	var mut2: = 1.0
	if lu is Dictionary:
		evolvable_mult = float(lu.get("evolvableMult", 1.0))
		nonevo_mult = float(lu.get("nonEvolvableMult", 1.0))
		var mm: Variant = lu.get("mutationMult", {})
		if mm is Dictionary:
			mut0 = float(mm.get(0, mm.get("0", 1.0)))
			mut1 = float(mm.get(1, mm.get("1", 1.0)))
			mut2 = float(mm.get(2, mm.get("2", 1.0)))
	var type_mult: = evolvable_mult if is_evolution_pet_arg else nonevo_mult
	var mc: = clampi(mutation_count_arg, 0, 2)
	var mut_mult: = mut0
	if mc == 1:
		mut_mult = mut1
	elif mc == 2:
		mut_mult = mut2
	return type_mult * mut_mult

func _level_up_stats():
	var _old_final_hp: = get_final_max_hp_with_equipment()
	var total_change = roll_level_total_growth_delta(generation, lineage_seed_growth, mutation_count, resolve_is_on_evolution_chain())

	for stat in ["attack", "defense", "agility"]:
		var stat_change = total_change * (stat_ratio.get(stat, 33.33) / 100.0)
		growth_rates[stat] = snapped(growth_rates[stat] + stat_change, 0.001)

	attack = snapped(base_stats.attack + (level - 1) * growth_rates.attack, 0.01)
	defense = snapped(base_stats.defense + (level - 1) * growth_rates.defense, 0.01)
	agility = snapped(base_stats.agility + (level - 1) * growth_rates.agility, 0.01)

	total_growth = snapped(growth_rates.attack + growth_rates.defense + growth_rates.agility, 0.001)
	# 生命成长按物种 hp_growth 走（参考稿口径），不再拿 total_growth 顶替
	growth_rates.hp = resolve_hp_growth(pet_id, total_growth)
	max_hp = snapped(base_stats.hp + (level - 1) * growth_rates.hp, 0.01)
	var _new_final_hp: = get_final_max_hp_with_equipment()
	if _old_final_hp <= 0.0001:
		hp = _new_final_hp
	else:
		var _r: = clampf(hp / _old_final_hp, 0.0, 1.0)
		hp = clampf(_new_final_hp * _r, 0.0, _new_final_hp)

func recalculate_stats():
	if GameManager.instance != null and GameManager.instance.has_method("local_use_item"):
		# Recompute derived stats without rolling another level of growth.
		GameManager.instance.pet_manager._update_pet_stats(self)
		return
	_level_up_stats()

func debug_level_up(levels: int):
	var actual_levels = min(levels, get_effective_max_level() - level)
	for i in range(actual_levels):
		level += 1
		_level_up_stats()

func get_exp_percent() -> float:
	var req: = get_required_exp()
	if req < 1:
		return 1.0
	return clampf(float(experience) / float(req), 0.0, 1.0)


func clamp_experience_if_max_level() -> void :
	if level < get_effective_max_level():
		experience = maxi(0, int(experience))
		return
	var cap: = GameData.get_pet_required_exp(level)
	if cap < 1:
		experience = maxi(0, int(experience))
		return
	experience = maxi(0, int(experience))
	if experience > cap:
		experience = cap
	exp_changed.emit(experience, cap)


func take_damage(damage: float) -> float:
	var actual_damage = max(1.0, damage - defense / 2.0)
	hp = max(0.0, hp - actual_damage)
	return actual_damage

func heal(amount: float):
	hp = min(get_final_max_hp_with_equipment(), hp + amount)

func heal_full():
	hp = get_final_max_hp_with_equipment()

func is_pet_mutant() -> bool:
	return is_mutant

func get_mutation_count() -> int:
	return clampi(mutation_count, 0, 2)

func is_alive() -> bool:
	return hp > 0

func get_hp_percent() -> float:
	return hp / get_final_max_hp_with_equipment()



func get_reincarnation_bonus() -> float:
	return float(reincarnation_count) * 0.01


func get_reincarnation_bracket() -> int:
	return reincarnation_count / 10

func resolve_is_on_evolution_chain() -> bool:
	var species_id: = str(pet_id).strip_edges()
	if not species_id.is_empty() and EvolutionDataClass.is_evolution_pet(species_id):
		return true
	return is_evolution_pet

func sync_level_cap_metadata_from_species() -> void :
	is_evolution_pet = resolve_is_on_evolution_chain()
	max_level = GameData.MAX_LEVEL_EVOLUTION if is_evolution_pet else GameData.MAX_LEVEL_NORMAL

func get_effective_max_level() -> int:
	var is_evo: = resolve_is_on_evolution_chain()
	var base_max: = GameData.MAX_LEVEL_EVOLUTION if is_evo else GameData.MAX_LEVEL_NORMAL
	var bonus_per_bracket: = 50 if is_evo else 100
	return base_max + get_reincarnation_bracket() * bonus_per_bracket

func clamp_level_to_effective_max() -> void :
	var cap: = get_effective_max_level()
	if int(level) > cap:
		level = cap
	clamp_experience_if_max_level()

func is_at_max_level() -> bool:
	return level >= get_effective_max_level()

func get_final_attack() -> float:
	var bonus = _get_collection_bonus("attack") + _get_medal_bonus("attack") + get_reincarnation_bonus()
	bonus += _get_talent_bonus("attack") + _get_gang_combat_buff_fraction("attack")
	bonus += _get_fabao_pct_bonus("atk")
	bonus += _get_noble_stat_bonus()
	bonus += _get_skill_stat_bonus_percent("mighty", "attack_bonus_percent")

	var base: float = attack + _get_assist_flat_bonus("attack")
	return base * (1.0 + bonus)

func get_final_defense() -> float:
	var bonus = _get_collection_bonus("defense") + _get_medal_bonus("defense") + get_reincarnation_bonus()
	bonus += _get_skill_stat_bonus_percent("fortify", "defense_bonus_percent")
	bonus += _get_talent_bonus("defense") + _get_gang_combat_buff_fraction("defense")
	bonus += _get_fabao_pct_bonus("def")
	bonus += _get_noble_stat_bonus()
	var base: float = defense + _get_assist_flat_bonus("defense")
	return base * (1.0 + bonus)

func get_final_agility() -> float:
	var bonus = _get_collection_bonus("agility") + _get_medal_bonus("agility") + get_reincarnation_bonus()
	bonus += _get_talent_bonus("agility") + _get_gang_combat_buff_fraction("agility")
	bonus += _get_fabao_pct_bonus("agi")
	bonus += _get_noble_stat_bonus()
	bonus += _get_skill_stat_bonus_percent("swift", "agility_bonus_percent")
	var base: float = agility + _get_assist_flat_bonus("agility")
	return base * (1.0 + bonus)

func get_final_max_hp() -> float:
	var bonus = _get_collection_bonus("hp") + get_reincarnation_bonus()
	bonus += _get_talent_bonus("hp") + _get_gang_combat_buff_fraction("hp")
	bonus += _get_fabao_pct_bonus("hp")
	bonus += _get_skill_stat_bonus_percent("longevity", "hp_bonus_percent")
	var base: float = max_hp + _get_assist_flat_bonus("hp")
	return base * (1.0 + bonus)

func _get_skill_stat_bonus_percent(skill_id: String, field_name: String) -> float:
	for slot in skill_slots:
		if not (slot is Dictionary):
			continue
		var sid: = str(slot.get("skill_id", "")).strip_edges()
		var key: = str(slot.get("skill_key", "")).strip_edges()
		if sid != skill_id and not key.begins_with("%s_" % skill_id):
			continue
		var cfg: Dictionary = GameData.PET_SKILLS.get(key, {})
		if cfg.is_empty() and not key.is_empty():
			cfg = PetSkillConfig.get_skill_definition(key)
		return float(cfg.get(field_name, 0)) / 100.0
	return 0.0


func _get_gang_combat_buff_fraction(stat_key: String) -> float:
	var game_manager = GameManagerClass.instance
	if game_manager == null or game_manager.gang_manager == null:
		return 0.0
	var gang_pct = game_manager.gang_manager.get_buff_percent(stat_key) / 100.0
	return maxf(0.0, gang_pct)

func _get_talent_bonus(stat_key: String) -> float:
	if not _is_active_battle_pet():
		return 0.0
	var game_manager = GameManagerClass.instance
	if game_manager == null or game_manager.player == null:
		return 0.0
	if game_manager.player.has_method("get_talent_percent"):
		return float(game_manager.player.get_talent_percent(stat_key))
	return 0.0

func _get_fabao_pct_bonus(stat_key: String) -> float:
	if not _is_active_battle_pet():
		return 0.0
	return FabaoStatBonus.pet_pct(stat_key) / 100.0


func _get_noble_stat_bonus() -> float:
	if not _is_active_battle_pet():
		return 0.0
	var game_manager = GameManagerClass.instance
	if game_manager == null:
		return 0.0
	return float(clampi(int(game_manager.noble_pet_damage_bonus), 0, 30)) / 100.0

func _is_active_battle_pet() -> bool:
	var game_manager = GameManagerClass.instance
	if game_manager == null or game_manager.pet_manager == null:
		return false
	var active = game_manager.pet_manager.get_active_pet()
	if active == null:
		return false
	return active == self or str(active.id) == str(id)

func _get_collection_bonus(bonus_type: String) -> float:
	var game_manager = GameManagerClass.instance
	if not game_manager or not game_manager.pet_collection_manager:
		return 0.0
	if game_manager.pet_manager:
		var active_pet = game_manager.pet_manager.active_pet
		if active_pet == null or str(active_pet.id) != str(id):
			return 0.0
	return game_manager.pet_collection_manager.get_bonus_by_type(bonus_type)

func _get_medal_bonus(stat_type: String) -> float:
	match stat_type:
		"attack":
			return float(int(medal_counts.get("brave", 0))) * 0.02
		"defense":
			return float(int(medal_counts.get("calm", 0))) * 0.02
		"agility":
			return float(int(medal_counts.get("bold", 0))) * 0.02
		_:
			return 0.0


const BT_PET_SNAPSHOT_META: = "bt_pet_snapshot_stats"

func _get_bt_pet_snapshot_stat(key: String) -> float:
	if not has_meta(BT_PET_SNAPSHOT_META):
		return -1.0
	var stats = get_meta(BT_PET_SNAPSHOT_META)
	if stats is Dictionary and stats.has(key):
		return float(stats[key])
	return -1.0



func get_final_attack_with_equipment() -> float:
	var snap_atk: = _get_bt_pet_snapshot_stat("attack")
	if snap_atk >= 0.0:
		return snap_atk
	var base = get_final_attack()
	var equipment_bonus = _get_pet_equipment_bonus("attack")
	return base + equipment_bonus

func get_final_defense_with_equipment() -> float:
	var snap_def: = _get_bt_pet_snapshot_stat("defense")
	if snap_def >= 0.0:
		return snap_def
	var base = get_final_defense()
	var equipment_bonus = _get_pet_equipment_bonus("defense")
	return base + equipment_bonus

func get_final_agility_with_equipment() -> float:
	var snap_agi: = _get_bt_pet_snapshot_stat("agility")
	if snap_agi >= 0.0:
		return snap_agi
	var base = get_final_agility()
	var equipment_bonus = _get_pet_equipment_bonus("agility")
	return base + equipment_bonus

func get_final_max_hp_with_equipment() -> float:
	var snap_hp: = _get_bt_pet_snapshot_stat("max_hp")
	if snap_hp >= 0.0:
		return snap_hp
	var base = get_final_max_hp()
	var equipment_bonus = _get_pet_equipment_bonus("hp")
	return base + equipment_bonus

func _get_assist_flat_bonus(stat_key: String) -> float:
	if not _is_active_battle_pet():
		return 0.0
	var game_manager = GameManagerClass.instance
	if game_manager == null or game_manager.pet_manager == null:
		return 0.0
	if game_manager.pet_manager.has_method("get_assist_flat_bonus_for_active"):
		return float(game_manager.pet_manager.get_assist_flat_bonus_for_active(stat_key))
	return 0.0



func get_max_hp() -> int:
	return maxi(1, int(ceil(get_final_max_hp_with_equipment())))


func _get_pet_equipment_bonus(stat_type: String) -> float:
	var game_manager = GameManagerClass.instance
	if not game_manager:
		return 0.0

	if not game_manager.pet_equipment_manager:
		return 0.0

	if game_manager.pet_manager:
		var active_pet = game_manager.pet_manager.active_pet
		if active_pet == null:
			return 0.0
		if active_pet.id != self.id:
			return 0.0

	return game_manager.pet_equipment_manager.get_bonus(self, stat_type)


static func create_from_data(pet_data: Dictionary, capture_map_name: String, is_elite_pet: bool = false, pet_type_id: String = ""):
	var pet = new()

	var original_pet_name = pet_data.get("name", UNKNOWN_PET_NAME)
	pet.pet_name = original_pet_name
	pet.original_name = original_pet_name
	pet.pet_id = pet_type_id if not pet_type_id.is_empty() else original_pet_name
	pet.element = pet_data.get("element", ELEMENT_NORMAL)
	pet.pet_type = pet_data.get("type", PET_TYPE_BALANCED)
	pet.capture_map = capture_map_name
	pet.is_elite = is_elite_pet

	pet.is_evolution_pet = EvolutionDataClass.is_evolution_pet(pet.pet_id)
	if pet.is_evolution_pet:
		pet.evolution_origin = EvolutionDataClass.get_evolution_origin(pet.pet_id)
		var normal_chain = EvolutionDataClass.get_evolution_chain_by_origin(pet.evolution_origin, false)
		var mutant_chain = EvolutionDataClass.get_evolution_chain_by_origin(pet.evolution_origin, true)

		var stage_in_normal = normal_chain.find(pet.pet_id)
		var stage_in_mutant = mutant_chain.find(pet.pet_id)

		if stage_in_normal >= 0:
			pet.evolution_stage = stage_in_normal
			pet.is_mutant = false
		elif stage_in_mutant >= 0:
			pet.evolution_stage = stage_in_mutant
			pet.is_mutant = true
		else:
			pet.evolution_stage = 0

		var form_names = [FORM_JUVENILE, FORM_STAGE_1, FORM_STAGE_2, FORM_FINAL]
		if pet.evolution_stage >= 0 and pet.evolution_stage < form_names.size():
			pet.form = form_names[pet.evolution_stage]
		else:
			pet.form = FORM_JUVENILE

		pet.max_level = GameData.MAX_LEVEL_EVOLUTION
	else:
		pet.max_level = GameData.MAX_LEVEL_NORMAL
		pet.form = FORM_NON_EVOLVABLE


	pet.base_stats = {
		"attack": pet_data.get("attack", 5.0), 
		"defense": pet_data.get("defense", 5.0), 
		"agility": pet_data.get("agility", 5.0), 
		"hp": pet_data.get("hp", 30.0)
	}


	var base_ratio = {
		"attack": pet_data.get("ratio", [33, 33, 34])[0], 
		"defense": pet_data.get("ratio", [33, 33, 34])[1], 
		"agility": pet_data.get("ratio", [33, 33, 34])[2]
	}
	pet.stat_ratio = apply_ratio_fluctuation(base_ratio)


	var elite_mult = randf_range(1.3, 1.5) if is_elite_pet else null
	var normal_mult = randf_range(0.9, 1.1) if not is_elite_pet else null

	pet.growth_rates = _calculate_growth_rates(
		pet_data.get("growth", 3.8), 
		pet_data.get("hp_growth", 2.5), 
		pet.stat_ratio, 
		elite_mult, 
		normal_mult
	)

	pet.total_growth = snapped(pet.growth_rates.attack + pet.growth_rates.defense + pet.growth_rates.agility, 0.001)
	pet.lineage_seed_growth = pet.total_growth


	pet.attack = pet.base_stats.attack
	pet.defense = pet.base_stats.defense
	pet.agility = pet.base_stats.agility
	pet.hp = pet.base_stats.hp
	pet.max_hp = pet.base_stats.hp

	return pet

static func _find_pet_id_by_name(name: String) -> String:
	for pet_key in GameData.PET_DATA.keys():
		var pet_data = GameData.PET_DATA.get(pet_key, {})
		if pet_data.get("name", "") == name:
			return pet_key
	return ""

static func apply_ratio_fluctuation(base_ratio: Dictionary) -> Dictionary:
	var fluctuation = randf_range(-0.05, 0.05)
	var new_ratio = base_ratio.duplicate()

	new_ratio.attack = clamp(base_ratio.attack + fluctuation * 100, 15.0, 55.0)
	new_ratio.defense = clamp(base_ratio.defense - fluctuation * 50, 15.0, 55.0)
	new_ratio.agility = clamp(base_ratio.agility - fluctuation * 50, 15.0, 55.0)


	var total = new_ratio.attack + new_ratio.defense + new_ratio.agility
	new_ratio.attack = snapped(new_ratio.attack / total * 100, 0.01)
	new_ratio.defense = snapped(new_ratio.defense / total * 100, 0.01)
	new_ratio.agility = snapped(100 - new_ratio.attack - new_ratio.defense, 0.01)

	return new_ratio

static func _calculate_growth_rates(base_growth: float, hp_growth: float, ratio: Dictionary, elite_mult = null, normal_mult = null) -> Dictionary:
	var multiplier = 1.0
	if elite_mult != null:
		multiplier = elite_mult
	elif normal_mult != null:
		multiplier = normal_mult

	var total_combat_growth = base_growth * multiplier

	return {
		"attack": snapped(total_combat_growth * ratio.attack / 100.0, 0.001), 
		"defense": snapped(total_combat_growth * ratio.defense / 100.0, 0.001), 
		"agility": snapped(total_combat_growth * ratio.agility / 100.0, 0.001), 
		"hp": snapped(hp_growth * multiplier, 0.001)
	}


## 生命成长（参考稿口径）。
##
## 物种表里 `growth`（攻+防+敏总成长）和 `hp_growth`（生命成长）是两个独立数值：
##   雏龙  growth 3.6 / hp_growth 6.0 → 血成长是战斗成长的 1.67 倍（血厚）
##   神甲  growth 4.0 / hp_growth 2.5 → 0.625 倍（血薄）
##   通宝  growth 3.8 / hp_growth 2.9
## 旧公式直接用 total_growth 当血成长（`max_hp = base.hp + total_growth * (等级-1)`），
## 等于把「生命成长」这一栏彻底忽略，面板上写着 6.0 实际按 3.6 在算。
##
## 这里按物种的 hp_growth/growth 比例跟随当前总成长浮动 —— 既保留升级滚动的成长增益，
## 又能吃掉历史存档里被错写成 total_growth 的 `growth_rates.hp`（不信任存档值）。
static func resolve_hp_growth(pet_id: String, combat_total: float) -> float:
	var species: Dictionary = GameData.PET_DATA.get(pet_id, {})
	var species_hp: float = float(species.get("hp_growth", 0.0))
	var species_total: float = float(species.get("growth", 0.0))
	if species_hp <= 0.0 or species_total <= 0.0:
		# 物种表里没有（节日宠 / 蛋 / 合体宠）：退回「生命成长 = 总成长」的老口径
		return maxf(combat_total, 0.0)
	# 成长丹 / 进化 / 变异能把总成长堆到物种基准的十几倍（线上有 60.75 对 3.5 的），
	# 所以这里的上下限只用来拦脏数据，不能当成玩法限制。
	var ratio: float = clampf(combat_total / species_total, 0.05, 100.0)
	return snapped(species_hp * ratio, 0.001)


func to_dict() -> Dictionary:
	sync_level_cap_metadata_from_species()
	return {
		"id": id, 
		"name": pet_name, 
		"pet_id": pet_id, 
		"level": level, 
		"experience": experience, 
		"element": element, 
		"type": pet_type, 
		"attack": attack, 
		"defense": defense, 
		"agility": agility, 
		"hp": hp, 
		"max_hp": max_hp, 
		"final_attack": get_final_attack_with_equipment(), 
		"final_defense": get_final_defense_with_equipment(), 
		"final_agility": get_final_agility_with_equipment(), 
		"final_max_hp": get_final_max_hp_with_equipment(), 
		"growth_rates": growth_rates, 
		"total_growth": total_growth, 
		"lineage_seed_growth": lineage_seed_growth, 
		"base_stats": base_stats, 
		"stat_ratio": stat_ratio, 
		"capture_map": capture_map, 
		"is_elite": is_elite, 
		"form": form, 
		"generation": generation, 
		"locked": locked, 
		"pet_raise_race_used": pet_raise_race_used, 
		"medal_counts": medal_counts.duplicate(), 
		"pending_medal_sync": pending_medal_sync, 
		"pending_medal_sync_reason": pending_medal_sync_reason, 
		"pending_skill_learn_sync": pending_skill_learn_sync, 
		"pending_skill_learn_prev_level": pending_skill_learn_prev_level, 
		"last_max_level_skill_learn_cap": last_max_level_skill_learn_cap, 
		"last_max_level_medal_cap": last_max_level_medal_cap, 
		"skill_slots": skill_slots.duplicate(true), 
		"evolution_stage": evolution_stage, 
		"is_mutant": is_mutant, 
		"mutation_count": mutation_count, 
		"is_evolution_pet": is_evolution_pet, 
		"evolution_origin": evolution_origin, 
		"max_level": max_level, 
		"reincarnation_count": reincarnation_count
	}


func _coerce_locked_from_save(v: Variant) -> bool:
	if v == null:
		return false
	match typeof(v):
		TYPE_BOOL:
			return v
		TYPE_INT:
			return int(v) != 0
		TYPE_FLOAT:
			return int(round(float(v))) != 0
		TYPE_STRING:
			var s: = str(v).strip_edges().to_lower()
			if s.is_empty() or s in ["0", "false", "no", "off", "n"]:
				return false
			if s in ["1", "true", "yes", "on", "y", "locked"]:
				return true
			return false
		_:
			return bool(v)


func from_dict(data: Variant = {}):
	if data == null or not data is Dictionary:
		return

	var raw_id: Variant = data.get("id", null)
	var sid: = ""
	if raw_id != null:
		sid = str(raw_id).strip_edges()
	if sid.is_empty() or sid == "null":
		for alt_k in ["instanceId", "petInstanceId", "_id"]:
			var av: Variant = data.get(alt_k, null)
			if av != null:
				var t: = str(av).strip_edges()
				if not t.is_empty() and t != "null":
					sid = t
					break
	id = sid if not sid.is_empty() else _generate_id()
	var nm_raw: Variant = data.get("name", null)
	pet_name = str(nm_raw).strip_edges() if nm_raw != null else ""
	if pet_name.is_empty():
		pet_name = str(data.get("petName", data.get("displayName", UNKNOWN_PET_NAME)))
	# 图鉴改过名的话老存档里还是旧名，先归一；缺 pet_id 时还要靠这个名字反查图鉴键
	pet_name = GameData.migrate_pet_name(pet_name)
	pet_id = str(data.get("pet_id", data.get("petId", "")))
	if pet_id == "":
		pet_id = _find_pet_id_by_name(pet_name)
	level = data.get("level", 1)
	if data.has("experience"):
		experience = maxi(0, int(data.get("experience", 0)))
	else:
		experience = maxi(0, int(data.get("exp", 0)))
	element = data.get("element", ELEMENT_NORMAL)
	pet_type = str(data.get("type", data.get("pet_type", data.get("petType", PET_TYPE_BALANCED))))
	attack = data.get("attack", 5.0)
	defense = data.get("defense", 5.0)
	agility = data.get("agility", 5.0)
	hp = data.get("hp", 30.0)
	max_hp = data.get("max_hp", 30.0)
	growth_rates = data.get("growth_rates", {"attack": 1.0, "defense": 1.0, "agility": 1.0, "hp": 1.0})
	total_growth = float(data.get("total_growth", data.get("growth", 3.0)))
	if data.has("lineage_seed_growth"):
		lineage_seed_growth = float(data.get("lineage_seed_growth", LINEAGE_SEED_SAVE_FALLBACK))
	elif data.has("initial_total_growth"):
		lineage_seed_growth = float(data.get("initial_total_growth", LINEAGE_SEED_SAVE_FALLBACK))
	else:
		lineage_seed_growth = LINEAGE_SEED_SAVE_FALLBACK
	base_stats = data.get("base_stats", {"attack": 5.0, "defense": 5.0, "agility": 5.0, "hp": 30.0})
	stat_ratio = data.get("stat_ratio", {"attack": 33.33, "defense": 33.33, "agility": 33.34})
	capture_map = data.get("capture_map", "")
	is_elite = data.get("is_elite", false)
	form = _normalize_form_text(str(data.get("form", FORM_JUVENILE)))
	generation = data.get("generation", 0)
	var lk_raw: Variant = false
	if data.has("locked"):
		lk_raw = data.get("locked")
	elif data.has("isLocked"):
		lk_raw = data.get("isLocked")
	locked = _coerce_locked_from_save(lk_raw)
	var race_raw: Variant = false
	if data.has("pet_raise_race_used"):
		race_raw = data.get("pet_raise_race_used")
	elif data.has("petRaiseRaceUsed"):
		race_raw = data.get("petRaiseRaceUsed")
	pet_raise_race_used = _coerce_locked_from_save(race_raw)
	var loaded_medals = data.get("medal_counts", {})
	if loaded_medals is Dictionary:
		var mc: Dictionary = loaded_medals
		medal_counts = {
			"brave": clamp(maxi(int(mc.get("brave", 0)), int(mc.get("yongmeng", 0))), 0, 5), 
			"calm": clamp(maxi(int(mc.get("calm", 0)), int(mc.get("lengjing", 0))), 0, 5), 
			"bold": clamp(maxi(int(mc.get("bold", 0)), int(mc.get("guogan", 0))), 0, 5)
		}
	else:
		medal_counts = {"brave": 0, "calm": 0, "bold": 0}
	pending_medal_sync = bool(data.get("pending_medal_sync", false))
	pending_medal_sync_reason = str(data.get("pending_medal_sync_reason", ""))
	pending_skill_learn_sync = bool(data.get("pending_skill_learn_sync", false))
	pending_skill_learn_prev_level = maxi(0, int(data.get("pending_skill_learn_prev_level", 0)))
	last_max_level_skill_learn_cap = maxi(0, int(data.get("last_max_level_skill_learn_cap", 0)))
	last_max_level_medal_cap = maxi(0, int(data.get("last_max_level_medal_cap", 0)))
	skill_slots = data.get("skill_slots", _build_empty_skill_slots())
	normalize_skill_slots()
	evolution_stage = data.get("evolution_stage", 0)
	is_mutant = data.get("is_mutant", false)
	mutation_count = clampi(int(data.get("mutation_count", 0)), 0, 2)
	is_evolution_pet = EvolutionDataClass.is_evolution_pet(pet_id)
	evolution_origin = data.get("evolution_origin", "")
	if is_evolution_pet and evolution_origin.is_empty():
		evolution_origin = EvolutionDataClass.get_evolution_origin(pet_id)

	reincarnation_count = maxi(0, int(data.get("reincarnation_count", 0)))
	sync_level_cap_metadata_from_species()
	if not is_evolution_pet:
		form = FORM_NON_EVOLVABLE
	elif form == FORM_NON_EVOLVABLE:
		form = FORM_JUVENILE

	clamp_level_to_effective_max()
