extends Node
class_name PetManager

const GameData = preload("res://scripts/game_data.gd")
const EvolutionDataClass = preload("res://scripts/evolution_data.gd")
const PetClass = preload("res://scripts/pet.gd")
const PetSkillConfig = preload("res://scripts/pet_skill_config.gd")

const GameManager = preload("res://scripts/game_manager.gd")
const VipBenefits = preload("res://scripts/vip_benefits.gd")


var pets = []
var active_pet = null


var _saved_active_id: = ""
var max_pets: int = GameData.MAX_PETS


var pet_bag = []
var max_pet_bag: int = GameData.MAX_PET_BAG

var assist_pets: Array = []
const MAX_ASSIST_SLOTS: = 10


signal pet_added(pet)
signal pet_removed(pet)
signal active_pet_changed(pet)
signal pet_list_changed
signal pet_leveled_up(pet, old_level: int, new_level: int)
signal pet_evolved(pet, old_form: String, new_form: String)
signal pet_merged(new_pet, main_pet, sub_pet, result_type: String)


const EVOLUTION_FORMS = ["幼年", "一进", "二进", "终极"]
const EVOLUTION_INITIAL_GROWTH_COEFF: float = 0.25



const MERGE_TYPES = {
	"A": {"name": "Perfect Inheritance", "weight": 5, "poem": "Two spirits merge into one flawless legacy."}, 
	"B": {"name": "Excellent Inheritance", "weight": 15, "poem": "Fortune blesses this bloodline with stable growth."}, 
	"C": {"name": "Normal Inheritance", "weight": 30, "poem": "A balanced fusion opens a new path."}, 
	"D": {"name": "Average Inheritance", "weight": 50, "poem": "Steady inheritance, modest but reliable."}
}


const PET_REFINE_GOLD_COST = 10000000

const MEDAL_MAX_PER_TYPE = 5
const MEDAL_TYPES = ["brave", "calm", "bold"]
const MEDAL_DISPLAY_NAMES = {
	"brave": "勇气勋章", 
	"calm": "冷静勋章", 
	"bold": "无畏勋章"
}


func create_initial_pet():

	var starter_pet_id: = "kǔxínggūi"
	var kuxinggui_data = GameData.PET_DATA.get(starter_pet_id)
	if kuxinggui_data:
		var pet = load("res://scripts/pet.gd").create_from_data(kuxinggui_data, "starter", true, starter_pet_id)
		pet.is_elite = true
		add_pet(pet)
		_apply_active_pet(pet)
		return pet
	return null


func bootstrap_starter_pet_if_needed() -> void :
	if pets.size() > 0 or pet_bag.size() > 0:
		return
	var gm = GameManager.instance
	if gm != null and gm.network != null and gm.network.is_logged_in():
		gm.call_deferred("_bootstrap_starter_pet_async")
		return
	create_initial_pet()


func add_pet(pet) -> bool:
	if pets.size() >= max_pets:
		return false

	pets.append(pet)
	add_child(pet)
	pet_added.emit(pet)
	pet_list_changed.emit()
	if GameManager.instance:
		GameManager.instance.block_battle_start_temporarily(GameManager.BATTLE_START_BLOCK_ROSTER_REFRESH_MS, "pet_add")
	return true


func try_adopt_server_granted_pet(pet) -> bool:
	if pet == null:
		return false
	if pets.size() < max_pets:
		return add_pet(pet)
	# 主战栏满了就到此为止，**不要再往宠物袋里塞**。
	# 宠物袋是玩家手动存暂存宠的仓库；自动兜底塞袋的结果是挂机一晚上袋里堆满
	# 十几只 Lv.1 野生宠（玩家看到的「宠物袋里多了很多宠物」就是它）。
	# 服务端 `/pet/roster/sync` 与捕捉接口现在也会保证主战栏 ≤ 10、
	# 满员时按参考稿口径放生/邮件补发，这边保持同口径即可。
	push_warning("[PetManager] 主战栏已满（%d/%d），服务端发放的宠物未注入" % [pets.size(), max_pets])
	return false


func inject_server_granted_pet_from_dict(pet_dict: Dictionary) -> bool:
	if pet_dict.is_empty():
		return false
	var instance_id: = str(pet_dict.get("id", "")).strip_edges()
	if not instance_id.is_empty():
		for p in pets:
			if p and str(p.id) == instance_id:
				return true
		for p in pet_bag:
			if p and str(p.id) == instance_id:
				return true
	var pet = load("res://scripts/pet.gd").new()
	pet.from_dict(pet_dict)
	return try_adopt_server_granted_pet(pet)

func remove_pet(pet) -> Dictionary:
	var result = {"success": false, "message": ""}
	if pet == null:
		result.message = "宠物不存在"
		return result
	return remove_pet_by_id(str(pet.id))

func remove_pet_by_id(pet_id: String) -> Dictionary:
	var result = {"success": false, "message": ""}
	if GameManager.instance:
		GameManager.instance.block_battle_start_temporarily(GameManager.BATTLE_START_BLOCK_ROSTER_REFRESH_MS, "pet_remove_begin")
	var stable_id: = str(pet_id).strip_edges()
	if stable_id.is_empty():
		result.message = "宠物不存在"
		return result

	if pets.size() + pet_bag.size() <= 1:
		result.message = "至少需要保留一只宠物"
		return result

	var pet = null
	var from_bag: = false
	for p in pets:
		if str(p.id) == stable_id:
			pet = p
			break
	if pet == null:
		for p in pet_bag:
			if p and str(p.id) == stable_id:
				pet = p
				from_bag = true
				break
	if pet == null:
		result.message = "宠物不存在"
		return result

	if pet.locked:
		result.message = "该宠物已锁定，无法放生"
		return result

	var was_active = active_pet != null and str(active_pet.id) == stable_id
	if from_bag:
		pet_bag.erase(pet)
	else:
		pets.erase(pet)
	if pet.get_parent() == self:
		remove_child(pet)
	if not from_bag:
		if was_active and pets.size() > 0:
			active_pet = pets[0]
			active_pet_changed.emit(active_pet)
		elif was_active:
			active_pet = null

	pet_removed.emit(pet)
	pet_list_changed.emit()

	result.success = true
	result.message = "已放生 %s" % pet.pet_name
	return result


func batch_release_unlocked() -> Dictionary:
	var result = {"success": false, "released": [], "message": ""}
	var to_release = []

	for pet in pets:
		if not pet.locked and pet != active_pet:
			to_release.append(pet)

	if to_release.is_empty():
		result.message = "没有可放生的未锁定宠物（出战宠物除外）"
		return result

	for pet in to_release:
		pets.erase(pet)
		remove_child(pet)
		result.released.append(pet.pet_name)

	pet_list_changed.emit()

	result.success = true
	result.message = "已放生 %d 只宠物：%s" % [to_release.size(), ", ".join(result.released)]
	return result

func toggle_pet_lock(pet) -> Dictionary:
	var result = {"success": false, "message": ""}

	if pet == null:
		result.message = "未找到该宠物"
		return result
	if not pets.has(pet) and not pet_bag.has(pet):
		result.message = "未找到该宠物"
		return result

	pet.locked = not pet.locked
	pet_list_changed.emit()
	result.success = true
	result.message = "%s %s" % ["已锁定" if pet.locked else "已解锁", pet.pet_name]
	return result


func capture_from_monster(monster: Dictionary, map_name: String, min_growth: float = 0.0) -> Dictionary:
	var result = {"success": false, "pet": null, "message": ""}

	if GameManager.instance and GameManager.instance.is_five_elements_battle:
		result.message = "五行副本中无法捕捉宠物"
		return result

	var pet_id = monster.get("pet_id", "")
	var pet_info = {}

	if not pet_id.is_empty():
		pet_info = GameData.PET_DATA.get(pet_id, {})
	else:
		var monster_name = monster.get("name", "")
		pet_info = _find_pet_by_name(monster_name)

	if not pet_info:
		result.message = "%s 无法被捕捉" % monster.get("name", "未知怪物")
		return result

	if is_event_limited_pet_id(pet_id, pet_info):
		result.message = "%s 是活动限定宠物，无法通过捕捉获得" % pet_info.get("name", "未知怪物")
		return result

	if randi() % 100 >= 10:
		result.message = "捕捉失败，宠物逃跑了"
		return result

	var is_elite_chance = 5
	if GameManager.instance and GameManager.instance.player:
		if VipBenefits.is_vip_active(GameManager.instance.player):
			is_elite_chance = 10
	var is_elite = randi() % 1000 < is_elite_chance
	var pet = load("res://scripts/pet.gd").create_from_data(pet_info, map_name, is_elite, pet_id)

	if pet.total_growth < min_growth:
		var collection_manager = GameManager.instance.pet_collection_manager if GameManager.instance else null
		if collection_manager and collection_manager.can_activate(pet.pet_id):
			var collection_result = collection_manager.activate_collection(pet.pet_id, pet)
			if collection_result.success:
				result.success = true
				result.message = "%s 成长值 %.3f 低于 %.3f，已加入图鉴" % [pet.pet_name, pet.total_growth, min_growth]
			else:
				result.message = "%s 成长值 %.3f 低于标准且图鉴已满" % [pet.pet_name, pet.total_growth]
		else:
			result.message = "%s 成长值 %.3f 低于 %.3f，已丢弃" % [pet.pet_name, pet.total_growth, min_growth]
		return result

	if pets.size() >= max_pets:
		result.message = "宠物栏已满，已放生"
		return result

	if add_pet(pet):
		result.success = true
		result.pet = pet
		result.message = "成功捕捉 %s！成长值 %.3f%s" % [pet.pet_name, pet.total_growth, " [精英]" if is_elite else ""]
	else:
		result.message = "捕捉失败"

	return result

func _find_pet_by_name(pet_name: String) -> Dictionary:
	for pet_id in GameData.PET_DATA:
		var pet_data = GameData.PET_DATA[pet_id]
		if pet_data.get("name", "") == pet_name:
			return pet_data
	return {}


func set_active_pet(pet) -> bool:
	if pet == null:
		return false
	return set_active_pet_by_id(str(pet.id))

func set_active_pet_by_id(stable_id: String) -> bool:
	var want: = str(stable_id).strip_edges()
	if want.is_empty():
		return false
	var pet = get_pet_by_stable_id(want)
	if pet == null:
		return false
	if not pets.has(pet):
		return false
	if GameManager.instance and GameManager.instance.has_method("is_in_instanced_challenge") and GameManager.instance.is_in_instanced_challenge():
		return false
	if GameManager.instance and GameManager.instance.has_method("is_active_pet_pending_cloud_sync") and GameManager.instance.is_active_pet_pending_cloud_sync():
		return false
	if not _apply_active_pet(pet):
		return false
	if GameManager.instance and GameManager.instance.has_method("sync_active_pet_switch_to_cloud"):
		GameManager.instance.sync_active_pet_switch_to_cloud()
	return true

func _apply_active_pet(pet) -> bool:
	if not pets.has(pet):
		return false
	active_pet = pet
	save_active_id()
	active_pet_changed.emit(pet)
	if GameManager.instance:
		GameManager.instance.block_battle_start_temporarily(GameManager.BATTLE_START_BLOCK_ROSTER_REFRESH_MS, "set_active_pet")
		if GameManager.instance.has_method("reset_field_battle_pet_level_anchor_on_switch"):
			GameManager.instance.reset_field_battle_pet_level_anchor_on_switch()
	return true

func get_active_pet():
	return active_pet



func save_active_id() -> void :
	if active_pet != null:
		_saved_active_id = active_pet.id
		print_debug("[PetManager] Cached active pet ID: " + _saved_active_id)

func clear_saved_active_id() -> void :
	_saved_active_id = ""

func get_saved_active_id() -> String:
	return _saved_active_id

func discard_saved_active_id() -> void :
	_saved_active_id = ""

func switch_active_pet(index: int) -> bool:
	if index < 0 or index >= pets.size():
		return false
	return set_active_pet(pets[index])


func add_pet_exp(pet, experience: int, allow_multiple_levels: bool = true, max_level_ups: int = 1) -> Dictionary:
	var result = {"leveled_up": false, "messages": [], "level_ups": 0}

	if not pets.has(pet):
		return result

	result.messages.append("%s 获得 [color=cyan]%d[/color] 点经验" % [pet.pet_name, experience])
	pet.experience += experience

	if allow_multiple_levels:

		while pet.level < pet.get_effective_max_level() and pet.experience >= _get_pet_max_exp(pet.level):
			pet.experience -= _get_pet_max_exp(pet.level)
			var old_level = pet.level
			pet.level += 1
			result.level_ups += 1

			var total_growth_change = _roll_level_growth_delta_for_pet(pet)
			var stat_ratio = pet.stat_ratio

			for stat in ["attack", "defense", "agility"]:
				var stat_change = total_growth_change * (stat_ratio.get(stat, 33.33) / 100.0)
				pet.growth_rates[stat] = snapped(pet.growth_rates[stat] + stat_change, 0.001)

			pet.total_growth = snapped(pet.growth_rates["attack"] + pet.growth_rates["defense"] + pet.growth_rates["agility"], 0.001)


			_update_pet_stats(pet)

			result.messages.append("成长 %+0.3f" % total_growth_change)
			var max_level_reward_message: = grant_max_level_medal_if_needed(pet, old_level)
			if not max_level_reward_message.is_empty():
				result.messages.append(max_level_reward_message)
			pet_leveled_up.emit(pet, old_level, pet.level)
			pet_list_changed.emit()
	else:

		var field_cap: = clampi(max_level_ups, 1, 10)
		while pet.level < pet.get_effective_max_level() and pet.experience >= _get_pet_max_exp(pet.level) and result.level_ups < field_cap:
			pet.experience -= _get_pet_max_exp(pet.level)
			var old_level = pet.level
			pet.level += 1
			result.level_ups += 1
			var total_growth_change = _roll_level_growth_delta_for_pet(pet)
			var stat_ratio = pet.stat_ratio
			for stat in ["attack", "defense", "agility"]:
				var stat_change = total_growth_change * (stat_ratio.get(stat, 33.33) / 100.0)
				pet.growth_rates[stat] = snapped(pet.growth_rates[stat] + stat_change, 0.001)
			pet.total_growth = snapped(pet.growth_rates["attack"] + pet.growth_rates["defense"] + pet.growth_rates["agility"], 0.001)
			_update_pet_stats(pet)
			result.messages.append("成长 %+0.3f" % total_growth_change)
			var max_level_reward_message_single: = grant_max_level_medal_if_needed(pet, old_level)
			if not max_level_reward_message_single.is_empty():
				result.messages.append(max_level_reward_message_single)
			pet_leveled_up.emit(pet, old_level, pet.level)
			pet_list_changed.emit()
		if result.level_ups > 0:
			pet.experience = 0
		else:
			var req: = _get_pet_max_exp(pet.level)
			var cap: = maxi(0, req - 1)
			if pet.experience > cap:
				pet.experience = cap

	result.leveled_up = result.level_ups > 0
	pet.clamp_experience_if_max_level()
	return result


func debug_level_up_pet_fast(pet, levels: int) -> Dictionary:
	var result = {"leveled_up": false, "messages": [], "level_ups": 0}
	if pet == null or not pets.has(pet):
		return result
	if levels <= 0:
		return result

	var target_level = min(pet.get_effective_max_level(), pet.level + levels)
	if target_level <= pet.level:
		return result

	var old_level = pet.level
	while pet.level < target_level:
		pet.level += 1
		result.level_ups += 1

		var total_growth_change = _roll_level_growth_delta_for_pet(pet)
		var stat_ratio = pet.stat_ratio

		for stat in ["attack", "defense", "agility"]:
			var stat_change = total_growth_change * (stat_ratio.get(stat, 33.33) / 100.0)
			pet.growth_rates[stat] = snapped(pet.growth_rates[stat] + stat_change, 0.001)


	_update_pet_stats(pet)
	pet.experience = 0

	var max_level_reward_message: = grant_max_level_medal_if_needed(pet, old_level)
	if not max_level_reward_message.is_empty():
		result.messages.append(max_level_reward_message)

	result.leveled_up = result.level_ups > 0
	if result.leveled_up:
		pet_leveled_up.emit(pet, old_level, pet.level)
	pet.clamp_experience_if_max_level()
	return result

static func sum_medal_counts_for_pet(pet) -> int:
	if pet == null:
		return 0
	var mc: Dictionary = {}
	if pet is Dictionary:
		var raw: Variant = pet.get("medal_counts", {})
		mc = raw if raw is Dictionary else {}
	elif pet.medal_counts is Dictionary:
		mc = pet.medal_counts
	return int(mc.get("brave", 0)) + int(mc.get("calm", 0)) + int(mc.get("bold", 0))

func grant_max_level_medal_if_needed(pet, old_level: int) -> String:
	queue_max_level_skill_learn_if_needed(pet, old_level)
	if pet == null:
		return ""
	if int(pet.reincarnation_count) > 0:
		return ""
	var effective_max: = int(pet.get_effective_max_level())
	if old_level >= effective_max:
		return ""
	if int(pet.level) < effective_max:
		return ""

	if "last_max_level_medal_cap" in pet and int(pet.last_max_level_medal_cap) >= effective_max:
		return ""
	var medal_type = _grant_random_medal(pet)
	if not medal_type.is_empty():
		if "last_max_level_medal_cap" in pet:
			pet.last_max_level_medal_cap = effective_max
		_queue_pet_medal_sync(pet, "max_level_reward")
		return "满级奖励：%s" % MEDAL_DISPLAY_NAMES.get(medal_type, "勋章")
	return "满级奖励：勋章槽已满"

func _is_pet_skill_feature_enabled() -> bool:
	var gm = GameManager.instance
	if gm == null or not (gm.gameplay_runtime_config is Dictionary):
		return false
	var learn_cfg: Variant = gm.gameplay_runtime_config.get("petSkillLearn", {})
	if learn_cfg is Dictionary and learn_cfg.has("featureEnabled"):
		return bool(learn_cfg.get("featureEnabled", false))
	var slot_cfg: Variant = gm.gameplay_runtime_config.get("petSkillSlots", {})
	if slot_cfg is Dictionary:
		return bool(slot_cfg.get("featureEnabled", false))
	return false

func _is_max_level_learn_enabled() -> bool:
	var gm = GameManager.instance
	if gm == null or not (gm.gameplay_runtime_config is Dictionary):
		return false
	var learn_cfg: Variant = gm.gameplay_runtime_config.get("petSkillLearn", {})
	if learn_cfg is Dictionary:
		return bool(learn_cfg.get("maxLevelLearnEnabled", false))
	return false


func _get_configured_max_skill_level() -> int:
	var cap: = 3
	var gm = GameManager.instance
	if gm != null and gm.gameplay_runtime_config is Dictionary:
		var learn_cfg: Variant = gm.gameplay_runtime_config.get("petSkillLearn", {})
		if learn_cfg is Dictionary:
			cap = int((learn_cfg as Dictionary).get("maxSkillLevel", 3))
	return clampi(cap, 1, 5)

func queue_max_level_skill_learn_if_needed(pet, old_level: int) -> void :
	if pet == null:
		return
	if not _is_max_level_learn_enabled():
		return
	var cap: = int(pet.get_effective_max_level())
	if old_level >= cap:
		return
	if int(pet.level) < cap:
		return
	if int(pet.last_max_level_skill_learn_cap) >= cap:
		return
	pet.pending_skill_learn_sync = true
	pet.pending_skill_learn_prev_level = old_level

	flush_pending_pet_skill_learn_syncs()


func _send_pet_max_level_learn_to_server(pet) -> bool:
	if pet == null:
		return false
	if GameManager.instance == null or GameManager.instance.network == null:
		return false
	var network = GameManager.instance.network
	if not network.has_method("is_logged_in") or not network.is_logged_in():
		return false
	if not network.has_method("request_pet_max_level_learn"):
		return false
	var stable_pet_id: = str(pet.id).strip_edges()
	if stable_pet_id.is_empty():
		return false
	var operation_id: = "pet_max_level_learn_%s_%s" % [str(Time.get_unix_time_from_system()), str(randi())]
	var prev_lv: = int(pet.pending_skill_learn_prev_level)
	var pet_level: = int(pet.level) if "level" in pet else -1
	var sent: Variant = network.request_pet_max_level_learn(operation_id, stable_pet_id, prev_lv, pet_level)
	return bool(sent)


func flush_pending_pet_skill_learn_syncs() -> int:
	if GameManager.instance == null or GameManager.instance.network == null:
		return 0
	var network = GameManager.instance.network
	if not network.has_method("is_logged_in") or not network.is_logged_in():
		return 0
	if not _is_max_level_learn_enabled():
		return 0
	var all_pets: Array = []
	all_pets.append_array(pets)
	all_pets.append_array(pet_bag)
	for ap in assist_pets:
		if ap != null:
			all_pets.append(ap)
	for pet in all_pets:
		if pet == null:
			continue
		if not ("pending_skill_learn_sync" in pet) or not bool(pet.pending_skill_learn_sync):
			continue
		if _send_pet_max_level_learn_to_server(pet):
			pet.pending_skill_learn_sync = false
			return 1

		return 0
	return 0


func snapshot_pending_skill_learn_syncs() -> Array:
	var out: Array = []
	var all_pets: Array = []
	all_pets.append_array(pets)
	all_pets.append_array(pet_bag)
	for ap in assist_pets:
		if ap != null:
			all_pets.append(ap)
	for pet in all_pets:
		if pet == null:
			continue
		if not ("pending_skill_learn_sync" in pet) or not bool(pet.pending_skill_learn_sync):
			continue
		var pid: = str(pet.id).strip_edges()
		if pid.is_empty():
			continue
		out.append({
			"id": pid, 
			"prev": int(pet.pending_skill_learn_prev_level) if "pending_skill_learn_prev_level" in pet else 0, 
		})
	return out

func restore_pending_skill_learn_syncs(rows: Array) -> void :
	if rows.is_empty():
		return
	var by_id: Dictionary = {}
	for row in rows:
		if not (row is Dictionary):
			continue
		var pid: = str(row.get("id", "")).strip_edges()
		if pid.is_empty():
			continue
		by_id[pid] = int(row.get("prev", 0))
	if by_id.is_empty():
		return
	var all_pets: Array = []
	all_pets.append_array(pets)
	all_pets.append_array(pet_bag)
	for ap in assist_pets:
		if ap != null:
			all_pets.append(ap)
	for pet in all_pets:
		if pet == null:
			continue
		var pid: = str(pet.id).strip_edges()
		if not by_id.has(pid):
			continue
		var cap: = int(pet.get_effective_max_level()) if pet.has_method("get_effective_max_level") else 0
		if cap > 0 and int(pet.last_max_level_skill_learn_cap) >= cap:
			pet.pending_skill_learn_sync = false
			continue
		pet.pending_skill_learn_sync = true
		pet.pending_skill_learn_prev_level = int(by_id[pid])

func _queue_pet_medal_sync(pet, reason: String = "") -> void :
	if pet == null:
		return
	if not (pet.medal_counts is Dictionary):
		pet.medal_counts = {}
	if "pending_medal_sync" in pet:
		pet.pending_medal_sync = true
	if "pending_medal_sync_reason" in pet:
		pet.pending_medal_sync_reason = reason

func _send_pet_medal_counts_to_server(pet, reason: String = "") -> void :
	if pet == null:
		return
	if not (pet.medal_counts is Dictionary):
		pet.medal_counts = {}
	if GameManager.instance == null or GameManager.instance.network == null:
		return
	var network = GameManager.instance.network
	if not network.has_method("is_logged_in") or not network.is_logged_in():
		return
	if not network.has_method("request_pet_grant_medal"):
		return
	var stable_pet_id: = str(pet.id).strip_edges()
	if stable_pet_id.is_empty():
		return
	var sync_reason: = reason.strip_edges()
	if sync_reason.is_empty():
		sync_reason = "pending_sync"
	var operation_id: = "pet_grant_medal_%s_%s_%s" % [sync_reason, str(Time.get_unix_time_from_system()), str(randi())]
	var medal_counts: Dictionary = pet.medal_counts.duplicate(true) if pet.medal_counts is Dictionary else {}
	var pet_level: = int(pet.level) if "level" in pet else -1
	network.request_pet_grant_medal(operation_id, stable_pet_id, medal_counts, sync_reason, pet_level)
	if OS.is_debug_build():
		print("[PetManager] send pet medal sync pet=", stable_pet_id, " reason=", sync_reason, " level=", pet_level, " counts=", medal_counts)

func flush_pending_pet_medal_syncs(reason_filter: String = "") -> int:
	if GameManager.instance == null or GameManager.instance.network == null:
		return 0
	var network = GameManager.instance.network
	if not network.has_method("is_logged_in") or not network.is_logged_in():
		return 0
	var flushed: = 0
	var all_pets: Array = []
	all_pets.append_array(pets)
	all_pets.append_array(pet_bag)
	for ap in assist_pets:
		if ap != null:
			all_pets.append(ap)
	for pet in all_pets:
		if pet == null:
			continue
		if not ("pending_medal_sync" in pet) or not bool(pet.pending_medal_sync):
			continue
		var pending_reason: = str(pet.pending_medal_sync_reason).strip_edges()
		if not reason_filter.is_empty() and pending_reason != reason_filter:
			continue
		_send_pet_medal_counts_to_server(pet, pending_reason if not pending_reason.is_empty() else "pending_sync")
		if "pending_medal_sync" in pet:
			pet.pending_medal_sync = false
		if "pending_medal_sync_reason" in pet:
			pet.pending_medal_sync_reason = ""
		flushed += 1
	flush_pending_pet_skill_learn_syncs()
	return flushed

func _get_pet_max_exp(level: int) -> int:
	return GameData.get_pet_required_exp(level)

func _update_pet_stats(pet):
	var base = pet.base_stats
	var growth = pet.growth_rates
	var level_diff = pet.level - 1
	# 礼包直发的一类宠（琳琳等）没有 growth_rates，缺键时按 0 处理，
	# 绝不能直接 growth["attack"] —— 会 KeyError 把宠物面板打断。
	var g_atk: float = float(growth.get("attack", 0.0))
	var g_def: float = float(growth.get("defense", 0.0))
	var g_agi: float = float(growth.get("agility", 0.0))
	if is_zero_approx(g_atk) and is_zero_approx(g_def) and is_zero_approx(g_agi):
		return

	var _old_pet_hp_cap: float = pet.get_final_max_hp_with_equipment()
	pet.attack = snapped(base["attack"] + g_atk * level_diff, 0.01)
	pet.defense = snapped(base["defense"] + g_def * level_diff, 0.01)
	pet.agility = snapped(base["agility"] + g_agi * level_diff, 0.01)
	pet.total_growth = snapped(g_atk + g_def + g_agi, 0.001)
	# 生命成长按物种 hp_growth 走（参考稿口径）。旧代码拿 total_growth 当血成长，
	# 面板上「生命成长 6.0」从来不参与计算。
	pet.growth_rates["hp"] = PetClass.resolve_hp_growth(str(pet.pet_id), pet.total_growth)
	pet.max_hp = snapped(base["hp"] + float(pet.growth_rates["hp"]) * level_diff, 0.01)
	var _new_pet_hp_cap: float = pet.get_final_max_hp_with_equipment()
	if _old_pet_hp_cap <= 0.0001:
		pet.hp = _new_pet_hp_cap
	else:
		var _ratio: = clampf(float(pet.hp) / _old_pet_hp_cap, 0.0, 1.0)
		pet.hp = clampf(_new_pet_hp_cap * _ratio, 0.0, _new_pet_hp_cap)
	_heal_pet_full_if_out_of_battle(pet)

func _heal_pet_full_if_out_of_battle(pet) -> void :
	if pet == null or not pet.has_method("heal_full"):
		return
	var gm = GameManager.instance
	if gm != null and bool(gm.in_battle):
		return
	pet.heal_full()

func _get_lineage_seed_growth(pet) -> float:
	if pet == null:
		return PetClass.LINEAGE_SEED_SAVE_FALLBACK
	if pet is Dictionary:
		return PetClass.ensure_lineage_seed_growth_dictionary(pet)
	return float(pet.lineage_seed_growth)

func _get_pet_mutation_count(pet) -> int:
	if pet == null:
		return 0
	if pet is Dictionary:
		return clampi(int(pet.get("mutation_count", 0)), 0, 2)
	return clampi(int(pet.mutation_count), 0, 2)

func _get_pet_is_evolution(pet) -> bool:
	if pet == null:
		return false
	if pet is Dictionary:
		var species_id: = str(pet.get("pet_id", "")).strip_edges()
		if not species_id.is_empty() and EvolutionDataClass.is_evolution_pet(species_id):
			return true
		return bool(pet.get("is_evolution_pet", false))
	if pet.has_method("resolve_is_on_evolution_chain"):
		return bool(pet.resolve_is_on_evolution_chain())
	return bool(pet.is_evolution_pet)

func _roll_level_growth_delta_for_pet(pet) -> float:
	var generation: = 0
	if pet is Dictionary:
		generation = int(pet.get("generation", 0))
	elif pet != null:
		generation = int(pet.generation)
	return PetClass.roll_level_total_growth_delta(
		generation, 
		_get_lineage_seed_growth(pet), 
		_get_pet_mutation_count(pet), 
		_get_pet_is_evolution(pet)
	)

static func _resolve_pet_dict_level_cap(pet: Dictionary) -> Dictionary:
	var species_id: = str(pet.get("pet_id", "")).strip_edges()
	var is_evo: = bool(pet.get("is_evolution_pet", false))
	if not species_id.is_empty() and EvolutionDataClass.is_evolution_pet(species_id):
		is_evo = true
	var base_max: = GameData.MAX_LEVEL_EVOLUTION if is_evo else GameData.MAX_LEVEL_NORMAL
	var rei_count: = int(pet.get("reincarnation_count", 0))
	var rei_bonus: = (rei_count / 10) * (50 if is_evo else 100)
	return {
		"is_evo": is_evo, 
		"base_max": base_max, 
		"effective_max": base_max + rei_bonus, 
	}

static func _apply_pet_dict_level_cap_metadata(pet: Dictionary) -> void :
	if pet == null or not pet is Dictionary:
		return
	var cap_info: = _resolve_pet_dict_level_cap(pet)
	pet["is_evolution_pet"] = cap_info.is_evo
	pet["max_level"] = cap_info.base_max
	var eff_max: = int(cap_info.effective_max)
	if int(pet.get("level", 1)) > eff_max:
		pet["level"] = eff_max
		pet["experience"] = 0
		pet["exp"] = 0


static func apply_offline_exp_to_pet_dictionary(pet: Dictionary, grant_exp: int) -> void :
	if pet == null or not pet is Dictionary:
		return
	var ge: = maxi(0, grant_exp)
	if ge <= 0:
		return
	var pet_level: = int(pet.get("level", 1))
	var pet_exp: = int(pet.get("experience", pet.get("exp", 0)))
	var pet_total_exp: = pet_exp + ge
	var species_id: = str(pet.get("pet_id", "")).strip_edges()
	var is_evolution_pet: = bool(pet.get("is_evolution_pet", false))
	if not species_id.is_empty() and EvolutionDataClass.is_evolution_pet(species_id):
		is_evolution_pet = true
	var pet_max_level: = GameData.MAX_LEVEL_EVOLUTION if is_evolution_pet else GameData.MAX_LEVEL_NORMAL

	var _rei_count: = int(pet.get("reincarnation_count", 0))
	var _rei_bonus: = (_rei_count / 10) * (50 if is_evolution_pet else 100)
	pet_max_level += _rei_bonus
	var gr_raw: Variant = pet.get("growth_rates", {"attack": 0.0, "defense": 0.0, "agility": 0.0, "hp": 0.0})
	var growth_rates: Dictionary
	if gr_raw is Dictionary:
		growth_rates = (gr_raw as Dictionary).duplicate(true)
	else:
		growth_rates = {"attack": 0.0, "defense": 0.0, "agility": 0.0, "hp": 0.0}
	var stat_ratio: Dictionary = pet.get("stat_ratio", {"attack": 33.33, "defense": 33.33, "agility": 33.34})
	var old_level: = pet_level
	while pet_level < pet_max_level:
		var pet_required: int = GameData.get_pet_required_exp(pet_level)
		if pet_total_exp < pet_required:
			break
		pet_total_exp -= pet_required
		pet_level += 1
		var lineage_seed: float = PetClass.ensure_lineage_seed_growth_dictionary(pet)
		var mut_count: = clampi(int(pet.get("mutation_count", 0)), 0, 2)
		var level_growth_change: float = PetClass.roll_level_total_growth_delta(
			int(pet.get("generation", 0)), 
			lineage_seed, 
			mut_count, 
			is_evolution_pet
		)
		for stat in ["attack", "defense", "agility"]:
			var stat_change: float = level_growth_change * (float(stat_ratio.get(stat, 33.33)) / 100.0)
			growth_rates[stat] = snapped(float(growth_rates.get(stat, 0.0)) + stat_change, 0.001)
	var total_growth: float = snapped(float(growth_rates["attack"]) + float(growth_rates["defense"]) + float(growth_rates["agility"]), 0.001)
	# 以前这里写死 growth_rates["hp"] = total_growth，正是把「生命成长」这一栏抹掉、
	# 并把错误值写进存档的元凶。现在按物种 hp_growth 比例重算。
	growth_rates["hp"] = PetClass.resolve_hp_growth(str(pet.get("pet_id", "")), total_growth)
	pet["level"] = pet_level
	pet["experience"] = pet_total_exp
	pet["growth_rates"] = growth_rates
	pet["total_growth"] = total_growth
	pet["is_evolution_pet"] = is_evolution_pet
	pet["max_level"] = GameData.MAX_LEVEL_EVOLUTION if is_evolution_pet else GameData.MAX_LEVEL_NORMAL
	var base_stats: Dictionary = pet.get("base_stats", {"attack": 5.0, "defense": 5.0, "agility": 5.0, "hp": 30.0})
	var level_diff: int = pet_level - 1
	pet["attack"] = snapped(float(base_stats.get("attack", 5.0)) + float(growth_rates["attack"]) * level_diff, 0.01)
	pet["defense"] = snapped(float(base_stats.get("defense", 5.0)) + float(growth_rates["defense"]) * level_diff, 0.01)
	pet["agility"] = snapped(float(base_stats.get("agility", 5.0)) + float(growth_rates["agility"]) * level_diff, 0.01)
	pet["max_hp"] = snapped(float(base_stats.get("hp", 30.0)) + float(growth_rates["hp"]) * level_diff, 0.01)
	pet["hp"] = pet["max_hp"]
	_apply_pet_dict_level_cap_metadata(pet)
	_grant_offline_max_level_medal_for_pet_dict(pet, old_level, pet_max_level)

static func _grant_offline_max_level_medal_for_pet_dict(pet_data: Dictionary, old_level: int, pet_max_level: int) -> void :
	if int(pet_data.get("reincarnation_count", 0)) > 0:
		return
	if old_level >= pet_max_level:
		return
	if int(pet_data.get("level", 1)) < pet_max_level:
		return
	if int(pet_data.get("last_max_level_medal_cap", 0)) >= pet_max_level:
		return
	var medal_counts: Dictionary = pet_data.get("medal_counts", {})
	var medal_types: = ["brave", "calm", "bold"]
	var available_types: Array = []
	for medal_type in medal_types:
		if int(medal_counts.get(medal_type, 0)) < 5:
			available_types.append(medal_type)
	if available_types.is_empty():
		pet_data["medal_counts"] = medal_counts
		return
	var selected_type: String = available_types[randi() % available_types.size()]
	medal_counts[selected_type] = int(medal_counts.get(selected_type, 0)) + 1
	pet_data["medal_counts"] = medal_counts
	pet_data["last_max_level_medal_cap"] = pet_max_level
	pet_data["pending_medal_sync"] = true
	pet_data["pending_medal_sync_reason"] = "offline_max_level_reward"



func _resolve_evolution_stage_index_from_pet(pet, chain: Array) -> int:
	if pet == null or chain.is_empty():
		return maxi(0, int(pet.evolution_stage) if pet else 0)
	var candidates: Array[int] = []
	var raw_stage: = int(pet.evolution_stage)
	if raw_stage >= 0:
		candidates.append(raw_stage)
	var pid_stage: = EvolutionDataClass.get_evolution_stage(str(pet.pet_id), chain)
	if pid_stage >= 0:
		candidates.append(pid_stage)
	var form_str: = str(pet.form).strip_edges()
	var form_idx: = EVOLUTION_FORMS.find(form_str)
	if form_idx >= 0:
		candidates.append(form_idx)
	if candidates.is_empty():
		return clampi(raw_stage, 0, chain.size() - 1)
	var resolved: = 0
	for c in candidates:
		resolved = maxi(resolved, int(c))
	return clampi(resolved, 0, chain.size() - 1)


func _apply_evolution_chain_cap_metadata(pet) -> void :
	if pet == null:
		return
	if not EvolutionDataClass.is_evolution_pet(str(pet.pet_id)):
		return
	if pet.has_method("sync_level_cap_metadata_from_species"):
		pet.sync_level_cap_metadata_from_species()
	else:
		pet.is_evolution_pet = true
		pet.max_level = GameData.MAX_LEVEL_EVOLUTION
	if pet.has_method("clamp_level_to_effective_max"):
		pet.clamp_level_to_effective_max()


func _sync_evolution_pet_identity_from_stage(pet) -> void :
	if pet == null:
		return
	var raw_stage: = int(pet.evolution_stage)
	if raw_stage < 0:
		return
	var origin: = str(pet.evolution_origin).strip_edges()
	if origin.is_empty():
		origin = EvolutionDataClass.get_evolution_origin(pet.pet_id)
	if origin.is_empty():
		return
	var mc: = 0
	if "mutation_count" in pet:
		mc = int(pet.mutation_count)
	var chain: Array = EvolutionDataClass.get_evolution_chain_by_origin(origin, pet.is_mutant, mc)
	if chain.is_empty():
		return
	var stage: = _resolve_evolution_stage_index_from_pet(pet, chain)
	if stage > raw_stage:
		push_warning(
			"[PetManager] evolution_stage lifted id=%s raw=%d resolved=%d pet_id=%s form=%s"
			%[str(pet.id), raw_stage, stage, str(pet.pet_id), str(pet.form)]
		)
	pet.evolution_stage = stage
	var idx: int = stage
	var correct_id: String = str(chain[idx])
	var pdata: Dictionary = GameData.PET_DATA.get(correct_id, {})
	if pdata.is_empty():
		push_warning("[PetManager] Missing PET_DATA in evolution chain: ", correct_id)
		return

	if pet.pet_id == correct_id:
		var official: String = str(pdata.get("name", ""))
		if not official.is_empty():
			pet.original_name = official
			pet.pet_name = official
		pet.form = EVOLUTION_FORMS[idx]
		_apply_evolution_chain_cap_metadata(pet)
		return

	pet.pet_id = correct_id
	pet.evolution_origin = origin
	pet.is_evolution_pet = true
	pet.max_level = GameData.MAX_LEVEL_EVOLUTION
	pet.form = EVOLUTION_FORMS[idx]
	var official: String = str(pdata.get("name", ""))
	if not official.is_empty():
		var cur_name: = str(pet.pet_name).strip_edges()
		if cur_name.is_empty() or cur_name == PetClass.UNKNOWN_PET_NAME:
			pet.original_name = official
			pet.pet_name = official
	pet.element = pdata.get("element", pet.element)
	pet.pet_type = pdata.get("type", pet.pet_type)
	_apply_evolution_chain_cap_metadata(pet)


func get_pet_by_stable_id(stable_id: String):
	if str(stable_id).is_empty():
		return null
	for p in pets:
		if p.id == stable_id:
			return p
	for p in pet_bag:
		if p.id == stable_id:
			return p
	return null


func can_evolve(pet) -> Dictionary:
	var result = {"can": false, "message": "", "is_evolution_pet": false, "can_mutate": false, "required_level": 500}

	if not pets.has(pet):
		result.message = "未找到该宠物"
		return result


	if not EvolutionDataClass.is_evolution_pet(pet.pet_id):
		result.message = "该宠物无法进化"
		return result

	result.is_evolution_pet = true
	return _can_evolve_special(pet, result)

func _can_evolve_special(pet, result: Dictionary) -> Dictionary:
	var origin_id = pet.evolution_origin if not pet.evolution_origin.is_empty() else pet.pet_id
	var evo_data = EvolutionDataClass.get_evolution_data(origin_id)
	if evo_data.is_empty():
		result.message = "进化数据无效"
		return result

	var mc: = 0
	if "mutation_count" in pet:
		mc = int(pet.mutation_count)
	var chain = EvolutionDataClass.get_evolution_chain_by_origin(origin_id, pet.is_mutant, mc)
	var stage = chain.find(pet.pet_id)

	if stage == -1:
		result.message = "进化链数据无效"
		return result

	if stage >= chain.size() - 1:
		result.message = "该宠物已是终极形态"
		return result

	var required_level = 500
	result.required_level = required_level

	if pet.level < required_level:
		result.message = "宠物等级需达到 %d 级才能进化" % required_level
		return result

	result.can = true
	result.can_mutate = evo_data.get("mutant_evolution", []).size() > 0 and stage == 0
	return result


func can_mutate_evolve(pet) -> Dictionary:
	var result = {"can": false, "message": ""}

	if not pets.has(pet):
		result.message = "未找到该宠物"
		return result

	if not EvolutionDataClass.is_evolution_pet(pet.pet_id):
		result.message = "该宠物无法变异"
		return result

	if pet.evolution_stage > 0:
		result.message = "已进化的宠物无法变异"
		return result

	var evo_data = EvolutionDataClass.get_evolution_data(pet.pet_id)
	var mutant_chain = evo_data.get("mutant_evolution", [])
	if mutant_chain.size() == 0:
		result.message = "该宠物没有变异路线"
		return result

	result.can = true
	return result

func mutate_pet(pet) -> Dictionary:
	var result = {"success": false, "message": ""}

	var can_result = can_mutate_evolve(pet)
	if not can_result.can:
		result.message = can_result.message
		return result

	pet.is_mutant = true
	result.success = true
	result.message = "[%s] switched to mutation evolution path." % pet.pet_name

	return result


func can_merge(main_pet, sub_pet, player_realm: String) -> Dictionary:
	var result = {"can": false, "message": ""}

	if not pets.has(main_pet) or not pets.has(sub_pet):
		result.message = "未找到该宠物"
		return result

	if main_pet == sub_pet:
		result.message = "不能选择同一只宠物"
		return result


	var valid_realms = ["凡人", "散仙", "地仙", "天仙", "大罗金仙", "幻灵天神"]
	if not player_realm in valid_realms:
		result.message = "境界要求未达到"
		return result


	if main_pet.level < 300:
		result.message = "主宠等级需达到300级"
		return result
	if sub_pet.level < 300:
		result.message = "副宠等级需达到300级"
		return result


	if main_pet.generation >= 3:
		result.message = "3代宠物无法参与幻化"
		return result
	if sub_pet.generation >= 3:
		result.message = "副宠是3代，无法使用"
		return result
	if main_pet.generation != sub_pet.generation:
		result.message = "仅允许同代宠物进行幻化"
		return result


	if main_pet.locked:
		result.message = "主宠已锁定"
		return result
	if sub_pet.locked:
		result.message = "副宠已锁定"
		return result


	var new_generation = max(main_pet.generation, sub_pet.generation) + 1
	if new_generation > 3:
		result.message = "Merged pet generation cannot exceed 3."
		return result

	result.can = true
	return result

func _are_enemies(pet1, pet2) -> bool:
	var enemy_pairs = [
		["金", "木"], 
		["木", "金"], 
		["木", "土"], 
		["土", "木"], 
		["土", "水"], 
		["水", "土"], 
		["水", "火"], 
		["火", "水"], 
		["火", "金"], 
		["金", "火"]
	]
	return [pet1.element, pet2.element] in enemy_pairs

func _get_available_medal_types(pet) -> Array:
	var available: = []
	for medal_type in MEDAL_TYPES:
		if int(pet.medal_counts.get(medal_type, 0)) < MEDAL_MAX_PER_TYPE:
			available.append(medal_type)
	return available

func _inherit_skill_slots(main_pet) -> Array:
	if main_pet == null:
		return []
	if main_pet.has_method("normalize_skill_slots"):
		main_pet.normalize_skill_slots()
	if main_pet.skill_slots is Array:
		return main_pet.skill_slots.duplicate(true)
	return []

func _get_max_skill_level_by_skill_id(pet, skill_id: String) -> int:
	if pet == null:
		return 0
	var sid: = skill_id.strip_edges()
	if sid.is_empty():
		return 0
	if pet.has_method("normalize_skill_slots"):
		pet.normalize_skill_slots()
	var max_level: = 0
	var slots: Array = pet.skill_slots if pet.skill_slots is Array else []
	for entry in slots:
		if not (entry is Dictionary):
			continue
		var d: Dictionary = entry
		if str(d.get("skill_id", "")).strip_edges() != sid:
			continue
		max_level = maxi(max_level, int(d.get("level", 0)))
	return max_level

func _pet_skill_tier_cn(level: int) -> String:
	if level <= 0:
		return ""
	var lv: = clampi(level, 1, 99)
	match lv:
		1:
			return "一阶"
		2:
			return "二阶"
		3:
			return "三阶"
		_:
			return "第%d阶" % lv


func _pet_skill_slot_bar_cn(slot_1based: int) -> String:
	var s: = clampi(slot_1based, 1, 99)
	match s:
		1:
			return "第一栏"
		2:
			return "第二栏"
		3:
			return "第三栏"
		_:
			return "第%d栏" % s



func _pet_skill_resolve_canonical_key(entry: Dictionary) -> String:
	var ek: = str(entry.get("skill_key", "")).strip_edges()
	if not ek.is_empty():
		return ek
	var sid: = str(entry.get("skill_id", "")).strip_edges()
	var lv: = int(entry.get("level", 0))
	return PetClass._infer_skill_key_from_skill_id_level(sid, lv)



func _pet_skill_slot_entry_has_skill(entry: Dictionary) -> bool:
	if not _pet_skill_resolve_canonical_key(entry).is_empty():
		return true
	var lv: = int(entry.get("level", 0))
	if lv <= 0:
		return false
	var sid: = str(entry.get("skill_id", "")).strip_edges()
	var sn: = str(entry.get("skill_name", "")).strip_edges()
	return not sid.is_empty() or ( not sn.is_empty() and sn != "无")


func _pet_skill_same_family_blocks_empty_slot_learn(pet, new_skill_key: String) -> String:
	var new_cfg: Dictionary = GameData.PET_SKILLS.get(new_skill_key, {})
	var nfid: = str(new_cfg.get("skill_id", "")).strip_edges()
	if nfid.is_empty():
		return ""
	for si in range(pet.skill_slots.size()):
		var e: Dictionary = pet.get_skill_slot(si)
		var rk: String = _pet_skill_resolve_canonical_key(e)
		if rk.is_empty() or rk == new_skill_key:
			continue
		var oc: Dictionary = GameData.PET_SKILLS.get(rk, {})
		if str(oc.get("skill_id", "")).strip_edges() == nfid:
			return "学习失败：请先卸载同系已有技能后再使用高阶技能书"
	return ""


func _pet_skill_splash_double_shot_mutex_blocks(pet, new_skill_key: String) -> String:
	var defn: Dictionary = PetSkillConfig.get_skill_definition(new_skill_key)
	if defn.is_empty():
		return ""
	var new_sid: = str(defn.get("skill_id", "")).strip_edges()
	if new_sid.is_empty():
		return ""
	var grp: Array = PetSkillConfig.get_mutex_group(new_sid)
	if grp.size() < 2:
		return ""
	for si in range(pet.skill_slots.size()):
		var e2: Dictionary = pet.get_skill_slot(si)
		var rk2: String = _pet_skill_resolve_canonical_key(e2)
		if rk2.is_empty():
			continue
		var d2: Dictionary = PetSkillConfig.get_skill_definition(rk2)
		if d2.is_empty():
			continue
		var osid: = str(d2.get("skill_id", "")).strip_edges()
		if grp.has(new_sid) and grp.has(osid) and new_sid != osid:
			var new_name: = str(defn.get("skill_name", new_sid)).strip_edges()
			if new_name.is_empty():
				new_name = new_sid
			var old_name: = str(d2.get("skill_name", osid)).strip_edges()
			if old_name.is_empty():
				old_name = osid
			return "学习失败：%s与%s不能共存，请先卸载其中一方后再使用技能书" % [new_name, old_name]
	return ""


func _grant_random_medal(pet) -> String:
	var available = _get_available_medal_types(pet)
	if available.is_empty():
		return ""
	var selected = available[randi() % available.size()]
	pet.medal_counts[selected] = int(pet.medal_counts.get(selected, 0)) + 1
	return selected

func grant_random_medal_from_active_pet() -> Dictionary:
	var result: = {"success": false, "message": "", "medal_type": ""}
	if active_pet == null:
		result.message = "请先设置一只出战宠物"
		return result
	var selected: = _grant_random_medal(active_pet)
	if selected.is_empty():
		result.message = "当前出战宠物勋章槽已满（15/15）"
		return result
	pet_list_changed.emit()
	result.success = true
	result.medal_type = selected
	result.message = "补章成功：%s +1" % MEDAL_DISPLAY_NAMES.get(selected, "勋章")
	return result

func learn_skill_book_from_active_pet(book_name: String) -> Dictionary:
	var result: = {"success": false, "message": "", "slot": 0, "skill_name": ""}
	if active_pet == null:
		result.message = "请先设置一只出战宠物"
		return result
	var book_cfg: Dictionary = GameData.PET_SKILL_BOOKS.get(book_name, {})
	if book_cfg.is_empty():
		result.message = "未知宠物技能书"
		return result
	var skill_key: = str(book_cfg.get("skill_key", "")).strip_edges()
	if skill_key.is_empty():
		result.message = "技能书配置错误：缺少技能键"
		return result
	active_pet.normalize_skill_slots()
	var slot_capacity: int = active_pet.skill_slots.size()
	var skill_cfg: Dictionary = GameData.PET_SKILLS.get(skill_key, {})
	if skill_cfg.is_empty():
		result.message = "技能配置缺失"
		return result
	var target_skill_id: = str(skill_cfg.get("skill_id", "")).strip_edges()
	var target_level: = maxi(1, int(skill_cfg.get("level", 1)))


	var skill_level_cap: = _get_configured_max_skill_level()
	for k in range(slot_capacity):
		var up_entry: Dictionary = active_pet.get_skill_slot(k)
		var rk: String = _pet_skill_resolve_canonical_key(up_entry)
		if rk != skill_key:
			continue
		var old_level: int = maxi(1, int(up_entry.get("level", 1)))
		if old_level >= skill_level_cap:
			result.message = "该技能已是最高阶，无法继续升级"
			return result
		var gm_up: = GameManager.instance
		if gm_up and gm_up.has_method("local_use_item"):
			up_entry["level"] = old_level + 1
			if not active_pet.set_skill_to_slot(k, up_entry):
				return {"success": false, "message": "技能槽更新失败"}
			pet_list_changed.emit()
			return {"success": true, "message": "技能已在本地升至%d阶" % (old_level + 1)}
		if gm_up and gm_up.network and gm_up.network.is_logged_in() and gm_up.pet_skill_manager:
			gm_up.pet_skill_manager.request_level_up_skill(book_name, str(active_pet.id).strip_edges())
		else:
			result.message = "网络未连接，请登录后重试"
			return result
		result.success = true
		result.slot = k + 1
		var disp_name: String = str(up_entry.get("skill_name", "")).strip_edges()
		if disp_name.is_empty() or disp_name == "无":
			disp_name = str(skill_cfg.get("name", "未知技能"))
		result.skill_name = disp_name
		result.message = "正在升级：【%s】由%s升至%s，请稍候…" % [
			result.skill_name, 
			_pet_skill_tier_cn(old_level), 
			_pet_skill_tier_cn(old_level + 1)
		]
		return result

	var slot_index: int = -1
	var empty_but_locked: = false
	for k2 in range(slot_capacity):
		var cand: Dictionary = active_pet.get_skill_slot(k2)
		if not _pet_skill_slot_entry_has_skill(cand):
			if bool(cand.get("slot_locked", false)) or (active_pet.has_method("is_skill_slot_locked") and active_pet.is_skill_slot_locked(k2)):
				empty_but_locked = true
				continue
			slot_index = k2
			break
	if slot_index < 0:
		if empty_but_locked:
			result.message = "技能槽已锁定，请先解锁后再学习"
		else:
			result.message = "所有技能槽已满，请先卸载已有技能"
		return result
	var mutex_msg: = _pet_skill_splash_double_shot_mutex_blocks(active_pet, skill_key)
	if not mutex_msg.is_empty():
		result.message = mutex_msg
		return result
	var family_msg: = _pet_skill_same_family_blocks_empty_slot_learn(active_pet, skill_key)
	if not family_msg.is_empty():
		result.message = family_msg
		return result
	var slot: int = slot_index + 1
	var new_entry: Dictionary = {
		"slot": slot, 
		"skill_key": skill_key, 
		"skill_id": target_skill_id, 
		"skill_name": str(skill_cfg.get("name", "未知技能")), 
		"level": target_level
	}
	var old_entry: Dictionary = active_pet.get_skill_slot(slot_index)
	if _pet_skill_slot_entry_has_skill(old_entry):
		var old_name2: String = str(old_entry.get("skill_name", "未知技能"))
		result.message = "该槽位已有【%s】，请先卸载后再学习新技能" % old_name2
		return result

	if target_level < 2:
		var required_skill_key: = str(book_cfg.get("required_skill_key", "")).strip_edges()
		if not required_skill_key.is_empty():
			var required_skill: Dictionary = active_pet.get_skill_by_key(required_skill_key)
			if required_skill.is_empty():
				var required_cfg: Dictionary = GameData.PET_SKILLS.get(required_skill_key, {})
				var required_name: = str(required_cfg.get("name", "前置技能"))
				var required_level: = maxi(1, int(required_cfg.get("level", 1)))
				result.message = "学习失败：请先学习【%s%s】" % [required_name, _pet_skill_tier_cn(required_level)]
				return result


	var gm2 = GameManager.instance
	if gm2 and gm2.has_method("local_use_item"):
		if not active_pet.set_skill_to_slot(slot_index, new_entry):
			return {"success": false, "message": "技能槽更新失败"}
		pet_list_changed.emit()
		return {"success": true, "message": "本地学习：%s（%d阶）" % [new_entry.skill_name, target_level]}
	if not (gm2 and gm2.network and gm2.network.is_logged_in() and gm2.pet_skill_manager):
		result.message = "网络未连接，请登录后重试"
		return result
	gm2.pet_skill_manager.request_learn_skill(book_name, str(active_pet.id).strip_edges())
	result.success = true
	result.slot = slot
	result.skill_name = str(new_entry.get("skill_name", "未知技能"))
	result.message = "正在学习：%s，技能「%s」%s，请稍候…" % [
		_pet_skill_slot_bar_cn(slot), 
		result.skill_name, 
		_pet_skill_tier_cn(target_level)
	]
	return result

func _add_medal_with_redirect(pet, medal_type: String) -> bool:
	var available = _get_available_medal_types(pet)
	if available.is_empty():
		return false
	var target_type = medal_type
	if int(pet.medal_counts.get(target_type, 0)) >= MEDAL_MAX_PER_TYPE:
		target_type = available[randi() % available.size()]
	pet.medal_counts[target_type] = int(pet.medal_counts.get(target_type, 0)) + 1
	return true

func _inherit_medals(main_pet, sub_pet) -> Dictionary:
	var result = {
		"brave": clamp(int(main_pet.medal_counts.get("brave", 0)), 0, MEDAL_MAX_PER_TYPE), 
		"calm": clamp(int(main_pet.medal_counts.get("calm", 0)), 0, MEDAL_MAX_PER_TYPE), 
		"bold": clamp(int(main_pet.medal_counts.get("bold", 0)), 0, MEDAL_MAX_PER_TYPE)
	}

	var sub_pool: Array = []
	for medal_type in MEDAL_TYPES:
		var count = clamp(int(sub_pet.medal_counts.get(medal_type, 0)), 0, MEDAL_MAX_PER_TYPE)
		for i in range(count):
			sub_pool.append(medal_type)

	var inherit_count = int(floor(sub_pool.size() / 2.0))
	for i in range(inherit_count):
		if sub_pool.is_empty():
			break
		var idx = randi() % sub_pool.size()
		var selected_type = sub_pool[idx]
		sub_pool.remove_at(idx)
		_add_medal_with_redirect_to_counts(result, selected_type)

	return result

func _add_medal_with_redirect_to_counts(counts: Dictionary, medal_type: String) -> bool:
	var available: Array = []
	for t in MEDAL_TYPES:
		if int(counts.get(t, 0)) < MEDAL_MAX_PER_TYPE:
			available.append(t)
	if available.is_empty():
		return false
	var target_type = medal_type
	if int(counts.get(target_type, 0)) >= MEDAL_MAX_PER_TYPE:
		target_type = available[randi() % available.size()]
	counts[target_type] = int(counts.get(target_type, 0)) + 1
	return true

func refine_pets(material_pets: Array, deduct_gold: bool = true) -> Dictionary:
	var result = {
		"success": false, 
		"message": "", 
		"new_pet": null, 
		"new_pet_id": "", 
		"pool_type": "", 
		"avg_growth": 0.0, 
		"consumed_count": 0
	}

	if material_pets.size() != 8:
		result.message = "炼化需要恰好8只宠物。"
		return result

	var unique_ids: = {}
	var growth_sum: = 0.0
	for pet in material_pets:
		if pet == null:
			result.message = "炼化材料宠物无效。"
			return result
		if not pets.has(pet):
			result.message = "部分材料不在当前宠物列表中。"
			return result
		if unique_ids.has(pet.id):
			result.message = "不能重复使用同一只宠物。"
			return result
		unique_ids[pet.id] = true
		if pet.level != 1:
			result.message = "仅允许使用1级宠物。"
			return result
		if int(pet.generation) != 0:
			result.message = "仅允许使用0代宠物。"
			return result
		if EvolutionDataClass.is_evolution_pet(pet.pet_id) and str(pet.form) != "幼年":
			result.message = "进化宠物必须为幼年形态。"
			return result
		if pet.locked:
			result.message = "已锁定宠物无法用于炼化。"
			return result
		if active_pet == pet:
			result.message = "出战宠物不能作为炼化材料。"
			return result
		growth_sum += pet.total_growth

	var avg_growth = snapped(growth_sum / 8.0, 0.001)
	result.avg_growth = avg_growth

	var gm = GameManager.instance
	if gm == null or gm.player == null:
		result.message = "玩家数据未初始化。"
		return result
	if gm.player.gold < PET_REFINE_GOLD_COST:
		result.message = "金币不足，需要10,000,000金币。"
		return result

	var selected_pool = _pick_refine_pool()
	var candidate_ids = _get_refine_pool_candidates(selected_pool, "")
	if candidate_ids.is_empty():
		result.message = "炼化奖池配置异常。"
		return result

	var new_pet_id = candidate_ids[randi() % candidate_ids.size()]
	var pet_data = GameData.PET_DATA.get(new_pet_id, null)
	if pet_data == null:
		result.message = "目标宠物数据缺失。"
		return result

	if pets.size() - material_pets.size() + 1 > max_pets:
		result.message = "宠物栏没有空位。"
		return result

	for pet in material_pets:
		pets.erase(pet)
		remove_child(pet)

	var new_pet = load("res://scripts/pet.gd").create_from_data(pet_data, "refine", true, new_pet_id)
	new_pet.level = 1
	new_pet.experience = 0
	new_pet.locked = false
	new_pet.generation = 0

	var ratio = new_pet.stat_ratio
	new_pet.growth_rates = {
		"attack": snapped(avg_growth * ratio.attack / 100.0, 0.001), 
		"defense": snapped(avg_growth * ratio.defense / 100.0, 0.001), 
		"agility": snapped(avg_growth * ratio.agility / 100.0, 0.001), 
		"hp": avg_growth
	}
	new_pet.total_growth = avg_growth
	new_pet.lineage_seed_growth = avg_growth
	new_pet.recalculate_stats()

	if deduct_gold:
		gm.player.gold -= PET_REFINE_GOLD_COST

	add_pet(new_pet)

	result.success = true
	result.new_pet = new_pet
	result.new_pet_id = new_pet_id
	result.pool_type = selected_pool
	result.consumed_count = material_pets.size()
	result.message = "炼化成功！获得[%s]，成长值%.3f，消耗10,000,000金币。" % [new_pet.pet_name, avg_growth]
	return result

func _pick_refine_pool() -> String:
	var roll = randi() % 100 + 1
	var w = GameData.PET_REFINE_POOL_WEIGHTS
	if roll <= w.common:
		return "common"
	if roll <= w.common + w.rare:
		return "rare"
	return "ultra_rare"

func is_event_limited_pet_id(pet_id: String, pet_data: Dictionary = {}) -> bool:
	var pdata: Dictionary = pet_data
	if pdata.is_empty():
		pdata = GameData.PET_DATA.get(pet_id, {})
	if pdata.is_empty():
		return false
	if bool(pdata.get("is_event_limited", false)):
		return true
	if bool(pdata.get("collection_display_only", false)):
		return true
	if bool(pdata.get("collection_disabled", false)):
		return true
	if not str(pdata.get("event_pool", "")).strip_edges().is_empty():
		return true
	return false


func is_soul_reward_pet_id(pet_id: String, pet_data: Dictionary = {}) -> bool:
	var pdata: Dictionary = pet_data
	if pdata.is_empty():
		pdata = GameData.PET_DATA.get(pet_id, {})
	if pdata.is_empty():
		return false
	if bool(pdata.get("is_soul_reward_pet", false)):
		return true
	if not str(pdata.get("soul_reward_pool", "")).strip_edges().is_empty():
		return true
	return false


func is_world_boss_pet_id(pet_id: String, pet_data: Dictionary = {}) -> bool:
	var pdata: Dictionary = pet_data
	if pdata.is_empty():
		pdata = GameData.PET_DATA.get(pet_id, {})
	if pdata.is_empty():
		return false
	if bool(pdata.get("is_world_boss_pet", false)):
		return true
	if not str(pdata.get("world_boss_pool", "")).strip_edges().is_empty():
		return true
	return false


func is_festival_pet_id(pet_id: String, pet_data: Dictionary = {}) -> bool:
	var pdata: Dictionary = pet_data
	if pdata.is_empty():
		pdata = GameData.PET_DATA.get(pet_id, {})
	if pdata.is_empty():
		return false
	return bool(pdata.get("is_festival_pet", false))

func _is_blocked_from_refine_pool(pet_id: String, pet_data: Dictionary = {}) -> bool:

	if is_event_limited_pet_id(pet_id, pet_data):
		return true
	if is_soul_reward_pet_id(pet_id, pet_data):
		return true
	return is_world_boss_pet_id(pet_id, pet_data)

func _get_refine_pool_candidates(pool_type: String, element_filter: String = "") -> Array:
	var all_ids = GameData.PET_DATA.keys()
	var ultra_set: = {}
	for pid in GameData.PET_REFINE_ULTRA_RARE_CHAIN_IDS:
		ultra_set[pid] = true

	var candidates: = []
	for pet_id in all_ids:
		var pdata: Dictionary = GameData.PET_DATA.get(pet_id, {})
		if _is_blocked_from_refine_pool(pet_id, pdata):
			continue
		if element_filter != "":
			if str(pdata.get("element", "")) != element_filter:
				continue
		var is_evo = EvolutionDataClass.is_evolution_origin_pet_id(pet_id)
		var is_ultra = ultra_set.has(pet_id)
		match pool_type:
			"common":
				if not is_evo:
					candidates.append(pet_id)
			"rare":
				if is_evo and not is_ultra:
					candidates.append(pet_id)
			"ultra_rare":
				if is_ultra:
					candidates.append(pet_id)

	if not candidates.is_empty():
		return candidates


	match pool_type:
		"ultra_rare":
			return _get_refine_pool_candidates("rare", element_filter)
		"rare":
			return _get_refine_pool_candidates("common", element_filter)
		_:
			return []


func roll_pet_id_from_refine_pools(element_filter: String = "") -> Dictionary:
	var out = {"pet_id": "", "pool_type": ""}
	var pool = _pick_refine_pool()
	out.pool_type = pool
	var candidate_ids = _get_refine_pool_candidates(pool, element_filter)
	if candidate_ids.is_empty():
		return out
	out.pet_id = candidate_ids[randi() % candidate_ids.size()]
	return out

func _weighted_random(weights: Array) -> int:
	var total = 0.0
	for w in weights:
		total += w

	var random_value = randf() * total
	var current = 0.0

	for i in range(weights.size()):
		current += weights[i]
		if random_value <= current:
			return i

	return weights.size() - 1


func get_pet_count() -> int:
	return pets.size()

func get_available_slots() -> int:
	return max_pets - pets.size()


func is_pet_normal_state(pet) -> bool:
	if pet.locked:
		return false
	if active_pet and pet.id == active_pet.id:
		return false
	for bag_pet in pet_bag:
		if bag_pet.id == pet.id:
			return false
	return true

func get_normal_pets() -> Array:
	var result: Array = []
	for pet in pets:
		if is_pet_normal_state(pet):
			result.append(pet)
	return result

func get_pet_count_by_element(element: String) -> int:
	var count = 0
	for pet in pets:
		if pet.element == element:
			count += 1
	return count


func get_max_pet_level() -> int:
	var max_level = 0
	for pet in pets:
		if pet.level > max_level:
			max_level = pet.level
	return max_level


func get_max_pet_level_by_element(element: String) -> int:
	var max_level = 0
	for pet in pets:
		if pet.element == element and pet.level > max_level:
			max_level = pet.level
	return max_level

func get_pet(index: int):
	if index < 0 or index >= pets.size():
		return null
	return pets[index]

func get_all_pets():
	return pets.duplicate()


func store_pet_to_bag(pet) -> Dictionary:
	var result = {"success": false, "message": ""}
	if GameManager.instance:
		GameManager.instance.block_battle_start_temporarily(GameManager.BATTLE_START_BLOCK_ROSTER_REFRESH_MS, "pet_store_to_bag")


	if active_pet and active_pet.id == pet.id:
		result.message = "出战宠物不能放入宠物袋。"
		return result


	if pet_bag.size() >= max_pet_bag:
		result.message = "宠物袋已满。"
		return result


	var index = pets.find(pet)
	if index == -1:
		result.message = "未找到该宠物。"
		return result

	pets.remove_at(index)
	remove_child(pet)


	pet_bag.append(pet)
	add_child(pet)

	pet_removed.emit(pet)
	pet_list_changed.emit()

	result.success = true
	result.message = "已将%s放入宠物袋。" % pet.pet_name
	return result

func retrieve_pet_from_bag(pet, auto_set_active: bool = false) -> Dictionary:
	var result = {"success": false, "message": ""}
	if GameManager.instance:
		GameManager.instance.block_battle_start_temporarily(GameManager.BATTLE_START_BLOCK_ROSTER_REFRESH_MS, "pet_retrieve_from_bag")


	if pets.size() >= max_pets:
		result.message = "宠物列表已满，请先腾出一个位置。"
		return result


	var index = pet_bag.find(pet)
	if index == -1 and pet != null:
		var pid = str(pet.id)
		for i in range(pet_bag.size()):
			var bp = pet_bag[i]
			if bp and str(bp.id) == pid:
				index = i
				pet = bp
				break
	if index == -1:
		result.message = "该宠物不在宠物袋中。"
		return result

	pet_bag.remove_at(index)
	remove_child(pet)


	pets.append(pet)
	add_child(pet)


	if auto_set_active and active_pet == null:
		active_pet = pet
		active_pet_changed.emit(pet)

	pet_added.emit(pet)
	pet_list_changed.emit()

	result.success = true
	result.message = "Retrieved %s from pet bag." % pet.pet_name
	return result

func get_pet_bag_count() -> int:
	return pet_bag.size()

func update_max_pet_bag_for_vip(vip_tier: int) -> void :
	print("[PetManager] ===== update_max_pet_bag_for_vip() 被调用 =====")
	print("[PetManager] 参数 vip_tier = ", vip_tier)
	print("[PetManager] 当前 max_pet_bag = ", max_pet_bag)
	const VipBenefits = preload("res://scripts/vip_benefits.gd")
	var new_cap: = VipBenefits.effective_pet_bag_cap(vip_tier)
	print("[PetManager] VipBenefits.effective_pet_bag_cap(", vip_tier, ") 返回: ", new_cap)
	if max_pet_bag != new_cap:
		print("[PetManager] ✅ 容量需要更新！")
		print("[PetManager] VIP宠物袋容量更新: %d -> %d (VIP%d)" % [max_pet_bag, new_cap, vip_tier])
		max_pet_bag = new_cap
		print("[PetManager] 发出 pet_list_changed 信号...")
		pet_list_changed.emit()
		print("[PetManager] ✅ pet_list_changed 信号已发出")
	else:
		print("[PetManager] ℹ️ 容量相同（%d），无需更新" % new_cap)

func get_pet_from_bag(index: int):
	if index < 0 or index >= pet_bag.size():
		return null
	return pet_bag[index]

func get_all_pets_in_bag():
	return pet_bag.duplicate()



func _ensure_assist_pets_size() -> void :
	while assist_pets.size() < MAX_ASSIST_SLOTS:
		assist_pets.append(null)
	if assist_pets.size() > MAX_ASSIST_SLOTS:
		assist_pets.resize(MAX_ASSIST_SLOTS)

func get_player_reincarnation_for_assist() -> int:
	if GameManager.instance and GameManager.instance.player:
		return int(GameManager.instance.player.reincarnation)
	return 0

func get_player_noble_for_assist() -> int:
	if GameManager.instance:
		return maxi(0, int(GameManager.instance.noble_level))
	return 0

func get_unlocked_assist_slot_count() -> int:
	return PetAssistBonus.unlocked_slot_count(get_player_reincarnation_for_assist(), get_player_noble_for_assist())

func get_assist_slot_element(index: int) -> String:
	return PetAssistBonus.slot_element(index)

func is_assist_slot_unlocked(index: int) -> bool:
	return PetAssistBonus.is_slot_unlocked(index, get_player_reincarnation_for_assist(), get_player_noble_for_assist())

func get_assist_pet_at(index: int):
	_ensure_assist_pets_size()
	if index < 0 or index >= MAX_ASSIST_SLOTS:
		return null
	return assist_pets[index]

func find_assist_slot_by_pet_id(pet_id: String) -> int:
	var want: = str(pet_id).strip_edges()
	if want.is_empty():
		return -1
	_ensure_assist_pets_size()
	for i in range(MAX_ASSIST_SLOTS):
		var p = assist_pets[i]
		if p != null and str(p.id).strip_edges() == want:
			return i
	return -1

func is_pet_in_assist(pet) -> bool:
	if pet == null:
		return false
	return find_assist_slot_by_pet_id(str(pet.id)) >= 0

func get_assist_flat_bonus_for_active(stat_key: String) -> float:
	_ensure_assist_pets_size()
	return PetAssistBonus.total_flat_bonus(assist_pets, stat_key)

func get_eligible_assist_candidates(element: String) -> Array:
	var out: Array = []
	var el: = str(element).strip_edges()
	var active_id: = str(active_pet.id) if active_pet != null else ""
	for p in pets:
		if p == null:
			continue
		if str(p.id) == active_id:
			continue
		var pet_el: = str(p.element).strip_edges()

		if pet_el != el and pet_el != "天":
			continue
		out.append(p)
	return out

func _free_assist_pets_nodes() -> void :
	for pet in assist_pets:
		if pet and is_instance_valid(pet) and pet.get_parent() == self:
			remove_child(pet)
			pet.queue_free()
	assist_pets.clear()
	_ensure_assist_pets_size()

func has_pet(pet_name: String) -> bool:
	for pet in pets:
		if pet.pet_name == pet_name:
			return true
	return false


func create_pet_from_tower(pet_id: String, pet_name: String, growth: float) -> Dictionary:
	var result = {"success": false, "sent_to_mail": false, "message": ""}

	var pet_data = GameData.PET_DATA.get(pet_id)
	if pet_data == null:
		pet_data = GameData.PET_DATA.get("linlin")
		if pet_data == null:
			result.message = "宠物数据缺失。"
			return result

	if pets.size() >= max_pets:
		var mail_manager = GameManager.instance.mail_manager if GameManager.instance else null
		if mail_manager:
			var op_id: = "pet_overflow_%s_%s_%s" % [str(Time.get_unix_time_from_system()), str(randi()), str(pet_id)]
			var payload: = {
				"petId": pet_id, 
				"petName": pet_name, 
				"level": 1, 
				"growthRate": growth, 
			}
			var queued: = mail_manager.request_pet_overflow_mail(payload, op_id)
			if queued:
				result.sent_to_mail = true
				result.message = "宠物栏已满，【%s】已提交到服务器邮件发放，请稍后到邮箱领取。" % pet_name
				return result
			result.message = "宠物栏已满，且当前未登录或邮件服务不可用，无法发放邮件。"
			return result
		else:
			result.message = "宠物栏已满，且邮件系统不可用。"
			return result

	var pet = load("res://scripts/pet.gd").create_from_data(pet_data, "tower", true, pet_id)
	pet.is_elite = true

	var ratio = pet.stat_ratio
	pet.growth_rates = {
		"attack": snapped(growth * ratio.attack / 100.0, 0.001), 
		"defense": snapped(growth * ratio.defense / 100.0, 0.001), 
		"agility": snapped(growth * ratio.agility / 100.0, 0.001), 
		"hp": growth
	}
	pet.total_growth = growth
	pet.lineage_seed_growth = growth

	pet.recalculate_stats()

	add_pet(pet)
	result.success = true
	result.message = "获得宠物【%s】（成长 %.2f）。" % [pet_name, growth]
	return result

func _build_splash_lv1_skill_slot() -> Dictionary:
	var skill_cfg: Dictionary = GameData.PET_SKILLS.get("splash_lv1", {})
	return {
		"slot": 1, 
		"skill_key": "splash_lv1", 
		"skill_id": str(skill_cfg.get("skill_id", "splash")), 
		"skill_name": str(skill_cfg.get("name", "溅墨")), 
		"level": int(skill_cfg.get("level", 1))
	}

func create_mayday_mutant_anu_reward_pet() -> Dictionary:
	var result: Dictionary = {"success": false, "sent_to_mail": false, "message": "", "pet_name": "变异阿努", "growth": 0.0}
	var game_manager = GameManager.instance
	if game_manager != null and game_manager.network != null and game_manager.network.is_logged_in():
		result.message = "五一活动宠物奖励已切换为服务端权威，在线状态下禁止本地直接发宠。"
		push_warning("[AuthorityGuard] " + result.message)
		return result
	if not OS.is_debug_build():
		result.message = "五一活动宠物本地发放仅允许调试环境使用，正式环境已禁用。"
		push_warning("[AuthorityGuard] " + result.message)
		return result
	var pet_id: String = "bianyianu"
	var pet_data: Dictionary = GameData.PET_DATA.get(pet_id, {})
	if pet_data.is_empty():
		result.message = "活动宠物数据缺失：变异阿努"
		return result
	var growth: float = snapped(4.0 + randf() * 2.0, 0.001)
	var slot_entry: Dictionary = _build_splash_lv1_skill_slot()
	var skill_slots: Array = [slot_entry]
	if pets.size() >= max_pets:
		result.message = "宠物栏已满，请先整理宠物栏后再开启礼包。"
		return result
	var pet = load("res://scripts/pet.gd").create_from_data(pet_data, "mayday_event", true, pet_id)
	pet.is_elite = true
	var ratio = pet.stat_ratio
	pet.growth_rates = {
		"attack": snapped(growth * ratio.attack / 100.0, 0.001), 
		"defense": snapped(growth * ratio.defense / 100.0, 0.001), 
		"agility": snapped(growth * ratio.agility / 100.0, 0.001), 
		"hp": growth
	}
	pet.total_growth = growth
	pet.lineage_seed_growth = growth
	pet.level = 1
	pet.generation = 0
	pet.skill_slots = skill_slots.duplicate(true)
	if pet.has_method("normalize_skill_slots"):
		pet.normalize_skill_slots()
	pet.recalculate_stats()
	add_pet(pet)
	result.success = true
	result.growth = growth
	result.message = "获得活动宠物【变异阿努】（成长 %.3f，1级0代，自带技能【溅墨lv1】）。" % growth
	return result

func _resolve_mail_pet_evolution_stage(pet_id: String, pet_evolution_stage: int, is_mutant: bool) -> int:
	if pet_evolution_stage < 0:
		return -1
	var binding: = EvolutionDataClass.find_pet_evolution_binding(pet_id)
	if not binding.is_empty():
		var chain: Array = binding.get("chain", [])
		if chain.is_empty():
			return clampi(int(pet_evolution_stage), 0, 999)
		var stage_from_id: = int(binding.get("stage", 0))
		var requested_stage: = clampi(int(pet_evolution_stage), 0, chain.size() - 1)
		return maxi(stage_from_id, requested_stage)
	var chain: = EvolutionDataClass.get_evolution_chain_for_pet(pet_id, is_mutant)
	if chain.is_empty():
		var origin: = EvolutionDataClass.get_evolution_origin(pet_id)
		if not origin.is_empty():
			chain = EvolutionDataClass.get_evolution_chain_by_origin(origin, is_mutant)
	if chain.is_empty():
		return clampi(int(pet_evolution_stage), 0, 999)
	var stage_from_id: = EvolutionDataClass.get_evolution_stage(pet_id, chain)
	var requested_stage: = clampi(int(pet_evolution_stage), 0, chain.size() - 1)
	if stage_from_id >= 0:
		return maxi(stage_from_id, requested_stage)
	return requested_stage

func _apply_mail_pet_evolution_identity(pet, actual_pet_id: String, pet_evolution_stage: int) -> void :
	if not EvolutionDataClass.is_evolution_pet(actual_pet_id):
		return
	var binding: = EvolutionDataClass.find_pet_evolution_binding(actual_pet_id)
	if binding.is_empty():
		if pet_evolution_stage < 0:
			return
		var mc: = 0
		if "mutation_count" in pet:
			mc = int(pet.mutation_count)
		var chain: = EvolutionDataClass.get_evolution_chain_by_origin(pet.evolution_origin, pet.is_mutant, mc)
		if chain.is_empty():
			chain = EvolutionDataClass.get_evolution_chain_for_pet(pet.pet_id, pet.is_mutant, mc)
		if chain.is_empty():
			return
		pet.evolution_stage = _resolve_mail_pet_evolution_stage(actual_pet_id, pet_evolution_stage, pet.is_mutant)
		_sync_evolution_pet_identity_from_stage(pet)
		return
	pet.evolution_origin = str(binding.get("origin", ""))
	pet.is_mutant = bool(binding.get("is_mutant", false))
	pet.is_evolution_pet = true
	var chain: Array = binding.get("chain", [])
	var stage_from_id: = int(binding.get("stage", 0))
	if pet_evolution_stage >= 0 and not chain.is_empty():
		var requested_stage: = clampi(int(pet_evolution_stage), 0, chain.size() - 1)
		pet.evolution_stage = maxi(stage_from_id, requested_stage)
	else:
		pet.evolution_stage = stage_from_id
	_sync_evolution_pet_identity_from_stage(pet)

func create_pet_from_mail(pet_id: String, pet_level: int, pet_growth: float, pet_generation: int = 0, pet_evolution_stage: int = -1, pet_skill_slots: Array = [], medal_counts: Dictionary = {}) -> bool:
	var actual_pet_id = pet_id
	var pet_data = GameData.PET_DATA.get(pet_id)

	if pet_data == null:
		for pet_key in GameData.PET_DATA.keys():
			var data = GameData.PET_DATA.get(pet_key, {})
			if data.get("name", "") == pet_id:
				actual_pet_id = pet_key
				pet_data = data
				break

	if pet_data == null:
		print("[PetManager] Mail pet id not found: ", pet_id)
		return false

	if pets.size() >= max_pets:
		print("[PetManager] Pet list is full, cannot add mail pet")
		return false

	var pet = load("res://scripts/pet.gd").create_from_data(pet_data, "mail", true, actual_pet_id)
	pet.is_elite = true

	var ratio = pet.stat_ratio
	pet.growth_rates = {
		"attack": snapped(pet_growth * ratio.attack / 100.0, 0.001), 
		"defense": snapped(pet_growth * ratio.defense / 100.0, 0.001), 
		"agility": snapped(pet_growth * ratio.agility / 100.0, 0.001), 
		"hp": pet_growth
	}
	pet.total_growth = pet_growth
	pet.lineage_seed_growth = pet_growth

	pet.generation = clampi(int(pet_generation), 0, 3)
	pet.level = pet_level
	if pet_skill_slots is Array and not pet_skill_slots.is_empty():
		pet.skill_slots = pet_skill_slots.duplicate(true)
		if pet.has_method("normalize_skill_slots"):
			pet.normalize_skill_slots()
	pet.medal_counts = {
		"brave": clampi(int(medal_counts.get("brave", 0)), 0, 5), 
		"calm": clampi(int(medal_counts.get("calm", 0)), 0, 5), 
		"bold": clampi(int(medal_counts.get("bold", 0)), 0, 5), 
	}
	if EvolutionDataClass.is_evolution_pet(actual_pet_id):
		_apply_mail_pet_evolution_identity(pet, actual_pet_id, pet_evolution_stage)
	pet.recalculate_stats()

	add_pet(pet)
	print("[PetManager] Mail pet added: ", pet.pet_name, " level:", pet_level, " growth:", pet_growth, " generation:", pet.generation, " stage:", pet.evolution_stage)
	return true

func create_pet_from_xianmo(pet_id: String, growth: float) -> bool:
	var pet_data = GameData.PET_DATA.get(pet_id)
	if pet_data == null:
		pet_data = GameData.PET_DATA.get("linlin")
		if pet_data == null:
			return false

	if pets.size() >= max_pets:
		return false

	var pet = load("res://scripts/pet.gd").create_from_data(pet_data, "xianmo", true, pet_id)
	pet.is_elite = true

	var ratio = pet.stat_ratio
	pet.growth_rates = {
		"attack": snapped(growth * ratio.attack / 100.0, 0.001), 
		"defense": snapped(growth * ratio.defense / 100.0, 0.001), 
		"agility": snapped(growth * ratio.agility / 100.0, 0.001), 
		"hp": growth
	}
	pet.total_growth = growth
	pet.lineage_seed_growth = growth

	pet.recalculate_stats()

	add_pet(pet)
	return true

func add_pet_from_data(pet_data: Dictionary) -> bool:
	print("[PetManager] add_pet_from_data called, pet_data=", pet_data)

	if pet_data == null or not pet_data is Dictionary:
		print("[PetManager] Invalid pet data")
		return false

	if pets.size() >= max_pets:
		print("[PetManager] Pet list is full, cannot add pet")
		return false

	var pet_id = pet_data.get("pet_id", pet_data.get("id", ""))
	var pet_level = pet_data.get("level", 1)
	var pet_growth = pet_data.get("growth", pet_data.get("growth_rate", 3.0))
	var pet_element = pet_data.get("element", "")

	print("[PetManager] pet_id=", pet_id, ", level=", pet_level, ", growth=", pet_growth, ", element=", pet_element)

	var actual_pet_id = pet_id
	var base_data = GameData.PET_DATA.get(pet_id)

	if base_data == null:
		print("[PetManager] Direct id lookup failed, trying by pet name...")
		for pet_key in GameData.PET_DATA.keys():
			var data = GameData.PET_DATA.get(pet_key, {})
			if data.get("name", "") == pet_id or data.get("name", "") == pet_data.get("name", ""):
				actual_pet_id = pet_key
				base_data = data
				print("[PetManager] Matched by name: pet_key=", pet_key, ", name=", data.get("name", ""))
				break

	if base_data == null:
		print("[PetManager] Pet id not found: ", pet_id)
		return false

	print("[PetManager] Creating pet with actual_pet_id=", actual_pet_id, ", base_data.name=", base_data.get("name", ""))

	var pet = load("res://scripts/pet.gd").create_from_data(base_data, "import", true, actual_pet_id)
	pet.is_elite = pet_data.get("is_elite", true)

	if pet_element != "" and pet_element in ["金", "木", "水", "火", "土"]:
		pet.element = pet_element

	var ratio = pet.stat_ratio
	pet.growth_rates = {
		"attack": snapped(pet_growth * ratio.attack / 100.0, 0.001), 
		"defense": snapped(pet_growth * ratio.defense / 100.0, 0.001), 
		"agility": snapped(pet_growth * ratio.agility / 100.0, 0.001), 
		"hp": pet_growth
	}
	pet.total_growth = pet_growth
	pet.lineage_seed_growth = pet_growth

	pet.level = pet_level
	pet.recalculate_stats()

	add_pet(pet)
	print("[PetManager] Pet added from data: ", pet.pet_name, " level:", pet_level, " growth:", pet_growth)
	return true


func to_dict() -> Dictionary:
	var pet_data = []
	for pet in pets:
		pet_data.append(pet.to_dict())

	var pet_bag_data = []
	for pet in pet_bag:
		pet_bag_data.append(pet.to_dict())

	_ensure_assist_pets_size()
	var assist_data: Array = []
	for i in range(MAX_ASSIST_SLOTS):
		var ap = assist_pets[i]
		if ap != null and is_instance_valid(ap):
			assist_data.append(ap.to_dict())
		else:
			assist_data.append(null)

	var active_id = active_pet.id if active_pet else ""

	return {
		"pets": pet_data, 
		"pet_bag": pet_bag_data, 
		"assist_pets": assist_data, 
		"active_pet_id": active_id, 
		"version": 2
	}


func _promote_active_pet_from_bag_if_needed(want_id: String) -> void :
	var want: = str(want_id).strip_edges()
	if want.is_empty():
		return
	for p in pets:
		if p != null and is_instance_valid(p) and str(p.id).strip_edges() == want:
			active_pet = p
			return
	var bag_idx: = -1
	var bag_pet = null
	for i in range(pet_bag.size()):
		var bp = pet_bag[i]
		if bp != null and is_instance_valid(bp) and str(bp.id).strip_edges() == want:
			bag_idx = i
			bag_pet = bp
			break
	if bag_pet == null:
		return
	if pets.size() >= max_pets:
		push_warning("[PetManager] 出战宠在宠物袋中但主栏已满，无法自动接回: %s" % want)
		return
	pet_bag.remove_at(bag_idx)
	pets.append(bag_pet)
	active_pet = bag_pet
	print("[PetManager] 出战宠已从宠物袋接回主栏: ", want)

func ensure_active_pet_consistent(preferred_active_id: String = "") -> void :
	if pets.is_empty():
		active_pet = null
		if pet_bag.size() > 0:
			push_warning("[PetManager] 存档同步后主阵容为空但宠物袋有宠物，出战已清空。")
		return
	var want: = str(preferred_active_id).strip_edges()
	if active_pet != null and is_instance_valid(active_pet) and pets.has(active_pet):
		if want.is_empty() or str(active_pet.id).strip_edges() == want:
			return
	if not want.is_empty():
		for q in pets:
			if q != null and is_instance_valid(q) and str(q.id).strip_edges() == want:
				active_pet = q
				return
	active_pet = pets[0]



func resolve_active_pet_for_battle():
	if pets.is_empty():
		active_pet = null
		return null
	if active_pet != null and is_instance_valid(active_pet) and pets.has(active_pet):
		return active_pet
	active_pet = pets[0]
	active_pet_changed.emit(active_pet)
	return active_pet

func has_valid_active_pet_reference() -> bool:
	return active_pet != null and is_instance_valid(active_pet) and pets.has(active_pet)

func ensure_active_pet_ready_for_battle() -> Dictionary:
	var result: = {
		"ok": false, 
		"pet": null, 
		"has_pets": pets.size() > 0, 
		"rebound": false, 
		"reason": ""
	}
	if pets.is_empty():
		active_pet = null
		result.ok = true
		result.reason = "no_pets"
		return result
	if has_valid_active_pet_reference():
		result.ok = true
		result.pet = active_pet
		result.reason = "active_ok"
		return result
	var previous_id: = ""
	if active_pet != null and is_instance_valid(active_pet):
		previous_id = str(active_pet.id).strip_edges()
	ensure_active_pet_consistent(previous_id)
	if has_valid_active_pet_reference():
		result.ok = true
		result.pet = active_pet
		result.rebound = true
		result.reason = "rebound_existing"
		active_pet_changed.emit(active_pet)
		return result
	active_pet = pets[0]
	result.ok = has_valid_active_pet_reference()
	result.pet = active_pet
	result.rebound = result.ok
	result.reason = "fallback_first" if result.ok else "invalid_after_fallback"
	if result.ok:
		active_pet_changed.emit(active_pet)
	return result


func _is_partial_battle_loot_pet_slice(pet_dict: Dictionary) -> bool:
	if pet_dict.is_empty():
		return true
	return (
		not pet_dict.has("total_growth")
		and not pet_dict.has("growth")
		and not pet_dict.has("growth_rates")
	)


func _resolve_battle_loot_pet_level_cap(gm, old_level: int) -> Dictionary:
	var anchor: = old_level
	var batch_budget: = 1
	if gm != null:
		if gm.has_method("get_field_battle_pet_level_anchor"):
			var anchor_raw: = int(gm.get_field_battle_pet_level_anchor())
			if anchor_raw > 0:
				anchor = anchor_raw
		if gm.has_method("get_field_battle_loot_batch_level_budget"):
			batch_budget = maxi(1, int(gm.get_field_battle_loot_batch_level_budget()))
	var per: = 1
	if gm != null and gm.has_method("get_field_catchup_level_ups"):
		per = maxi(1, int(gm.get_field_catchup_level_ups()))
	return {
		"anchor": anchor, 
		"batch_budget": batch_budget, 
		"max_allowed": mini(old_level + per, anchor + per * batch_budget), 
	}


func _roll_battle_loot_pet_growth_steps(pet, from_level: int, to_level: int) -> void :
	if pet == null or to_level <= from_level:
		return
	for _i in range(to_level - from_level):
		var total_growth_change = _roll_level_growth_delta_for_pet(pet)
		var stat_ratio = pet.stat_ratio
		for stat in ["attack", "defense", "agility"]:
			var stat_change = total_growth_change * (stat_ratio.get(stat, 33.33) / 100.0)
			pet.growth_rates[stat] = snapped(pet.growth_rates[stat] + stat_change, 0.001)
		pet.total_growth = snapped(
			pet.growth_rates["attack"] + pet.growth_rates["defense"] + pet.growth_rates["agility"], 
			0.001
		)
	_update_pet_stats(pet)


func _apply_battle_loot_pet_level_exp_with_growth(
	pet, 
	old_level: int, 
	incoming_level: int, 
	auth_exp: int, 
	pet_dict: Dictionary, 
	force_absolute: bool = false, 
) -> void :
	if pet == null:
		return
	if force_absolute:
		if incoming_level < old_level:
			if pet.has_method("is_at_max_level") and old_level >= int(pet.get_effective_max_level()):
				pet.experience = maxi(int(pet.experience), auth_exp)
				pet.clamp_experience_if_max_level()
				return
			pet.level = incoming_level
			pet.experience = auth_exp
			pet.clamp_experience_if_max_level()
			return
		if incoming_level == old_level:
			pet.experience = auth_exp
			pet.clamp_experience_if_max_level()
			return
		if not _is_partial_battle_loot_pet_slice(pet_dict):
			var merged_abs: = pet_dict.duplicate(true)
			merged_abs["level"] = incoming_level
			merged_abs["experience"] = auth_exp
			pet.from_dict(merged_abs)
			return
		pet.level = incoming_level
		pet.experience = auth_exp
		_roll_battle_loot_pet_growth_steps(pet, old_level, incoming_level)
		pet.clamp_experience_if_max_level()
		return
	if incoming_level < old_level:
		if pet.has_method("is_at_max_level") and old_level >= int(pet.get_effective_max_level()):
			pet.experience = maxi(int(pet.experience), auth_exp)
			pet.clamp_experience_if_max_level()
			return
		pet.experience = maxi(int(pet.experience), auth_exp)
		pet.clamp_experience_if_max_level()
		return
	if incoming_level == old_level:
		pet.experience = maxi(int(pet.experience), auth_exp)
		pet.clamp_experience_if_max_level()
		return
	if not _is_partial_battle_loot_pet_slice(pet_dict):
		var merged: = pet_dict.duplicate(true)
		merged["level"] = incoming_level
		merged["experience"] = auth_exp
		pet.from_dict(merged)
		return
	pet.level = incoming_level
	pet.experience = auth_exp
	_roll_battle_loot_pet_growth_steps(pet, old_level, incoming_level)
	pet.clamp_experience_if_max_level()


func _maybe_grant_battle_loot_max_level_medal(pet, old_level: int, old_medals: int) -> void :

	if pet == null or not pet.has_method("get_effective_max_level"):
		return
	var cap: = int(pet.get_effective_max_level())
	if old_level >= cap or int(pet.level) < cap:
		return
	if sum_medal_counts_for_pet(pet) != old_medals:
		return
	var msg: = grant_max_level_medal_if_needed(pet, old_level)
	if msg.is_empty():
		return
	flush_pending_pet_medal_syncs("max_level_reward")


func apply_active_pet_battle_loot_slice(pet_dict: Dictionary, force_absolute: bool = false) -> void :

	if pet_dict.is_empty():
		return
	var ap = get_active_pet()
	if ap == null:
		return
	var gm = GameManager.instance
	if gm != null and gm.has_method("is_pet_merge_exp_blocked_for_pet") and gm.is_pet_merge_exp_blocked_for_pet(ap):
		return
	var old_level: = int(ap.level)
	var old_medals: = sum_medal_counts_for_pet(ap)
	var incoming_level: = int(pet_dict.get("level", old_level))
	var auth_exp: = maxi(0, int(pet_dict.get("experience", pet_dict.get("exp", ap.experience))))
	var cap_info: = _resolve_battle_loot_pet_level_cap(gm, old_level)
	var max_allowed_level: = int(cap_info.get("max_allowed", old_level + 1))
	var anchor: = int(cap_info.get("anchor", old_level))
	var full_snapshot: = not _is_partial_battle_loot_pet_slice(pet_dict)
	if force_absolute:
		if gm != null and gm.has_method("_cap_field_pet_progress_exp"):
			if incoming_level > old_level:
				auth_exp = 0
			else:
				auth_exp = gm._cap_field_pet_progress_exp(incoming_level, auth_exp)
		_apply_battle_loot_pet_level_exp_with_growth(ap, old_level, incoming_level, auth_exp, pet_dict, true)
		if int(ap.level) > old_level:
			pet_leveled_up.emit(ap, old_level, int(ap.level))
		if gm != null and gm.has_method("_clamp_field_pet_level_after_exp"):
			gm._clamp_field_pet_level_after_exp(ap)
		_heal_pet_full_if_out_of_battle(ap)
		_maybe_grant_battle_loot_max_level_medal(ap, old_level, old_medals)
		return

	if incoming_level < old_level:
		print("[PetManager] battle-loot rejected pet downgrade id=%s localLv=%d incomingLv=%d" % [str(ap.id), old_level, incoming_level])
		incoming_level = old_level
		auth_exp = maxi(int(ap.experience), auth_exp)
	elif incoming_level == old_level:
		auth_exp = maxi(int(ap.experience), auth_exp)
	elif incoming_level > max_allowed_level and not full_snapshot:
		if anchor <= 10 and incoming_level >= int(ap.get_effective_max_level()) - 1:
			print(
				"[PetManager] battle-loot rejected suspicious pet level jump id=%s localLv=%d incomingLv=%d anchor=%d cap=%d"
				%[str(ap.id), old_level, incoming_level, anchor, max_allowed_level]
			)
			return
		print(
			"[PetManager] battle-loot clamped pet upgrade id=%s localLv=%d incomingLv=%d cap=%d anchor=%d"
			%[str(ap.id), old_level, incoming_level, max_allowed_level, anchor]
		)
		incoming_level = max_allowed_level
		auth_exp = maxi(int(ap.experience), auth_exp)


	if incoming_level > old_level and not full_snapshot:
		auth_exp = 0
	elif incoming_level <= old_level and gm != null and gm.has_method("_cap_field_pet_progress_exp"):
		auth_exp = gm._cap_field_pet_progress_exp(incoming_level, auth_exp)
	_apply_battle_loot_pet_level_exp_with_growth(ap, old_level, incoming_level, auth_exp, pet_dict, false)
	if int(ap.level) > old_level:
		pet_leveled_up.emit(ap, old_level, int(ap.level))
	if force_absolute and gm != null and gm.has_method("_clamp_field_pet_level_after_exp"):
		gm._clamp_field_pet_level_after_exp(ap)
	_heal_pet_full_if_out_of_battle(ap)
	_maybe_grant_battle_loot_max_level_medal(ap, old_level, old_medals)


## 读档后把全部宠物（上阵 + 袋 + 助战）按当前公式重算一遍属性。
## 目前唯一的用处是把「生命成长」切回参考稿口径后，让存量宠物的血量立刻跟上。
func _refresh_all_pet_stats_after_load() -> void:
	# 早期加载（GameManager 还没起来）时不碰属性：_update_pet_stats 要读装备加成，
	# 这时候拿不到会算出偏低的血上限。
	if GameManager.instance == null:
		return
	for pet in pets:
		_update_pet_stats(pet)
	for pet in pet_bag:
		_update_pet_stats(pet)
	for pet in assist_pets:
		if pet != null:
			_update_pet_stats(pet)


func from_dict(data: Dictionary):
	if GameManager.instance:
		GameManager.instance.block_battle_start_temporarily(GameManager.BATTLE_START_BLOCK_ROSTER_REFRESH_MS, "pet_from_dict_begin")
	if data == null or not data is Dictionary:
		return

	var previous_active_id: = str(active_pet.id) if active_pet != null else ""
	var active_id = str(data.get("active_pet_id", "")).strip_edges()
	if active_id == "":
		active_id = previous_active_id
	var pet_array = data.get("pets", [])
	var pet_bag_array = data.get("pet_bag", [])

	for pet in pets:
		if pet and is_instance_valid(pet) and pet.get_parent() == self:
			remove_child(pet)
			pet.queue_free()
	for pet in pet_bag:
		if pet and is_instance_valid(pet) and pet.get_parent() == self:
			remove_child(pet)
			pet.queue_free()
	_free_assist_pets_nodes()
	pets.clear()
	pet_bag.clear()
	active_pet = null

	var found_active_pet = null
	if data.has("pets"):
		for pet_dict in pet_array:
			var pet = load("res://scripts/pet.gd").new()
			pet.from_dict(pet_dict)
			pets.append(pet)
			add_child(pet)
			if pet.id == active_id:
				found_active_pet = pet
		for p in pets:
			_sync_evolution_pet_identity_from_stage(p)
		if found_active_pet:
			active_pet = found_active_pet
		elif active_id.is_empty() and pets.size() > 0:
			active_pet = pets[0]
		flush_pending_pet_medal_syncs("offline_max_level_reward")

	if data.has("pet_bag"):
		for pet_dict in pet_bag_array:
			var pet = load("res://scripts/pet.gd").new()
			pet.from_dict(pet_dict)
			pet_bag.append(pet)
			add_child(pet)
		for p in pet_bag:
			_sync_evolution_pet_identity_from_stage(p)

	_ensure_assist_pets_size()
	var assist_array = data.get("assist_pets", [])
	if data.has("assist_pets") and assist_array is Array:
		for i in range(mini(MAX_ASSIST_SLOTS, assist_array.size())):
			var pet_dict = assist_array[i]
			if pet_dict == null or not (pet_dict is Dictionary):
				assist_pets[i] = null
				continue
			var pet = load("res://scripts/pet.gd").new()
			pet.from_dict(pet_dict)
			assist_pets[i] = pet
			add_child(pet)
			_sync_evolution_pet_identity_from_stage(pet)

	if not active_id.is_empty():
		_promote_active_pet_from_bag_if_needed(active_id)

	ensure_active_pet_consistent(active_id)

	# 生命成长改回参考稿口径（血量成长走物种 hp_growth）之后，
	# 老存档里的 max_hp 还是按「总成长」算出来的。读档时统一重算一次，
	# 否则面板上写着「生命成长 6.0」、血量却仍按 3.6 在长。
	# _update_pet_stats 会按血量百分比缩放，不会让宠物突然变残血/满血。
	_refresh_all_pet_stats_after_load()

	active_pet_changed.emit(active_pet)
	pet_list_changed.emit()


	if GameManager.instance and GameManager.instance.in_battle and active_pet:
		ensure_active_pet_consistent(str(active_pet.id))

	if GameManager.instance:
		GameManager.instance.block_battle_start_temporarily(GameManager.BATTLE_START_BLOCK_ROSTER_REFRESH_MS, "pet_from_dict_done")
