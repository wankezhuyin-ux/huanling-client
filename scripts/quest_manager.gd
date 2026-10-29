extends Node

class_name QuestManager

const EQUIPMENT = preload("res://scripts/equipment_manager.gd").Equipment
const GameData = preload("res://scripts/game_data.gd")

signal quest_updated(quest_id: String, progress: Dictionary)
signal quest_completed(quest_id: String)
signal quest_reward_claimed(quest_id: String, rewards: Dictionary)
signal daily_quests_reset

var player_quests: Dictionary = {}
var daily_reset_time: int = 0

const DAILY_RESET_HOUR = 0
const DAILY_RESET_CHECK_INTERVAL_SECONDS = 60.0

const DAILY_RESET_UPLOAD_STAGGER_MAX_SEC: = 90

var _daily_reset_check_timer: Timer = null
var _daily_reset_upload_timer: Timer = null
var _daily_reset_upload_pending: bool = false

func _normalize_quest_status_value(v: Variant) -> int:
	var x: = int(QuestDatabase.QuestStatus.LOCKED)
	match typeof(v):
		TYPE_INT:
			x = int(v)
		TYPE_FLOAT:
			x = int(round(v))
		TYPE_STRING:
			var sv: = String(v).strip_edges()
			if sv.is_valid_int():
				x = int(sv)
			elif sv.is_valid_float():
				x = int(round(float(sv)))
			else:
				x = int(QuestDatabase.QuestStatus.LOCKED)
		_:
			x = int(QuestDatabase.QuestStatus.LOCKED)
	var lo: = int(QuestDatabase.QuestStatus.LOCKED)
	var hi: = int(QuestDatabase.QuestStatus.FINISHED)
	if x < lo or x > hi:
		x = lo

	if x == int(QuestDatabase.QuestStatus.IN_PROGRESS):
		x = int(QuestDatabase.QuestStatus.ACTIVE)
	return x



func _player_reach_realm_satisfies_objective(target_realm: String) -> bool:
	var tr: = str(target_realm).strip_edges()
	if tr.is_empty():
		return false
	if not GameManager.instance or not GameManager.instance.player:
		return false
	var player_realm: = str(GameManager.instance.player.realm).strip_edges()
	var need_idx: = GameData.REALMS.find(tr)
	var pl_idx: = GameData.REALMS.find(player_realm)
	if need_idx < 0:
		return player_realm == tr
	if pl_idx < 0:
		return false
	return pl_idx >= need_idx


func _normalize_objective_progress_value(v: Variant) -> int:
	match typeof(v):
		TYPE_INT:
			return int(v)
		TYPE_FLOAT:
			return int(round(v))
		TYPE_STRING:
			var sv: = String(v).strip_edges()
			if sv.is_valid_int():
				return int(sv)
			if sv.is_valid_float():
				return int(round(float(sv)))
			return 0
		_:
			return 0


func _sanitize_quest_progress_numbers() -> void :
	var changed: = false
	for quest_id in player_quests.keys():
		var info = player_quests[quest_id]
		if typeof(info) != TYPE_DICTIONARY:
			continue
		var prog = info.get("progress")
		if typeof(prog) != TYPE_DICTIONARY:
			continue
		for k in prog.keys():
			var nv: = _normalize_objective_progress_value(prog[k])
			if prog[k] != nv:
				prog[k] = nv
				changed = true
	if changed:
		save_quest_data()


func _sanitize_all_quest_status_fields() -> void :
	var changed: = false
	for quest_id in player_quests.keys():
		var info = player_quests[quest_id]
		if typeof(info) != TYPE_DICTIONARY:
			continue
		var ns: = _normalize_quest_status_value(info.get("status"))
		if info.get("status") != ns:
			info["status"] = ns
			changed = true
	if changed:
		save_quest_data()
	_sanitize_quest_progress_numbers()



func _progress_main_quest_chain_if_advanced_player() -> void :
	if not GameManager.instance or not GameManager.instance.player:
		return
	var pl = GameManager.instance.player
	var player_realm_idx: = GameData.REALMS.find(str(pl.realm))
	if player_realm_idx < 0:
		player_realm_idx = GameData.REALMS.size() - 1
	if player_realm_idx < GameData.REALMS.find("散仙"):
		return

	var changed: = false
	for _i in range(14):
		var pass_changed: = false
		var qid: = "quest_001"
		while qid != "":
			var qdata = QuestDatabase.get_quest(qid)
			if qdata.is_empty() or qdata.get("type") != QuestDatabase.QuestType.MAIN:
				break
			if player_quests.has(qid):
				var info = player_quests[qid]
				var st: = _normalize_quest_status_value(info.get("status"))
				info["status"] = st
				match st:
					QuestDatabase.QuestStatus.ACTIVE, QuestDatabase.QuestStatus.IN_PROGRESS:
						_update_quest_progress_from_current_state(qid)
						if _is_quest_complete(qid):
							info["status"] = QuestDatabase.QuestStatus.COMPLETED
							pass_changed = true
							changed = true
							print("[QuestManager] 高境界结算主线进度: %s → 可领取" % qid)
					QuestDatabase.QuestStatus.LOCKED:
						if _check_quest_unlock(qid):
							pass_changed = true
							changed = true
			qid = str(qdata.get("next_quest", ""))
		if not pass_changed:
			break

	if changed:
		save_quest_data()


func _ready():
	load_quest_data()
	check_daily_reset()
	_ensure_daily_reset_timer()

	if GameManager.instance:
		GameManager.instance.game_initialized.connect(_on_game_initialized)

func _ensure_daily_reset_timer() -> void :
	if _daily_reset_check_timer != null and is_instance_valid(_daily_reset_check_timer):
		return

	_daily_reset_check_timer = Timer.new()
	_daily_reset_check_timer.wait_time = DAILY_RESET_CHECK_INTERVAL_SECONDS
	_daily_reset_check_timer.one_shot = false
	_daily_reset_check_timer.autostart = true
	_daily_reset_check_timer.timeout.connect(check_daily_reset)
	add_child(_daily_reset_check_timer)

func _get_server_now_unix() -> int:
	if not GameManager.instance:
		return -1
	var gm = GameManager.instance
	if gm.has_method("get_authoritative_unix_time"):


		return int(gm.get_authoritative_unix_time(false, 0.0))
	return -1

func _get_daily_reset_anchor(current_time: int) -> int:
	if current_time <= 0:
		return 0
	var current_datetime = Time.get_datetime_dict_from_unix_time(current_time)
	var reset_datetime = current_datetime.duplicate()
	reset_datetime.hour = DAILY_RESET_HOUR
	reset_datetime.minute = 0
	reset_datetime.second = 0
	var today_reset = Time.get_unix_time_from_datetime_dict(reset_datetime)
	if current_time < today_reset:
		today_reset -= 86400
	return today_reset

func _build_claim_rewards_from_server_payload(data: Dictionary) -> Dictionary:
	var resolved: Dictionary = {
		"exp": max(0, int(data.get("expGranted", 0))), 
		"gold": max(0, int(data.get("goldGranted", 0))), 
		"items": []
	}
	var items_out: Array[String] = []
	var granted_items: Variant = data.get("itemsGranted", [])
	if granted_items is Array:
		for raw_item in granted_items:
			if raw_item is Dictionary:
				var raw_dict: Dictionary = raw_item
				var item_name: String = str(raw_dict.get("name", "")).strip_edges()
				var item_count: int = max(0, int(raw_dict.get("count", 0)))
				if item_name.is_empty() or item_count <= 0:
					continue
				if item_count == 1:
					items_out.append(item_name)
				else:
					items_out.append("%s x%d" % [item_name, item_count])
	resolved["items"] = items_out
	if int(resolved.get("exp", 0)) <= 0 and int(resolved.get("gold", 0)) <= 0 and items_out.is_empty():
		return {}
	return resolved

func _on_game_initialized():
	print("[QuestManager] GameManager 初始化完成，开始检查任务")

	_sanitize_all_quest_status_fields()
	_check_all_quest_unlocks()
	check_capture_quest_completion()
	_check_all_active_quests_completion()
	_backfill_reach_level_quests()
	_backfill_reach_realm_quests()
	_progress_main_quest_chain_if_advanced_player()
	_check_all_quest_unlocks()

	if GameManager.instance and GameManager.instance.equipment_manager:
		GameManager.instance.equipment_manager.equipment_changed.connect(_on_equipment_changed)
		_check_equip_quest_completion()

	if GameManager.instance and GameManager.instance.pet_manager:
		if not GameManager.instance.pet_manager.pet_list_changed.is_connected(_on_pet_list_changed):
			GameManager.instance.pet_manager.pet_list_changed.connect(_on_pet_list_changed)


	call_deferred("_deferred_late_quest_repair")


func _deferred_late_quest_repair() -> void :
	if not GameManager.instance or not GameManager.instance.player:
		return
	_sanitize_all_quest_status_fields()
	_check_all_active_quests_completion()
	_backfill_reach_level_quests()
	_backfill_reach_realm_quests()
	_progress_main_quest_chain_if_advanced_player()
	_check_all_quest_unlocks()
	if GameManager.instance.equipment_manager:
		_check_equip_quest_completion()


func _backfill_reach_level_quests():
	if not GameManager.instance or not GameManager.instance.player:
		return

	var player_level = GameManager.instance.player.level
	var changed = false

	for quest_id in player_quests:
		var quest_info = player_quests[quest_id]
		if quest_info.status != QuestDatabase.QuestStatus.ACTIVE:
			continue

		var quest_data = QuestDatabase.get_quest(quest_id)
		if quest_data.is_empty():
			continue

		var objectives = quest_data.get("objectives", [])
		var has_reach_level_objective = false
		for objective in objectives:
			if _normalize_objective_type(objective.get("type", -1)) == QuestDatabase.QuestConditionType.REACH_LEVEL:
				has_reach_level_objective = true
				var objective_key = _get_objective_key(objective)
				var target_level = _get_target_count(objective)
				var old_progress = quest_info.progress.get(objective_key, 0)
				var new_progress = min(player_level, target_level)
				if new_progress > old_progress:
					quest_info.progress[objective_key] = new_progress
					changed = true
					quest_updated.emit(quest_id, quest_info.progress)
					print("[QuestManager] 登录补偿等级任务: %s %d/%d" % [quest_id, new_progress, target_level])

		if has_reach_level_objective and _is_quest_complete(quest_id):
			quest_info.status = QuestDatabase.QuestStatus.COMPLETED
			changed = true
			quest_completed.emit(quest_id)
			print("[QuestManager] 登录补偿完成任务: %s" % quest_id)

	if changed:
		save_quest_data()

func _backfill_reach_realm_quests() -> void :
	if not GameManager.instance or not GameManager.instance.player:
		return

	var player_realm: String = GameManager.instance.player.realm
	var changed: = false

	for quest_id in player_quests:
		var quest_info = player_quests[quest_id]
		if quest_info.status != QuestDatabase.QuestStatus.ACTIVE:
			continue

		var quest_data = QuestDatabase.get_quest(quest_id)
		if quest_data.is_empty():
			continue

		var objectives = quest_data.get("objectives", [])
		var has_reach_realm_objective: = false
		for objective in objectives:
			if _normalize_objective_type(objective.get("type", -1)) != QuestDatabase.QuestConditionType.REACH_REALM:
				continue
			has_reach_realm_objective = true
			var objective_key = _get_objective_key(objective)
			var target_realm: = str(objective.get("realm", ""))
			var old_progress = int(quest_info.progress.get(objective_key, 0))
			var new_progress = old_progress
			if target_realm != "" and _player_reach_realm_satisfies_objective(target_realm):
				new_progress = 1
			if new_progress > old_progress:
				quest_info.progress[objective_key] = new_progress
				changed = true
				quest_updated.emit(quest_id, quest_info.progress)
				print("[QuestManager] 登录补偿境界任务: %s 目标=%s" % [quest_id, target_realm])

		if has_reach_realm_objective and _is_quest_complete(quest_id):
			quest_info.status = QuestDatabase.QuestStatus.COMPLETED
			changed = true
			quest_completed.emit(quest_id)
			print("[QuestManager] 登录补偿完成任务(境界): %s" % quest_id)

	if changed:
		save_quest_data()

func load_quest_data():
	var save_path = "user://quest_data.json"
	var save_file = FileAccess.open(save_path, FileAccess.READ)

	if save_file:
		var json_string = save_file.get_as_text()
		save_file.close()

		if not json_string.is_empty():
			var json = JSON.new()
			var error = json.parse(json_string)
			if error == OK:
				var save_data = json.get_data()
				player_quests = save_data.get("quests", {})
				daily_reset_time = save_data.get("daily_reset_time", 0)

	_migrate_old_quest_data()
	_initialize_quests()
	_sanitize_all_quest_status_fields()

func _migrate_old_quest_data():
	var all_quest_ids = QuestDatabase.get_all_quest_ids()
	var quests_to_remove = []
	for quest_id in player_quests:
		if not all_quest_ids.has(quest_id):
			quests_to_remove.append(quest_id)

	for quest_id in quests_to_remove:
		player_quests.erase(quest_id)
		print("[QuestManager] 删除已废弃的任务: %s" % quest_id)

	for i in range(1, 22):
		var quest_id = "suit_%03d" % i
		if player_quests.has(quest_id):
			var quest_data = QuestDatabase.get_quest(quest_id)
			if not quest_data.is_empty():
				var old_progress = player_quests[quest_id].get("progress", {})
				var new_objectives = quest_data.get("objectives", [])
				var needs_reset = false

				if new_objectives.size() > 0:
					var new_floor = new_objectives[0].get("floor", new_objectives[0].get("target", 0))
					for key in old_progress:
						if old_progress[key] > new_floor:
							needs_reset = true
							break

				if needs_reset:
					player_quests[quest_id].progress = {}
					if player_quests[quest_id].status == QuestDatabase.QuestStatus.COMPLETED:
						player_quests[quest_id].status = QuestDatabase.QuestStatus.ACTIVE
					print("[QuestManager] 重置套装任务进度: %s" % quest_id)

	_migrate_element_owned_pet_quests()

func _migrate_element_owned_pet_quests():
	var element_quest_migrations = {
		"fire_002": {"old_key": "collect_烈火石", "new_key": "has_pet_火"}, 
		"water_002": {"old_key": "collect_寒冰精", "new_key": "has_pet_水"}, 
		"wood_002": {"old_key": "collect_灵木", "new_key": "has_pet_木"}, 
		"earth_002": {"old_key": "collect_金刚石", "new_key": "has_pet_土"}, 
		"metal_002": {"old_key": "collect_玄铁", "new_key": "has_pet_金"}
	}

	for quest_id in element_quest_migrations.keys():
		if not player_quests.has(quest_id):
			continue

		var quest_info = player_quests[quest_id]
		if typeof(quest_info) != TYPE_DICTIONARY:
			continue

		if not quest_info.has("progress") or typeof(quest_info.get("progress", {})) != TYPE_DICTIONARY:
			quest_info["progress"] = {}

		var migration = element_quest_migrations[quest_id]
		var old_key = migration.get("old_key", "")
		var new_key = migration.get("new_key", "")
		var progress: Dictionary = quest_info.get("progress", {})
		var changed = false


		if not old_key.is_empty() and progress.has(old_key):
			progress.erase(old_key)
			changed = true

		var status = int(quest_info.get("status", QuestDatabase.QuestStatus.LOCKED))
		if status != QuestDatabase.QuestStatus.FINISHED:

			if not new_key.is_empty() and progress.get(new_key, 0) != 0:
				progress[new_key] = 0
				changed = true

			if status == QuestDatabase.QuestStatus.COMPLETED:
				quest_info["status"] = QuestDatabase.QuestStatus.ACTIVE
				changed = true

		if changed:
			quest_info["progress"] = progress
			player_quests[quest_id] = quest_info
			print("[QuestManager] 元素任务条件迁移完成: %s" % quest_id)

func save_quest_data():
	var save_data = {
		"quests": player_quests, 
		"daily_reset_time": daily_reset_time
	}

	var json_string = JSON.stringify(save_data)
	var save_file = FileAccess.open("user://quest_data.json", FileAccess.WRITE)
	if save_file:
		save_file.store_string(json_string)
		save_file.close()

func to_dict() -> Dictionary:
	return {
		"quests": player_quests, 
		"daily_reset_time": daily_reset_time
	}

func from_dict(data: Dictionary):
	if data.has("quests"):
		player_quests = data.get("quests", {})
	if data.has("daily_reset_time"):
		daily_reset_time = data.get("daily_reset_time", 0)
	_migrate_old_quest_data()
	_initialize_quests()
	_sanitize_all_quest_status_fields()

	check_daily_reset()

func _initialize_quests():
	var all_quests = QuestDatabase.get_all_quest_ids()

	for quest_id in all_quests:
		if not player_quests.has(quest_id):
			player_quests[quest_id] = {
				"status": QuestDatabase.QuestStatus.LOCKED, 
				"progress": {}, 
				"completed_time": 0
			}

func _check_all_active_quests_completion():
	print("[QuestManager] 开始检查所有激活任务")
	for quest_id in player_quests:
		var quest_info = player_quests[quest_id]
		var pst: = _normalize_quest_status_value(quest_info.get("status"))
		quest_info["status"] = pst
		if pst == QuestDatabase.QuestStatus.ACTIVE:
			print("[QuestManager] 检查任务 %s" % quest_id)
			_update_quest_progress_from_current_state(quest_id)

			if _is_quest_complete(quest_id):
				quest_info.status = QuestDatabase.QuestStatus.COMPLETED
				quest_completed.emit(quest_id)
				print("[QuestManager] 任务 %s 在启动时检测为已完成" % quest_id)

	save_quest_data()
	print("[QuestManager] 完成所有激活任务检查")

func _update_quest_progress_from_current_state(quest_id: String):
	var quest_data = QuestDatabase.get_quest(quest_id)
	if quest_data.is_empty():
		return

	var quest_info = player_quests[quest_id]
	print("[QuestManager] 更新任务 %s 进度" % quest_id)

	var objectives = quest_data.get("objectives", [])
	for objective in objectives:
		var objective_key = _get_objective_key(objective)
		var current_progress = 0
		var old_progress: = _normalize_objective_progress_value(quest_info.progress.get(objective_key, 0))

		var objective_type = _normalize_objective_type(objective.get("type", -1))

		match objective_type:
			QuestDatabase.QuestConditionType.REACH_LEVEL:
				if GameManager.instance and GameManager.instance.player:
					var target_level = objective.get("target", objective.get("level", 1))
					current_progress = min(GameManager.instance.player.level, target_level)
					print("[QuestManager] REACH_LEVEL: 玩家等级=%d, 目标=%d, 进度=%d" % [GameManager.instance.player.level, target_level, current_progress])

			QuestDatabase.QuestConditionType.REACH_REALM:
				if GameManager.instance and GameManager.instance.player:
					var target_realm = str(objective.get("realm", ""))
					if _player_reach_realm_satisfies_objective(target_realm):
						current_progress = 1
					print("[QuestManager] REACH_REALM: 玩家境界=%s, 目标=%s 满足=%s" % [GameManager.instance.player.realm, target_realm, str(current_progress >= 1)])

			QuestDatabase.QuestConditionType.CAPTURE_PET:
				if GameManager.instance and GameManager.instance.pet_manager:
					var pet_element = objective.get("pet_element", "")
					var target_count = objective.get("target", 1)
					var pet_count = 0
					if objective.get("require_owned_pet", false):
						pet_count = _get_owned_pet_count_by_element(pet_element)
					else:
						if pet_element.is_empty():
							pet_count = GameManager.instance.pet_manager.get_pet_count()
						else:
							pet_count = GameManager.instance.pet_manager.get_pet_count_by_element(pet_element)
					current_progress = min(pet_count, target_count)
					print("[QuestManager] CAPTURE_PET: 元素=%s 数量=%d 进度=%d/%d" % [pet_element if not pet_element.is_empty() else "任意", pet_count, current_progress, target_count])

			QuestDatabase.QuestConditionType.COLLECT_ITEM:
				if GameManager.instance and GameManager.instance.inventory_manager:
					var item_name = objective.get("item", "")
					if not item_name.is_empty():
						var item_count = GameManager.instance.inventory_manager.get_item_count(item_name)
						current_progress = min(item_count, objective.get("target", 1))
						print("[QuestManager] COLLECT_ITEM: 物品%s数量=%d" % [item_name, item_count])

			QuestDatabase.QuestConditionType.REACH_PET_LEVEL:
				if GameManager.instance and GameManager.instance.pet_manager:
					var pet_element = objective.get("pet_element", "")
					var target_level = objective.get("target", 1)
					var max_level = 0
					if pet_element.is_empty():
						max_level = GameManager.instance.pet_manager.get_max_pet_level()
					else:
						max_level = GameManager.instance.pet_manager.get_max_pet_level_by_element(pet_element)
					current_progress = min(max_level, target_level)
					print("[QuestManager] REACH_PET_LEVEL: 最高等级=%d, 目标=%d" % [max_level, target_level])

			QuestDatabase.QuestConditionType.EQUIP_ITEM:
				if GameManager.instance and GameManager.instance.equipment_manager:
					var required_rarity = str(objective.get("rarity", "any")).strip_edges()
					var equipped_count = _count_equipped_items(required_rarity)
					current_progress = min(equipped_count, objective.get("target", 1))
					print("[QuestManager] EQUIP_ITEM: 已装备%s品质=%d" % [required_rarity, equipped_count])

			QuestDatabase.QuestConditionType.COMPLETE_TOWER:
				if objective.get("count_mode", false):
					print("[QuestManager] COMPLETE_TOWER: count_mode跳过")
				elif GameManager.instance and GameManager.instance.player:
					var target_floor = objective.get("floor", objective.get("target", 1))
					var current_floor = GameManager.instance.player.tower_highest
					current_progress = min(current_floor, target_floor)
					print("[QuestManager] COMPLETE_TOWER: 最高层=%d, 目标=%d" % [current_floor, target_floor])

			QuestDatabase.QuestConditionType.COMPLETE_SUIT_DUNGEON:
				if objective.get("count_mode", false):
					print("[QuestManager] COMPLETE_SUIT_DUNGEON: count_mode跳过")
				elif GameManager.instance and GameManager.instance.player:
					var target_floor = objective.get("floor", objective.get("target", 1))
					var current_floor = GameManager.instance.player.suit_dungeon_progress
					current_progress = min(current_floor, target_floor)
					print("[QuestManager] COMPLETE_SUIT_DUNGEON: 最高层=%d, 目标=%d" % [current_floor, target_floor])

			QuestDatabase.QuestConditionType.BATTLE_COUNT:
				print("[QuestManager] BATTLE_COUNT: 无法从当前状态检测，保持现有进度")
				current_progress = old_progress

			QuestDatabase.QuestConditionType.UNLOCK_PET_COLLECTION:
				if GameManager.instance and GameManager.instance.pet_collection_manager:
					var activated_count = GameManager.instance.pet_collection_manager.get_activated_count()
					current_progress = min(activated_count, objective.get("target", 1))
					print("[QuestManager] UNLOCK_PET_COLLECTION: 已激活图鉴=%d, 目标=%d" % [activated_count, objective.get("target", 1)])

			QuestDatabase.QuestConditionType.JOIN_XIANMO_BATTLE:
				print("[QuestManager] JOIN_XIANMO_BATTLE: 无法从当前状态检测，保持现有进度")
				current_progress = old_progress

			_:
				print("[QuestManager] 未知类型: %d" % objective.get("type", -1))

		print("[QuestManager] 进度更新: %s 从 %d 到 %d" % [objective_key, old_progress, current_progress])
		var allow_progress_decrease = objective_type == QuestDatabase.QuestConditionType.CAPTURE_PET and objective.get("require_owned_pet", false)
		if allow_progress_decrease:
			if current_progress != old_progress:
				quest_info.progress[objective_key] = current_progress
		elif current_progress > old_progress:
			quest_info.progress[objective_key] = current_progress

func _normalize_objective_type(objective_type: int) -> int:
	if objective_type == QuestDatabase.QuestConditionType.CLEAR_TOWER:
		return QuestDatabase.QuestConditionType.COMPLETE_TOWER
	if objective_type == QuestDatabase.QuestConditionType.CLEAR_SUIT_DUNGEON:
		return QuestDatabase.QuestConditionType.COMPLETE_SUIT_DUNGEON
	return objective_type

func _pet_matches_objective_element(pet, pet_element: String) -> bool:
	if pet == null:
		return false
	if pet_element.is_empty():
		return true
	return str(pet.element) == pet_element

func _get_owned_pet_count_by_element(pet_element: String) -> int:
	if not GameManager.instance or not GameManager.instance.pet_manager:
		return 0

	var pet_manager = GameManager.instance.pet_manager
	var count = 0
	for pet in pet_manager.get_all_pets():
		if _pet_matches_objective_element(pet, pet_element):
			count += 1

	for pet in pet_manager.get_all_pets_in_bag():
		if _pet_matches_objective_element(pet, pet_element):
			count += 1

	return count

func _check_quest_unlock(quest_id: String) -> bool:
	if quest_id == null or str(quest_id).is_empty():
		return false

	var quest_data = QuestDatabase.get_quest(quest_id)
	if quest_data.is_empty():
		return false

	if not player_quests.has(quest_id):
		return false

	var current_status: = _normalize_quest_status_value(player_quests[quest_id].get("status"))
	player_quests[quest_id]["status"] = current_status
	if current_status != QuestDatabase.QuestStatus.LOCKED:
		return false

	if not GameManager.instance or not GameManager.instance.player:
		return false

	var can_unlock = true

	if quest_data.has("unlock_level"):
		if GameManager.instance.player.level < quest_data.get("unlock_level"):
			can_unlock = false

	if can_unlock and quest_data.has("unlock_realm"):
		var required_realm: = str(quest_data.get("unlock_realm"))
		var required_index: = GameData.REALMS.find(required_realm)
		if required_index >= 0:
			var player_realm_index: = GameData.REALMS.find(str(GameManager.instance.player.realm))
			if player_realm_index < 0:
				player_realm_index = GameData.REALMS.size() - 1
			elif player_realm_index < required_index:
				can_unlock = false

	if can_unlock and quest_data.has("unlock_tower"):
		if GameManager.instance.player.tower_highest < quest_data.get("unlock_tower"):
			can_unlock = false

	if can_unlock and quest_data.has("unlock_suit_dungeon"):
		if GameManager.instance.player.suit_dungeon_progress < quest_data.get("unlock_suit_dungeon"):
			can_unlock = false

	if can_unlock:
		var all_quests = QuestDatabase.get_all_quest_ids()
		for check_quest_id in all_quests:
			var check_quest = QuestDatabase.get_quest(check_quest_id)
			if check_quest.has("next_quest") and check_quest.get("next_quest") == quest_id:
				if player_quests.has(check_quest_id):
					var pre_status: = _normalize_quest_status_value(player_quests[check_quest_id].get("status"))
					player_quests[check_quest_id]["status"] = pre_status
					var predecessor_met: = (
						pre_status == QuestDatabase.QuestStatus.FINISHED
						or pre_status == QuestDatabase.QuestStatus.COMPLETED
						or (
							pre_status == QuestDatabase.QuestStatus.ACTIVE
							and _is_quest_complete(check_quest_id)
						)
					)
					if not predecessor_met:
						can_unlock = false
						break
				else:
					can_unlock = false
					break

	if can_unlock:
		player_quests[quest_id].status = QuestDatabase.QuestStatus.ACTIVE
		_initialize_quest_progress(quest_id)

		if _is_quest_complete(quest_id):
			player_quests[quest_id].status = QuestDatabase.QuestStatus.COMPLETED
			quest_completed.emit(quest_id)
			print("[QuestManager] 任务 %s 解锁后立即完成" % quest_id)

		save_quest_data()
		return true

	return false

func check_capture_quest_completion():
	if not player_quests.has("quest_002"):
		return

	var quest_info = player_quests["quest_002"]

	if quest_info.status == QuestDatabase.QuestStatus.COMPLETED or quest_info.status == QuestDatabase.QuestStatus.FINISHED:
		return

	var has_pet = false
	if GameManager.instance and GameManager.instance.pet_manager:
		has_pet = GameManager.instance.pet_manager.get_pet_count() > 0

	if has_pet:
		if quest_info.status == QuestDatabase.QuestStatus.LOCKED:
			quest_info.status = QuestDatabase.QuestStatus.ACTIVE
		quest_info.progress["capture_pet"] = 1
		quest_info.status = QuestDatabase.QuestStatus.COMPLETED
		save_quest_data()
		quest_completed.emit("quest_002")
		print("[QuestManager] 捕捉任务自动完成")

func _initialize_quest_progress(quest_id: String):
	var quest_data = QuestDatabase.get_quest(quest_id)
	if quest_data.is_empty():
		return
	player_quests[quest_id].progress = {}

	var objectives = quest_data.get("objectives", [])
	for objective in objectives:
		var objective_key = _get_objective_key(objective)
		var initial_progress = 0

		var objective_type = _normalize_objective_type(objective.get("type", -1))

		match objective_type:
			QuestDatabase.QuestConditionType.REACH_LEVEL:
				if GameManager.instance and GameManager.instance.player:
					var target_level = objective.get("target", objective.get("level", 1))
					initial_progress = min(GameManager.instance.player.level, target_level)

			QuestDatabase.QuestConditionType.REACH_REALM:
				if GameManager.instance and GameManager.instance.player:
					if _player_reach_realm_satisfies_objective(str(objective.get("realm", ""))):
						initial_progress = 1

			QuestDatabase.QuestConditionType.CAPTURE_PET:
				if GameManager.instance and GameManager.instance.pet_manager:
					var pet_element = objective.get("pet_element", "")
					var target_count = objective.get("target", 1)
					if objective.get("require_owned_pet", false):
						initial_progress = min(_get_owned_pet_count_by_element(pet_element), target_count)
					else:
						if pet_element.is_empty():
							initial_progress = min(GameManager.instance.pet_manager.get_pet_count(), target_count)
						else:
							var count = GameManager.instance.pet_manager.get_pet_count_by_element(pet_element)
							initial_progress = min(count, target_count)

			QuestDatabase.QuestConditionType.COLLECT_ITEM:
				if GameManager.instance and GameManager.instance.inventory_manager:
					var item_name = objective.get("item", "")
					if not item_name.is_empty():
						var count = GameManager.instance.inventory_manager.get_item_count(item_name)
						initial_progress = min(count, objective.get("target", 1))

			QuestDatabase.QuestConditionType.REACH_PET_LEVEL:
				if GameManager.instance and GameManager.instance.pet_manager:
					var pet_element = objective.get("pet_element", "")
					var target_level = objective.get("target", 1)
					if pet_element.is_empty():
						var max_level = GameManager.instance.pet_manager.get_max_pet_level()
						initial_progress = min(max_level, target_level)
					else:
						var max_level = GameManager.instance.pet_manager.get_max_pet_level_by_element(pet_element)
						initial_progress = min(max_level, target_level)

			QuestDatabase.QuestConditionType.EQUIP_ITEM:
				if GameManager.instance and GameManager.instance.equipment_manager:
					var required_rarity = str(objective.get("rarity", "any")).strip_edges()
					var equipped_count = _count_equipped_items(required_rarity)
					initial_progress = min(equipped_count, objective.get("target", 1))

			QuestDatabase.QuestConditionType.COMPLETE_TOWER:
				if not objective.get("count_mode", false) and GameManager.instance and GameManager.instance.player:
					var target_floor = objective.get("floor", objective.get("target", 1))
					var current_floor = GameManager.instance.player.tower_highest
					initial_progress = min(current_floor, target_floor)

			QuestDatabase.QuestConditionType.COMPLETE_SUIT_DUNGEON:
				if not objective.get("count_mode", false) and GameManager.instance and GameManager.instance.player:
					var target_floor = objective.get("floor", objective.get("target", 1))
					var current_floor = GameManager.instance.player.suit_dungeon_progress
					initial_progress = min(current_floor, target_floor)

			QuestDatabase.QuestConditionType.UNLOCK_PET_COLLECTION:
				if GameManager.instance and GameManager.instance.pet_collection_manager:
					var activated_count = GameManager.instance.pet_collection_manager.get_activated_count()
					initial_progress = min(activated_count, objective.get("target", 1))

			QuestDatabase.QuestConditionType.JOIN_XIANMO_BATTLE:
				pass

		player_quests[quest_id].progress[objective_key] = initial_progress
		print("[QuestManager] 初始化任务 %s 目标 %s 进度: %d" % [quest_id, objective_key, initial_progress])

func _get_objective_key(objective: Dictionary) -> String:
	var objective_type = _normalize_objective_type(objective.get("type", -1))

	match objective_type:
		QuestDatabase.QuestConditionType.KILL_MONSTER:
			if objective.has("monster_id"):
				return "kill_" + str(objective.get("monster_id"))
			elif objective.has("map"):
				return "kill_map_" + str(objective.get("map"))
			else:
				return "kill_any"
		QuestDatabase.QuestConditionType.KILL_MONSTER_TYPE:
			return "kill_type_" + objective.get("element", "any")
		QuestDatabase.QuestConditionType.COMPLETE_MAP:
			return "complete_map_" + str(objective.get("target"))
		QuestDatabase.QuestConditionType.CAPTURE_PET:
			if objective.get("require_owned_pet", false):
				return "has_pet_" + objective.get("pet_element", "any")
			return "capture_pet"
		QuestDatabase.QuestConditionType.REACH_LEVEL:
			return "reach_level"
		QuestDatabase.QuestConditionType.REACH_REALM:
			return "reach_realm"
		QuestDatabase.QuestConditionType.COMPLETE_TOWER:
			return "complete_tower"
		QuestDatabase.QuestConditionType.COMPLETE_SUIT_DUNGEON:
			return "complete_suit_dungeon"
		QuestDatabase.QuestConditionType.BATTLE_COUNT:
			return "battle_count"
		QuestDatabase.QuestConditionType.USE_ITEM:
			return "use_item_" + objective.get("item_type", "any")
		QuestDatabase.QuestConditionType.EQUIP_ITEM:
			return "equip_" + objective.get("rarity", "any")
		QuestDatabase.QuestConditionType.REACH_PET_LEVEL:
			return "reach_pet_level_" + objective.get("pet_element", "any")
		QuestDatabase.QuestConditionType.EVOLVE_PET:
			return "evolve_pet"
		QuestDatabase.QuestConditionType.FUSE_PET:
			return "fuse_pet"
		QuestDatabase.QuestConditionType.COLLECT_ITEM:
			return "collect_" + objective.get("item", "any")
		QuestDatabase.QuestConditionType.COMPLETE_QUEST:
			return "complete_quest_" + objective.get("quest_id", "any")
		QuestDatabase.QuestConditionType.UNLOCK_PET_COLLECTION:
			return "unlock_pet_collection"
		QuestDatabase.QuestConditionType.JOIN_XIANMO_BATTLE:
			return "join_xianmo_battle"
		_:
			return str(objective.get("type", -1))

func update_quest_progress(event_type: int, params: Dictionary = {}):
	var updated = false

	for quest_id in player_quests:
		var quest_info = player_quests[quest_id]
		var pst: = _normalize_quest_status_value(quest_info.get("status"))
		quest_info["status"] = pst
		if pst != QuestDatabase.QuestStatus.ACTIVE:
			continue

		var quest_data = QuestDatabase.get_quest(quest_id)
		if quest_data.is_empty():
			continue

		var objectives = quest_data.get("objectives", [])
		for objective in objectives:
			var objective_type = _normalize_objective_type(objective.get("type", -1))

			if objective_type != event_type:
				continue

			var objective_key = _get_objective_key(objective)
			var current_progress: = _normalize_objective_progress_value(quest_info.progress.get(objective_key, 0))

			var target_count = _get_target_count(objective)

			var should_update = _check_objective_match(objective, params)

			if should_update and current_progress < target_count:
				var new_progress = _calculate_new_progress(objective, current_progress, params, target_count)

				quest_info.progress[objective_key] = new_progress
				updated = true
				quest_updated.emit(quest_id, quest_info.progress)
				print("[QuestManager] 任务 %s 进度更新: %s = %d/%d" % [quest_id, objective_key, new_progress, target_count])

			if _is_quest_complete(quest_id):
				quest_info.status = QuestDatabase.QuestStatus.COMPLETED
				quest_completed.emit(quest_id)

	if updated:
		save_quest_data()

func _get_target_count(objective: Dictionary) -> int:
	var objective_type = _normalize_objective_type(objective.get("type", -1))

	match objective_type:
		QuestDatabase.QuestConditionType.REACH_LEVEL:
			return objective.get("target", objective.get("level", 1))
		QuestDatabase.QuestConditionType.REACH_REALM:
			return 1
		QuestDatabase.QuestConditionType.COMPLETE_TOWER:
			return objective.get("floor", objective.get("target", objective.get("count", 1)))
		QuestDatabase.QuestConditionType.COMPLETE_SUIT_DUNGEON:
			return objective.get("floor", objective.get("target", objective.get("count", 1)))
		_:
			return objective.get("count", objective.get("target", 1))

func _calculate_new_progress(objective: Dictionary, current_progress: int, params: Dictionary, target_count: int) -> int:
	var objective_type = _normalize_objective_type(objective.get("type", -1))

	match objective_type:
		QuestDatabase.QuestConditionType.REACH_LEVEL:
			if GameManager.instance and GameManager.instance.player:
				return min(GameManager.instance.player.level, target_count)
			return current_progress + 1

		QuestDatabase.QuestConditionType.REACH_REALM:
			if _player_reach_realm_satisfies_objective(str(objective.get("realm", ""))):
				return target_count
			return current_progress

		QuestDatabase.QuestConditionType.COMPLETE_TOWER, QuestDatabase.QuestConditionType.COMPLETE_SUIT_DUNGEON:
			if not objective.get("count_mode", false) and params.has("floor"):
				return min(params.floor, target_count)
			return current_progress + 1

		_:
			return current_progress + 1

func _check_objective_match(objective: Dictionary, params: Dictionary) -> bool:
	var objective_type = _normalize_objective_type(objective.get("type", -1))

	match objective_type:
		QuestDatabase.QuestConditionType.KILL_MONSTER:
			if objective.has("monster_id"):
				return params.get("monster_id", "") == str(objective.get("monster_id"))
			if objective.has("map"):
				return params.get("map_name", "") == objective.get("map")
			return true

		QuestDatabase.QuestConditionType.KILL_MONSTER_TYPE:
			var element = objective.get("element", "any")
			if element == "any":
				return true
			return params.get("element", "") == element

		QuestDatabase.QuestConditionType.CAPTURE_PET:
			if objective.get("require_owned_pet", false):
				return false
			var pet_element = objective.get("pet_element", "")
			if pet_element.is_empty():
				return true
			return params.get("element", "") == pet_element

		QuestDatabase.QuestConditionType.COMPLETE_MAP:
			return params.get("map_name", "") == str(objective.get("target"))

		QuestDatabase.QuestConditionType.COMPLETE_TOWER:
			if objective.get("count_mode", false):
				return true
			if objective.has("floor"):
				return params.get("floor", 0) >= objective.get("floor", 1)
			return true

		QuestDatabase.QuestConditionType.COMPLETE_SUIT_DUNGEON:
			if objective.get("count_mode", false):
				return true
			if objective.has("floor"):
				return params.get("floor", 0) >= objective.get("floor", 1)
			return true

		QuestDatabase.QuestConditionType.REACH_LEVEL:
			if GameManager.instance and GameManager.instance.player:
				var target_level = objective.get("target", objective.get("level", 1))
				return GameManager.instance.player.level >= target_level
			return false

		QuestDatabase.QuestConditionType.REACH_REALM:
			return _player_reach_realm_satisfies_objective(str(objective.get("realm", "")))

		_:
			return true

func _is_quest_complete(quest_id: String) -> bool:
	var quest_data = QuestDatabase.get_quest(quest_id)
	if quest_data.is_empty():
		return false
	var quest_info = player_quests[quest_id]

	var objectives = quest_data.get("objectives", [])
	for objective in objectives:
		var objective_key = _get_objective_key(objective)
		var current: = _normalize_objective_progress_value(quest_info.progress.get(objective_key, 0))
		var target = _get_target_count(objective)

		if current < target:
			print("[QuestManager] 任务 %s 未完成: %s = %d/%d" % [quest_id, objective_key, current, target])
			return false

	print("[QuestManager] 任务 %s 已完成!" % quest_id)
	return true


func try_merge_quest_state_from_server_payload(payload: Variant) -> bool:
	if payload == null or not payload is Dictionary:
		return false
	var d: Dictionary = payload as Dictionary
	var qd: Variant = d.get("questData", null)
	if qd == null or not qd is Dictionary:
		var sd: Variant = d.get("saveData", null)
		if sd is Dictionary:
			qd = (sd as Dictionary).get("questData", null)
	if qd == null or not qd is Dictionary:
		return false
	var qdict: Dictionary = qd as Dictionary
	if not qdict.has("quests"):
		return false
	from_dict(qdict)
	save_quest_data()
	return true

func claim_quest_reward(quest_id: String) -> Dictionary:
	var quest_info = player_quests.get(quest_id)
	if not quest_info:
		return {"ok": false, "rewards": {}, "err": "任务不存在"}

	var quest_data = QuestDatabase.get_quest(quest_id)
	if quest_data.is_empty():
		return {"ok": false, "rewards": {}, "err": "任务配置缺失"}

	if int(quest_data.get("type", -1)) == QuestDatabase.QuestType.DAILY:
		check_daily_reset()
		quest_info = player_quests.get(quest_id, quest_info)
		var current_time: = _get_server_now_unix()
		if current_time <= 0:
			current_time = int(Time.get_unix_time_from_system())
		var current_reset_anchor: = _get_daily_reset_anchor(current_time)
		var completed_time: = int(quest_info.get("completed_time", 0))
		if completed_time > 0 and completed_time >= current_reset_anchor:
			return {"ok": false, "rewards": {}, "err": "今日已领取该日常奖励"}

	var st_claim: = _normalize_quest_status_value(quest_info.get("status"))
	quest_info["status"] = st_claim
	if st_claim != QuestDatabase.QuestStatus.COMPLETED:
		return {"ok": false, "rewards": {}, "err": "当前不可领取奖励"}

	var rewards = quest_data.get("rewards", {})
	var display_rewards: Dictionary = rewards.duplicate(true) if rewards is Dictionary else {}

	if GameManager.instance and GameManager.instance.player:
		var gm = GameManager.instance
		if gm.network and gm.network.is_logged_in():


			var st_sync: Dictionary = gm.start_force_cloud_upload_wait("quest_claim_presync", false, 35.0)
			var sync_ok: bool = await gm.wait_commit_secure_op(st_sync)
			if not sync_ok:
				return {"ok": false, "rewards": {}, "err": "任务状态同步失败，请稍后重试"}
			var op_id: = "quest_%s_%s_%s" % [quest_id, str(Time.get_unix_time_from_system()), str(randi())]
			var er: Dictionary = await gm.wait_economy("economy_quest_claim", func():
				gm.network.economy_quest_claim(op_id, quest_id)
			)
			if not er.get("ok", false):
				var err_txt: = str(er.get("err", ""))
				if err_txt.is_empty():
					err_txt = "服务端领奖失败，请稍后重试或同步存档"
				push_warning("[Quest] 服务端领奖失败: " + err_txt)
				if not try_merge_quest_state_from_server_payload(er.get("data", {})):
					gm.download_cloud_save()
				return {"ok": false, "rewards": {}, "err": err_txt}
			var qd: Variant = er.get("data", {})
			if qd is Dictionary:
				var d: Dictionary = qd
				var server_rewards: = _build_claim_rewards_from_server_payload(d)
				if not server_rewards.is_empty():
					display_rewards = server_rewards
				if d.has("newGold"):
					gm.player.gold = int(d.get("newGold", gm.player.gold))
				gm.gold_changed.emit(gm.player.gold)
				var ps_var: Variant = d.get("playerSync", {})
				if ps_var is Dictionary:
					var ps: Dictionary = ps_var
					var old_level: int = int(gm.player.level)
					gm.player.level = int(ps.get("level", gm.player.level))
					gm.player.experience = int(ps.get("experience", gm.player.experience))
					gm.player.max_hp = int(ps.get("max_hp", gm.player.max_hp))
					gm.player.hp = int(ps.get("hp", gm.player.hp))
					gm.player.points = int(ps.get("points", gm.player.points))
					gm.player.pending_auto_points = int(ps.get("pending_auto_points", gm.player.pending_auto_points))
					gm.player.cultivation = int(ps.get("cultivation", gm.player.cultivation))
					var req_exp: = GameData.get_required_exp(gm.player.level)
					gm.player.exp_changed.emit(gm.player.experience, req_exp)
					if gm.player.level != old_level:
						gm.player.level_up.emit(gm.player.level)
				var ig_var: Variant = d.get("itemsGranted", [])
				if ig_var is Array and gm.inventory_manager:
					for it in ig_var:
						if it is Dictionary:
							var nm: = str(it.get("name", ""))
							var cnt: = int(it.get("count", 1))
							if nm != "" and cnt > 0:
								gm.inventory_manager.add_item(nm, cnt)
		else:
			return {"ok": false, "rewards": {}, "err": "请先联网登录后再领取奖励"}

	quest_info.status = QuestDatabase.QuestStatus.FINISHED
	quest_info.completed_time = Time.get_unix_time_from_system()

	var next_quest = quest_data.get("next_quest")
	if next_quest and not str(next_quest).is_empty():
		_check_quest_unlock(str(next_quest))

	save_quest_data()
	quest_reward_claimed.emit(quest_id, display_rewards)

	return {"ok": true, "rewards": display_rewards, "err": ""}

func check_daily_reset():
	var current_time: = _get_server_now_unix()
	if current_time <= 0:
		current_time = int(Time.get_unix_time_from_system())
		if current_time <= 0:
			return
	var current_reset_anchor: = _get_daily_reset_anchor(current_time)
	if current_reset_anchor <= 0:
		return

	if daily_reset_time < current_reset_anchor:
		_reset_daily_quests()
		daily_reset_time = current_reset_anchor
		save_quest_data()
		daily_quests_reset.emit()

		_schedule_daily_reset_cloud_upload()

func _get_daily_reset_upload_delay_sec() -> float:
	var uid: = 0
	if GameManager.instance and GameManager.instance.network:
		uid = int(GameManager.instance.network.user_id)
	if uid <= 0:
		return float(randi() % (DAILY_RESET_UPLOAD_STAGGER_MAX_SEC + 1))

	return float(absi(uid * 2654435761) % (DAILY_RESET_UPLOAD_STAGGER_MAX_SEC + 1))

func _schedule_daily_reset_cloud_upload() -> void :
	if not GameManager.instance or not GameManager.instance.network:
		return
	if not GameManager.instance.network.is_logged_in():
		return
	_daily_reset_upload_pending = true
	var delay: = _get_daily_reset_upload_delay_sec()
	if _daily_reset_upload_timer != null and is_instance_valid(_daily_reset_upload_timer):
		_daily_reset_upload_timer.stop()
		_daily_reset_upload_timer.queue_free()
		_daily_reset_upload_timer = null
	_daily_reset_upload_timer = Timer.new()
	_daily_reset_upload_timer.one_shot = true
	_daily_reset_upload_timer.wait_time = maxf(0.05, delay)
	add_child(_daily_reset_upload_timer)
	_daily_reset_upload_timer.timeout.connect(_on_daily_reset_cloud_upload_timeout)
	_daily_reset_upload_timer.start()

func _on_daily_reset_cloud_upload_timeout() -> void :
	if _daily_reset_upload_timer != null and is_instance_valid(_daily_reset_upload_timer):
		_daily_reset_upload_timer.queue_free()
		_daily_reset_upload_timer = null
	if not _daily_reset_upload_pending:
		return
	_daily_reset_upload_pending = false
	if GameManager.instance and GameManager.instance.network and GameManager.instance.network.is_logged_in():
		GameManager.instance.save_game(true)

func _reset_daily_quests():
	var daily_quests = QuestDatabase.get_quests_by_type(QuestDatabase.QuestType.DAILY)

	for quest_data in daily_quests:
		var quest_id = quest_data.get("id")
		if player_quests.has(quest_id):
			player_quests[quest_id].status = QuestDatabase.QuestStatus.ACTIVE
			player_quests[quest_id].progress = {}
			_initialize_quest_progress(quest_id)

func get_quests_by_type(quest_type: int) -> Array:
	var result = []
	var quests = QuestDatabase.get_quests_by_type(quest_type)

	for quest_data in quests:
		var quest_id = quest_data.get("id")
		var quest_info = player_quests.get(quest_id, {})
		var raw_st = quest_info.get("status", QuestDatabase.QuestStatus.LOCKED)
		var disp_st: = _normalize_quest_status_value(raw_st)
		if quest_info is Dictionary and quest_info.get("status") != disp_st:
			quest_info["status"] = disp_st
			player_quests[quest_id] = quest_info

		result.append({
			"data": quest_data, 
			"status": disp_st, 
			"progress": quest_info.get("progress", {})
		})

	return result

func get_active_quests() -> Array:
	var result = []

	for quest_id in player_quests:
		var quest_info = player_quests[quest_id]
		if quest_info.status == QuestDatabase.QuestStatus.ACTIVE or quest_info.status == QuestDatabase.QuestStatus.COMPLETED:
			var quest_data = QuestDatabase.get_quest(quest_id)
			if not quest_data.is_empty():
				result.append({
					"data": quest_data, 
					"status": quest_info.status, 
					"progress": quest_info.progress
				})

	return result

func get_quest_status(quest_id: String) -> int:
	if player_quests.has(quest_id):
		var ns: = _normalize_quest_status_value(player_quests[quest_id].get("status"))
		player_quests[quest_id]["status"] = ns
		return ns
	return QuestDatabase.QuestStatus.LOCKED

func get_quest_progress(quest_id: String) -> Dictionary:
	if player_quests.has(quest_id):
		return player_quests[quest_id].progress
	return {}

func teleport_to_quest_map(quest_id: String) -> bool:
	var quest_data = QuestDatabase.get_quest(quest_id)
	if quest_data.is_empty():
		return false

	var destination_map: = str(quest_data.get("teleport_map", ""))
	if destination_map.is_empty():
		var objectives: Array = quest_data.get("objectives", [])
		for objective in objectives:
			if objective is Dictionary and objective.has("map"):
				destination_map = str(objective.get("map", ""))
				if not destination_map.is_empty():
					break

	if destination_map.is_empty():
		if GameManager.instance and GameManager.instance.has_method("show_message"):
			GameManager.instance.show_message("该任务暂无可传送目标")
		return false

	if not GameManager.instance or not GameManager.instance.player:
		return false

	var changed: = GameManager.instance.change_map(destination_map)
	if changed:
		if GameManager.instance.has_method("show_message"):
			GameManager.instance.show_message("已传送至 " + destination_map)
	else:
		if GameManager.instance.has_method("show_message"):
			GameManager.instance.show_message("传送失败：无效地图")

	return changed

func on_battle_completed(map_name: String, monster_id: String, element: String):
	update_quest_progress(QuestDatabase.QuestConditionType.COMPLETE_MAP, {"map_name": map_name})
	update_quest_progress(QuestDatabase.QuestConditionType.KILL_MONSTER, {"monster_id": monster_id, "map_name": map_name})
	update_quest_progress(QuestDatabase.QuestConditionType.KILL_MONSTER_TYPE, {"element": element})
	update_quest_progress(QuestDatabase.QuestConditionType.BATTLE_COUNT)

func on_pet_captured(pet_element: String = ""):
	update_quest_progress(QuestDatabase.QuestConditionType.CAPTURE_PET)
	if not pet_element.is_empty():
		update_quest_progress(QuestDatabase.QuestConditionType.CAPTURE_PET, {"element": pet_element})

func _on_pet_list_changed():
	_refresh_owned_pet_objectives()

func _refresh_owned_pet_objectives():
	var changed = false

	for quest_id in player_quests:
		var quest_info = player_quests[quest_id]
		if quest_info.status != QuestDatabase.QuestStatus.ACTIVE:
			continue

		var quest_data = QuestDatabase.get_quest(quest_id)
		if quest_data.is_empty():
			continue

		var has_owned_pet_objective = false
		for objective in quest_data.get("objectives", []):
			var objective_type = _normalize_objective_type(objective.get("type", -1))
			if objective_type == QuestDatabase.QuestConditionType.CAPTURE_PET and objective.get("require_owned_pet", false):
				has_owned_pet_objective = true
				break

		if not has_owned_pet_objective:
			continue

		var old_progress: Dictionary = quest_info.progress.duplicate(true)
		_update_quest_progress_from_current_state(quest_id)
		if quest_info.progress != old_progress:
			changed = true
			quest_updated.emit(quest_id, quest_info.progress)

		if _is_quest_complete(quest_id):
			quest_info.status = QuestDatabase.QuestStatus.COMPLETED
			changed = true
			quest_completed.emit(quest_id)

	if changed:
		save_quest_data()

func on_level_up(new_level: int):
	update_quest_progress(QuestDatabase.QuestConditionType.REACH_LEVEL, {"level": new_level})
	_check_all_quest_unlocks()

func on_realm_changed(new_realm: String):
	update_quest_progress(QuestDatabase.QuestConditionType.REACH_REALM, {"realm": new_realm})
	_check_all_quest_unlocks()

func on_tower_completed(floor: int):
	update_quest_progress(QuestDatabase.QuestConditionType.COMPLETE_TOWER, {"floor": floor})
	for quest_id in player_quests:
		var quest_data = QuestDatabase.get_quest(quest_id)
		if quest_data.is_empty():
			continue
		var objectives = quest_data.get("objectives", [])
		for objective in objectives:
			if _normalize_objective_type(objective.get("type", -1)) == QuestDatabase.QuestConditionType.COMPLETE_TOWER:
				_update_quest_progress_from_current_state(quest_id)
				break
	_check_all_quest_unlocks()

func on_suit_dungeon_completed(floor: int):
	update_quest_progress(QuestDatabase.QuestConditionType.COMPLETE_SUIT_DUNGEON, {"floor": floor})
	_check_all_quest_unlocks()

func on_item_used(item_type: String):
	update_quest_progress(QuestDatabase.QuestConditionType.USE_ITEM, {"item_type": item_type})

func on_pet_evolved():
	update_quest_progress(QuestDatabase.QuestConditionType.EVOLVE_PET)

func on_pet_fused():
	update_quest_progress(QuestDatabase.QuestConditionType.FUSE_PET)

func on_pet_collection_activated():
	for quest_id in player_quests:
		var quest_info = player_quests[quest_id]
		if quest_info.status != QuestDatabase.QuestStatus.ACTIVE:
			continue

		var quest_data = QuestDatabase.get_quest(quest_id)
		if quest_data.is_empty():
			continue

		var objectives = quest_data.get("objectives", [])
		for objective in objectives:
			var objective_type = _normalize_objective_type(objective.get("type", -1))
			if objective_type != QuestDatabase.QuestConditionType.UNLOCK_PET_COLLECTION:
				continue

			var target_count = objective.get("target", 1)

			if GameManager.instance and GameManager.instance.pet_collection_manager:
				var activated_count = GameManager.instance.pet_collection_manager.get_activated_count()
				var objective_key = "unlock_pet_collection"
				var old_progress = quest_info.progress.get(objective_key, 0)

				if activated_count > old_progress:
					quest_info.progress[objective_key] = min(activated_count, target_count)
					print("[QuestManager] 任务 %s 宠物图鉴进度更新: %d/%d" % [quest_id, activated_count, target_count])

				if activated_count >= target_count:
					quest_info.status = QuestDatabase.QuestStatus.COMPLETED
					quest_completed.emit(quest_id)
					print("[QuestManager] 任务 %s 完成（宠物图鉴条件满足）" % quest_id)
					save_quest_data()

func on_xianmo_battle_joined():
	for quest_id in player_quests:
		var quest_info = player_quests[quest_id]
		if quest_info.status != QuestDatabase.QuestStatus.ACTIVE:
			continue

		var quest_data = QuestDatabase.get_quest(quest_id)
		if quest_data.is_empty():
			continue

		var objectives = quest_data.get("objectives", [])
		for objective in objectives:
			var objective_type = _normalize_objective_type(objective.get("type", -1))
			if objective_type != QuestDatabase.QuestConditionType.JOIN_XIANMO_BATTLE:
				continue

			var target_count = objective.get("target", 1)
			var objective_key = "join_xianmo_battle"
			var old_progress = quest_info.progress.get(objective_key, 0)

			if old_progress < target_count:
				quest_info.progress[objective_key] = 1
				print("[QuestManager] 任务 %s 仙魔战场进度更新: 1/%d" % [quest_id, target_count])

			if quest_info.progress[objective_key] >= target_count:
				quest_info.status = QuestDatabase.QuestStatus.COMPLETED
				quest_completed.emit(quest_id)
				print("[QuestManager] 任务 %s 完成（仙魔战场条件满足）" % quest_id)
				save_quest_data()

func _on_equipment_changed(_slot: String, _item):
	_check_equip_quest_completion()

func _check_equip_quest_completion():
	for quest_id in player_quests:
		var quest_info = player_quests[quest_id]
		if quest_info.status != QuestDatabase.QuestStatus.ACTIVE:
			continue

		var quest_data = QuestDatabase.get_quest(quest_id)
		if quest_data.is_empty():
			continue

		var objectives = quest_data.get("objectives", [])
		for objective in objectives:
			var objective_type = _normalize_objective_type(objective.get("type", -1))
			if objective_type != QuestDatabase.QuestConditionType.EQUIP_ITEM:
				continue

			var required_rarity = str(objective.get("rarity", "any")).strip_edges()
			var target_count = objective.get("target", 1)

			if GameManager.instance and GameManager.instance.equipment_manager:
				var equipped_count = _count_equipped_items(required_rarity)

				var objective_key = _get_objective_key(objective)
				var old_progress = quest_info.progress.get(objective_key, 0)
				if equipped_count != old_progress:
					quest_info.progress[objective_key] = equipped_count
					print("[QuestManager] 任务 %s 装备进度更新: %d/%d" % [quest_id, equipped_count, target_count])

				if equipped_count >= target_count:
					quest_info.status = QuestDatabase.QuestStatus.COMPLETED
					quest_completed.emit(quest_id)
					print("[QuestManager] 任务 %s 完成（装备条件满足）" % quest_id)
					save_quest_data()

func _count_equipped_items(required_rarity: String) -> int:
	if not GameManager.instance or not GameManager.instance.equipment_manager:
		return 0
	var equipped_items = GameManager.instance.equipment_manager.equipped
	var equipped_count = 0
	var rarity_filter = required_rarity.to_lower()
	var allow_any = rarity_filter.is_empty() or rarity_filter == "any"
	for slot in equipped_items:
		var eq = equipped_items[slot]
		if eq == null:
			continue
		if allow_any:
			equipped_count += 1
		elif str(eq.rarity).to_lower() == rarity_filter:
			equipped_count += 1
	return equipped_count

func _check_all_quest_unlocks():
	var unlocked_count = 0
	var max_iterations = 10

	for i in range(max_iterations):
		var new_unlocked = 0
		for quest_id in player_quests:
			if player_quests[quest_id].status == QuestDatabase.QuestStatus.LOCKED:
				if _check_quest_unlock(quest_id):
					new_unlocked += 1

		unlocked_count += new_unlocked
		if new_unlocked == 0:
			break

	if unlocked_count > 0:
		print("[QuestManager] 共解锁 %d 个任务" % unlocked_count)
		save_quest_data()
