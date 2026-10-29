extends "res://scripts/game_manager.gd"

# Local preview only: original client combat, no server settlement; experience uses recovered field rules.
func prepare_local_encounter() -> void:
	if in_battle:
		return
	battle_system.player = player
	battle_system.active_pet = pet_manager.get_active_pet()
	battle_system.monsters = Monster.create_group(get_current_map_data())
	_local_calibrate_encounter()

func start_battle() -> bool:
	if in_battle or not initialized:
		return false
	prepare_local_encounter()
	if battle_system.monsters.is_empty():
		return false
	battle_system.replay_log_only = false
	battle_system.drive_by_execute_turn = true
	battle_system.suppress_battle_character_exp = false
	if not battle_system.battle_ended.is_connected(_local_battle_finished):
		battle_system.battle_ended.connect(_local_battle_finished)
	_local_reward_settled = false
	_local_cancelled = false
	in_battle = true
	var started: bool = battle_system.start_battle(player, pet_manager.get_active_pet(), battle_system.monsters, maxi(1, Monster.wild_battle_max_rounds), false, resolve_attack_target_mode("wild"))
	if not started:
		in_battle = false
	else:
		battle_system.add_log("[color=yellow]本地战斗联调：经验可用于本地升级，未连接正式服务器[/color]")
	return started

var _local_reward_settled := false
var _local_cancelled := false

func cancel_local_battle() -> void:
	_local_cancelled = true
	battle_system.force_end_battle()

func _local_battle_finished(victory: bool) -> void:
	in_battle = false
	if victory and not _local_reward_settled and not _local_cancelled:
		var rule := _local_captured_map_rule()
		if rule.get("rewardCode", "") == "UNKNOWN_MAP" or rule.get("rewardEnabled", true) == false:
			_local_reward_settled = true
			battle_system.add_log("采集规则：当前地图战斗不发放金币和经验")
			battle_ended_ui.emit(victory)
			save_game()
			return
		var snapshot := create_secure_op_snapshot()
		_local_shop_busy = true
		var rewards: Dictionary = battle_system.get_battle_rewards()
		var payload: Array = _build_battle_loot_monsters_payload()
		var exp_reward: int = _compute_preview_field_battle_exp(int(rewards.get("exp", 0)), payload)
		_grant_field_battle_exp(exp_reward, pet_manager.get_active_pet())
		var gold: int = int(rewards.get("gold", 0))
		player.gold += gold
		var dropped: String = inventory_manager.get_random_drop(player.level)
		if not dropped.is_empty():
			var added: Dictionary = inventory_manager.add_item(dropped, 1)
			if not bool(added.get("success", false)):
				var pending: Array = _local_metadata.get("pending_battle_items", [])
				pending.append(dropped)
				_local_metadata.pending_battle_items = pending
				battle_system.add_log("背包已满，掉落已暂存本地待领取：" + dropped)
		_local_shop_busy = false
		if save_game():
			_local_reward_settled = true
			gold_changed.emit(player.gold)
			battle_system.add_log("[color=yellow]本地结算已保存：金币+%d%s[/color]" % [gold, "，掉落" + dropped if not dropped.is_empty() else ""])
		else:
			restore_secure_op_snapshot(snapshot)
			battle_system.add_log("[color=red]本地奖励存档失败，已回滚，请保留窗口检查存档[/color]")
	battle_ended_ui.emit(victory)
	save_game()

const LOCAL_MODULES := ["player", "pet_manager", "pet_collection_manager", "pet_soul_manager", "pet_equipment_manager", "equipment_manager", "fabao_manager", "suit_manager", "martial_arts_manager", "inventory_manager", "crafting_manager", "quest_manager", "xianmo_system", "xianmo_ranking", "xianmo_chest_manager"]
const LOCAL_SETTINGS := ["current_map", "auto_capture_enabled", "min_growth_threshold", "auto_change_map_enabled", "previous_map", "bgm_enabled", "bgm_volume"]
var _local_loading := false
var _local_save_ready := false

func local_slot_path() -> String:
	if "--auto-entry-test" in OS.get_cmdline_user_args():
		return "user://inkbeast/auto-entry-qa.json"
	# Web/mini-game builds use the platform adapter's persistent user filesystem.
	# Keep the desktop user's live save and QA slots separate.
	if OS.has_feature("web"):
		var isolated := "--smoke" in OS.get_cmdline_user_args() or "--buff-test" in OS.get_cmdline_user_args() or "--item-test" in OS.get_cmdline_user_args() or "--full-audit-test" in OS.get_cmdline_user_args()
		return "user://inkbeast/qa-slot.json" if isolated else "user://inkbeast/preview-slot.json"
	var executable := OS.get_executable_path()
	var output := executable.get_base_dir().path_join("../../..").simplify_path() if executable.contains(".app/Contents/MacOS/") else ProjectSettings.globalize_path("res://../../outputs")
	if "--full-audit-test" in OS.get_cmdline_user_args():
		return output.path_join("local-state/full-audit-qa.json")
	var test_slot := "--save-write-test" in OS.get_cmdline_user_args() or "--save-read-test" in OS.get_cmdline_user_args()
	if "--shop-test" in OS.get_cmdline_user_args() or "--shop-read-test" in OS.get_cmdline_user_args():
		return output.path_join("local-state/shop-qa.json")
	if "--item-test" in OS.get_cmdline_user_args() or "--item-read-test" in OS.get_cmdline_user_args():
		return output.path_join("local-state/item-qa.json")
	if "--buff-test" in OS.get_cmdline_user_args() or "--buff-read-test" in OS.get_cmdline_user_args():
		return output.path_join("local-state/buff-qa.json")
	if "--lottery-test" in OS.get_cmdline_user_args() or "--lottery-read-test" in OS.get_cmdline_user_args():
		return output.path_join("local-state/lottery-qa.json")
	return output.path_join("local-state/qa-slot.json" if test_slot else "local-state/preview-slot.json")

func enable_local_saving() -> void:
	_local_save_ready = true
	var migrated: bool = _migrate_local_double_exp()
	var credited: bool = _apply_pending_local_credit()
	if migrated or credited:
		save_game()
	var autosave := Timer.new()
	autosave.wait_time = 10.0
	autosave.timeout.connect(func(): save_game())
	add_child(autosave)
	autosave.start()

func save_game(_force_cloud_upload: bool = false, _upload_reason: String = "") -> bool:
	if _local_loading or not _local_save_ready or _local_shop_busy:
		return false
	# QA combat fixtures must never modify the user's normal save.
	if "--smoke" in OS.get_cmdline_user_args():
		return false
	_apply_pending_local_credit()
	var snapshot := {"local_schema": 1, "modules": {}, "settings": {}, "local_metadata": _local_metadata}
	for key in LOCAL_MODULES:
		var manager = get(key)
		if manager != null and manager.has_method("to_dict"):
			snapshot.modules[key] = manager.to_dict()
	for key in LOCAL_SETTINGS:
		snapshot.settings[key] = get(key)
	var path := local_slot_path()
	if DirAccess.make_dir_recursive_absolute(path.get_base_dir()) != OK:
		return false
	var serialized := JSON.stringify(snapshot)
	var temp := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if temp == null:
		return false
	temp.store_string(serialized)
	temp.close()
	if _read_local_snapshot(path + ".tmp").is_empty():
		return false
	if FileAccess.file_exists(path) and not _read_local_snapshot(path).is_empty():
		if DirAccess.copy_absolute(path, path + ".bak") != OK:
			return false
	if DirAccess.rename_absolute(path + ".tmp", path) != OK:
		return false
	game_saved.emit()
	return true

func _read_local_snapshot(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or int(parsed.get("local_schema", 0)) != 1:
		return {}
	var modules: Variant = parsed.get("modules")
	if not modules is Dictionary or not modules.get("player") is Dictionary or not modules.get("pet_manager") is Dictionary or not parsed.get("settings") is Dictionary:
		return {}
	for key in modules:
		if not modules[key] is Dictionary:
			return {}
	return parsed

func has_local_slot() -> bool:
	return FileAccess.file_exists(local_slot_path()) or FileAccess.file_exists(local_slot_path() + ".bak")

func load_game() -> bool:
	var snapshot := _read_local_snapshot(local_slot_path())
	if snapshot.is_empty():
		snapshot = _read_local_snapshot(local_slot_path() + ".bak")
	if snapshot.is_empty():
		return false
	_local_loading = true
	_local_metadata = snapshot.get("local_metadata", {"credits": {}, "shop_counts": {}})
	for key in LOCAL_MODULES:
		var manager = get(key)
		if manager != null and manager.has_method("from_dict") and snapshot.modules.has(key):
			manager.from_dict(snapshot.modules[key])
	for key in LOCAL_SETTINGS:
		if snapshot.settings.has(key):
			set(key, snapshot.settings[key])
	_local_loading = false
	gold_changed.emit(player.gold)
	yuanbao_changed.emit(player.yuanbao_currency)
	return true

var _local_metadata: Dictionary = {"credits": {}, "shop_counts": {}}
var _local_shop_busy := false

func local_shop_catalog() -> Array:
	var shop = load("res://ui/city/shop_ui.gd")
	var rows: Array = shop._get_gold_items_cfg_fallback() + shop._get_yuanbao_items_cfg_fallback() + shop._get_friendship_items_cfg_fallback()
	var date_key := Time.get_date_string_from_system(true)
	var result: Array = []
	for cfg in rows:
		var limit: int = int(cfg.get("daily_limit", 0))
		var key: String = date_key + "|" + str(cfg.name)
		result.append({"itemName": cfg.name, "currency": cfg.currency, "basePrice": cfg.price, "finalPrice": cfg.price, "vipRequiredTier": int(cfg.get("vip_required_tier", 0)), "dailyLimit": limit, "dailyRemaining": maxi(0, limit - int(_local_metadata.shop_counts.get(key, 0)))})
	return result

func local_shop_buy(item_name: String, currency: String, quantity: int) -> Dictionary:
	if _local_shop_busy or quantity < 1 or quantity > 999:
		return {"ok": false, "message": "购买数量无效或交易处理中"}
	var cfg: Dictionary = {}
	for row in local_shop_catalog():
		if row.itemName == item_name and row.currency == currency:
			cfg = row
			break
	if cfg.is_empty():
		return {"ok": false, "message": "该商品不在原客户端商城目录中"}
	var vip = load("res://scripts/vip_benefits.gd")
	if vip.tier_from_player(player) < int(cfg.vipRequiredTier):
		return {"ok": false, "message": "VIP等级不足"}
	if int(cfg.dailyLimit) > 0 and quantity > int(cfg.dailyRemaining):
		return {"ok": false, "message": "超过今日限购数量"}
	var fields := {"gold": "gold", "yuanbao": "yuanbao_currency", "friendship": "friendship_points"}
	if not fields.has(currency):
		return {"ok": false, "message": "未知货币"}
	var field: String = fields[currency]
	var cost: int = int(cfg.finalPrice) * quantity
	var balance: int = int(player.get(field))
	if cost <= 0 or balance < cost:
		return {"ok": false, "message": "余额不足"}
	_local_shop_busy = true
	var inventory_before: Dictionary = inventory_manager.to_dict().duplicate(true)
	var count_before: int = inventory_manager.get_item_count(item_name)
	var counts_before: Dictionary = _local_metadata.shop_counts.duplicate(true)
	var added: Dictionary = inventory_manager.add_item(item_name, quantity)
	if not bool(added.get("success", false)) or inventory_manager.get_item_count(item_name) - count_before != quantity:
		inventory_manager.from_dict(inventory_before)
		_local_shop_busy = false
		return {"ok": false, "message": str(added.get("message", "背包无法容纳完整数量"))}
	for item in inventory_manager.items:
		if str(item.name) == item_name:
			inventory_manager._try_patch_limit_material_custom_data(item)
	player.set(field, balance - cost)
	var key: String = Time.get_date_string_from_system(true) + "|" + item_name
	_local_metadata.shop_counts[key] = int(_local_metadata.shop_counts.get(key, 0)) + quantity
	_local_shop_busy = false
	if not save_game():
		_local_shop_busy = true
		player.set(field, balance)
		inventory_manager.from_dict(inventory_before)
		_local_metadata.shop_counts = counts_before
		_local_shop_busy = false
		return {"ok": false, "message": "本地存档失败，交易已回滚"}
	gold_changed.emit(player.gold)
	yuanbao_changed.emit(player.yuanbao_currency)
	return {"ok": true, "cost": cost, "message": "本地购买成功：%s x%d，已放入背包" % [item_name, quantity]}

func _apply_pending_local_credit() -> bool:
	if "--full-audit-test" in OS.get_cmdline_user_args() or "--smoke" in OS.get_cmdline_user_args() or "--save-write-test" in OS.get_cmdline_user_args() or "--save-read-test" in OS.get_cmdline_user_args() or "--shop-test" in OS.get_cmdline_user_args() or "--shop-read-test" in OS.get_cmdline_user_args() or "--item-test" in OS.get_cmdline_user_args() or "--item-read-test" in OS.get_cmdline_user_args() or "--buff-test" in OS.get_cmdline_user_args() or "--buff-read-test" in OS.get_cmdline_user_args() or "--lottery-test" in OS.get_cmdline_user_args() or "--lottery-read-test" in OS.get_cmdline_user_args():
		return false
	var path := local_slot_path().get_base_dir().path_join("test-credit.json")
	if not FileAccess.file_exists(path):
		return false
	var credit: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not credit is Dictionary or str(credit.get("id", "")).is_empty():
		return false
	var key: String = str(credit.id)
	if _local_metadata.credits.has(key):
		return false
	var gold: int = maxi(0, int(credit.get("gold", 0)))
	var yuanbao: int = maxi(0, int(credit.get("yuanbao", 0)))
	player.gold += gold
	player.yuanbao_currency += yuanbao
	_local_metadata.credits[key] = {"gold": gold, "yuanbao": yuanbao}
	return true

func commit_secure_op(_max_wait_sec: float = COMMIT_SECURE_OP_DEFAULT_MAX_WAIT_SEC) -> bool:
	return save_game()

func initialize(_skip_local_disk: bool = false) -> bool:
	# The preview bootstrap chooses the normal or isolated QA slot explicitly.
	var ready: bool = super.initialize(true)
	if ready:
		var config: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://dev/local_runtime_config.json"))
		if config is Dictionary:
			_on_gameplay_runtime_config_loaded(config)
			print("LOCAL_CAPTURED_RUNTIME_APPLIED=true")
	return ready

func local_use_item(item_id: String, quantity: int = 1) -> Dictionary:
	return await load("res://dev/local_items.gd").use_item(self, item_id, quantity)

const LOCAL_DOUBLE_HOURS := {"双倍经验丹": 24, "双倍经验丹(周)": 168, "双倍经验丹(月)": 720}

func _migrate_local_double_exp() -> bool:
	if _local_metadata.has("double_exp_channels"):
		return false
	var channels: Dictionary = {}
	var consumed: Dictionary = {}
	var total_seconds := 0
	for name in LOCAL_DOUBLE_HOURS:
		var purchased := 0
		for key in _local_metadata.shop_counts:
			if str(key).ends_with("|" + name):
				purchased += int(_local_metadata.shop_counts[key])
		var stock: int = inventory_manager.count_item_total_in_bag_and_warehouse(name)
		var used: int = maxi(0, purchased - stock)
		consumed[name] = used
		total_seconds += used * int(LOCAL_DOUBLE_HOURS[name]) * 3600
	var now := int(Time.get_unix_time_from_system())
	var old_until: int = player.double_exp_until
	if old_until > now and total_seconds > 0:
		# The previous version saved only the combined end. Recover the common
		# start from purchased-minus-remaining stock without consuming anything.
		var start: int = mini(now, old_until - total_seconds)
		for name in LOCAL_DOUBLE_HOURS:
			if int(consumed[name]) > 0:
				channels[name] = start + int(consumed[name]) * int(LOCAL_DOUBLE_HOURS[name]) * 3600
	elif old_until > now:
		channels["旧版经验效果"] = old_until
	_local_metadata.double_exp_channels = channels
	_local_metadata.double_exp_migration = {"old_until": old_until, "consumed_from_shop": consumed, "method": "combined_until_minus_consumed_duration"}
	_sync_local_double_exp_until()
	return true

func _sync_local_double_exp_until() -> void:
	var latest := 0
	for value in _local_metadata.get("double_exp_channels", {}).values():
		latest = maxi(latest, int(value))
	player.double_exp_until = latest

func local_double_exp_count(current_time: int = -1) -> int:
	var now := int(Time.get_unix_time_from_system()) if current_time < 0 else current_time
	if not _local_metadata.has("double_exp_channels"):
		return 1 if player.double_exp_until > now else 0
	var count := 0
	var legacy_active := false
	for name in _local_metadata.double_exp_channels:
		if int(_local_metadata.double_exp_channels[name]) > now:
			if LOCAL_DOUBLE_HOURS.has(name):
				count += 1
			else:
				legacy_active = true
	return maxi(count, 1 if legacy_active else 0)

func local_extend_double_exp(name: String) -> String:
	var now := int(Time.get_unix_time_from_system())
	var channels: Dictionary = _local_metadata.get("double_exp_channels", {})
	channels[name] = maxi(now, int(channels.get(name, 0))) + int(LOCAL_DOUBLE_HOURS[name]) * 3600
	_local_metadata.double_exp_channels = channels
	_sync_local_double_exp_until()
	return local_double_exp_status()

func local_double_exp_status() -> String:
	var now := int(Time.get_unix_time_from_system())
	var parts: Array[String] = []
	for name in _local_metadata.get("double_exp_channels", {}):
		var remaining: int = int(_local_metadata.double_exp_channels[name]) - now
		if remaining > 0:
			parts.append("%s：剩余%d小时" % [name, int(ceil(float(remaining) / 3600.0))])
	var count := local_double_exp_count()
	return "%d种经验丹生效，丹药加成+%d%%（基础共%d倍）\n%s" % [count, count * 100, count + 1, "\n".join(parts)]

# 父类后来加了 server_count 参数（服务端权威值优先），子类签名必须跟着改，
# 否则整个 dev 脚本解析失败（--editor 重扫时会报 signature doesn't match）。
func _log_double_exp_field_bonus_once(_server_count: int = -1) -> void:
	if _field_double_exp_bonus_logged_in_window or battle_system == null or local_double_exp_count() == 0:
		return
	_field_double_exp_bonus_logged_in_window = true
	battle_system.add_log("[color=orange]%s[/color]" % local_double_exp_status())

func create_secure_op_snapshot() -> Dictionary:
	var result: Dictionary = super.create_secure_op_snapshot()
	result["local_metadata"] = _local_metadata.duplicate(true)
	return result

func restore_secure_op_snapshot(snapshot: Dictionary) -> void:
	if snapshot.has("local_metadata"):
		_local_metadata = snapshot.local_metadata.duplicate(true)
	super.restore_secure_op_snapshot(snapshot)

func local_lottery_draw(pool: String, operation_id: String) -> Dictionary:
	return load("res://dev/local_lottery.gd").draw(self, pool, operation_id)

func local_lottery_pity_status() -> Dictionary:
	return load("res://dev/local_lottery.gd").pity_status(self)

func local_lottery_claim(name: String, operation_id: String) -> Dictionary:
	return load("res://dev/local_lottery.gd").claim(self, name, operation_id)

var _local_attr_allocating := false
var last_local_settlement: Dictionary = {}

func local_auto_allocate() -> bool:
	if _local_attr_allocating or player == null or not player.auto_allocation_enabled or int(player.pending_auto_points) < int(player.AUTO_ALLOCATE_THRESHOLD):
		return false
	if player._auto_allocation_plan_total() <= 0:
		return false
	_local_attr_allocating = true
	var before: int = player.pending_auto_points
	player.set_attr_mutation_allowed(true)
	var messages: Array = player.auto_allocate_pending_points()
	player.set_attr_mutation_allowed(false)
	_local_attr_allocating = false
	if before == int(player.pending_auto_points):
		return false
	for message in messages:
		battle_system.add_log(str(message))
	var ui = _find_main_ui_node()
	if ui != null and ui.has_method("_notify_player_attr_changed"):
		ui.call_deferred("_notify_player_attr_changed", "local_auto_allocate")
	save_game()
	return true

func _grant_field_battle_exp(exp_reward: int, active_pet) -> void:
	if exp_reward <= 0:
		return
	var player_before := {"level": player.level, "exp": player.experience}
	var pet_before := {"level": active_pet.level, "exp": active_pet.experience} if active_pet else {}
	var mult: float = player.get_total_exp_multiplier(-1, true)
	var player_granted := 0
	var pet_granted := 0
	# Server slice mode intentionally drops overflow and caps level updates.
	# Offline settlement must consume the full experience against the same tables.
	if not battle_system.player_died_in_battle:
		player_granted = int(round(float(exp_reward) * mult))
		for message in player.add_exp(exp_reward, false, true, player.get_field_max_level_ups()):
			battle_system.add_log(str(message))
	if active_pet != null and not battle_system.pet_died_in_battle:
		pet_granted = _battle_pet_exp_with_player_multiplier(exp_reward)
		var result: Dictionary = pet_manager.add_pet_exp(active_pet, pet_granted, false)
		for message in result.get("messages", []):
			battle_system.add_log(str(message))
	last_local_settlement = {"base_exp": exp_reward, "multiplier": mult, "player_granted": player_granted, "pet_granted": pet_granted, "player_before": player_before, "player_after": {"level": player.level, "exp": player.experience}, "pet_before": pet_before, "pet_after": {"level": active_pet.level, "exp": active_pet.experience} if active_pet else {}}
	battle_system.add_log("[color=cyan]本地经验入账：基础%d × %.2f；人物%d，灵兽%d；人物Lv.%d余%d，灵兽Lv.%d余%d[/color]" % [exp_reward, mult, player_granted, pet_granted, player.level, player.experience, active_pet.level if active_pet else 0, active_pet.experience if active_pet else 0])
	local_auto_allocate()

func local_pair_primary_target(targets: Array):
	for target in targets:
		if battle_system.is_monster_alive(target):
			return target
	return battle_system._find_first_alive_monster()

func local_equipment_op(pet_equipment: bool, action: String, equipment_id: String, slot: String = "") -> Dictionary:
	if _local_shop_busy:
		return {"success": false, "message": "操作处理中"}
	var snapshot := create_secure_op_snapshot()
	_local_shop_busy = true
	var success := false
	if not pet_equipment:
		if action == "equip":
			var equipment = equipment_manager.get_equipment_by_id(equipment_id)
			if equipment != null:
				success = equipment_manager.equip(equipment)
		elif action == "unequip" and equipment_manager.equipped.has(slot):
			success = equipment_manager.unequip(slot) != null
	else:
		if action == "equip":
			var data: Dictionary = inventory_manager.get_pet_equipment_by_id(equipment_id)
			if not data.is_empty():
				var equipment = equipment_manager.create_equipment_from_data(data)
				equipment.is_pet_equipment = true
				inventory_manager.remove_pet_equipment(equipment_id)
				var result: Dictionary = pet_equipment_manager.equip(equipment)
				success = bool(result.get("success", false))
				if success and result.get("unequipped") != null:
					success = bool(inventory_manager.add_pet_equipment(result.unequipped).get("success", false))
		elif action == "unequip":
			var equipment = pet_equipment_manager.unequip(slot)
			if equipment != null:
				success = bool(inventory_manager.add_pet_equipment(equipment).get("success", false))
	_local_shop_busy = false
	if not success or not save_game():
		_local_shop_busy = true
		restore_secure_op_snapshot(snapshot)
		_local_shop_busy = false
		return {"success": false, "message": "装备操作失败（条件/空间不足或存档失败），已回滚"}
	return {"success": true, "message": "装备已在本地生效并保存"}

func local_realm_transition(kind: String) -> Dictionary:
	if in_battle or _local_shop_busy:
		return {"success": false, "message": "请先停止战斗"}
	var snapshot := create_secure_op_snapshot()
	_local_shop_busy = true
	var result: Dictionary = player.ascend(pet_collection_manager.get_all_element_collection_counts()) if kind == "ascend" else player.reincarnate()
	_local_shop_busy = false
	if not bool(result.get("success", false)) or not save_game():
		_local_shop_busy = true
		restore_secure_op_snapshot(snapshot)
		_local_shop_busy = false
		return {"success": false, "message": str(result.get("message", "本地存档失败，已回滚"))}
	return {"success": true, "message": "境界：%s，等级：%d，投胎：%d。已按原客户端规则本地保存。" % [player.realm, player.level, player.reincarnation]}

func local_feature_action(kind: String, args: Dictionary = {}) -> Dictionary:
	return load("res://dev/local_features.gd").action(self, kind, args)

func track_event(_event_type: String, _event_data: Dictionary = {}) -> void:
	pass

var _local_map_revision := 0
func change_map(map_name: String) -> bool:
	if not GameData.MAPS_DATA.has(map_name):
		return false
	_local_map_revision += 1
	if in_battle:
		cancel_local_battle()
	current_map = map_name
	player.add_recent_map(map_name)
	map_changed.emit(map_name)
	save_game()
	call_deferred("_local_begin_changed_map", _local_map_revision)
	return true

func _local_begin_changed_map(revision: int) -> void:
	if revision != _local_map_revision:
		return
	var ui = _find_main_ui_node()
	if ui == null:
		return
	ui.set("auto_battle", true)
	set_auto_battle_enabled(true)
	ui.set("_battle_cooldown_deadline_ms", Time.get_ticks_msec() + 1000)
	start_battle()
	ui.call("_refresh_stop_or_start_battle_btn_text")

var _local_maps_cache: Dictionary = {}
func _local_captured_map_rule() -> Dictionary:
	if _local_maps_cache.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://dev/local_maps.json"))
		if parsed is Dictionary:
			_local_maps_cache = parsed.get("maps", {})
	var rule: Variant = _local_maps_cache.get(current_map, {})
	return rule if rule is Dictionary else {}

func _local_calibrate_encounter() -> void:
	var rule := _local_captured_map_rule()
	var pool: Array = rule.get("pool", [])
	for monster in battle_system.monsters:
		# Only replace stats when the capture supplies this exact monster level.
		for row in pool:
			if str(row.get("pet_id", "")) != monster.monster_id or int(row.get("level", -1)) != monster.level:
				continue
			monster.attack = int(row.get("attack", monster.attack))
			monster.defense = int(row.get("defense", monster.defense))
			monster.agility = int(row.get("agility", monster.agility))
			monster.max_hp = int(row.get("hp", monster.max_hp))
			monster.hp = monster.max_hp
			break
		monster.exp_reward = monster.level * 90
		monster.gold_reward = monster.level
