class_name FestivalGiftManager
extends RefCounted

const FestivalGiftConfig = preload("res://scripts/data/festival_gift_config.gd")

static func is_festival_gift(gift_name: String) -> bool:
	return FestivalGiftConfig.is_festival_gift(gift_name)

static func get_festival_config(gift_name: String) -> Dictionary:
	return FestivalGiftConfig.get_festival_config(gift_name)

static func get_active_shop_sale(now_unix: int) -> Dictionary:
	return FestivalGiftConfig.get_active_shop_sale(now_unix)

static func get_active_shop_sale_discount_rate(now_unix: int) -> float:
	var sale: = get_active_shop_sale(now_unix)
	if sale.is_empty():
		return 1.0
	return float(sale.get("discount_rate", 1.0))

static func get_active_festival_wild_spawn(now_unix: int) -> Dictionary:
	return FestivalGiftConfig.get_active_festival_wild_spawn(now_unix)

static func is_festival_activity_active(now_unix: int) -> bool:
	return FestivalGiftConfig.is_festival_activity_active(now_unix)

static func apply_runtime_config(payload: Dictionary) -> int:
	return FestivalGiftConfig.apply_runtime_config(payload)

static func use_festival_gift_batch(item_id: String, _player: Node, count: int, gift_name: String) -> Dictionary:
	var result: Dictionary = {"success": false, "message": "", "summary_lines": [], "total_gold": 0, "opened": 0}
	if not is_festival_gift(gift_name):
		result.message = "该道具不支持此批量方式"
		return result
	if count <= 0:
		result.message = "数量无效"
		return result
	var gm: = GameManager.instance
	if gm == null or gm.inventory_manager == null:
		result.message = "背包管理器未初始化，请稍后再试"
		return result
	var inv: InventoryManager = gm.inventory_manager as InventoryManager
	var item = inv.get_item_by_id(item_id)
	if item == null:
		result.message = "物品不存在"
		return result
	if str(item.name).strip_edges() != str(gift_name).strip_edges():
		result.message = "该道具不支持此批量方式"
		return result
	count = inv.clamp_pet_batch_use_count(count, int(item.count))
	if int(item.count) < count:
		result.message = "物品数量不足（需要%d，拥有%d）" % [count, int(item.count)]
		return result
	if gm.network == null or not gm.network.is_logged_in():
		result.message = "当前网络不可用，已阻止批量使用。"
		return result
	var cfg: = get_festival_config(gift_name)
	var op_id: = "%s_gift_batch_%d_%s" % [str(cfg.get("id", "festival")), Time.get_ticks_usec(), str(randi())]
	var state: = {"done": false, "ok": false, "data": {}, "message": ""}
	var on_success = func(data: Dictionary):
		state.done = true
		state.ok = true
		state.data = data if data is Dictionary else {}
		state.message = str(state.data.get("message", "%s批量开启成功" % gift_name))
	var on_failed = func(error: String):
		state.done = true
		state.ok = false
		state.message = error
	gm.network.pet_gift_open_success.connect(on_success, CONNECT_ONE_SHOT)
	gm.network.pet_gift_open_failed.connect(on_failed, CONNECT_ONE_SHOT)
	gm.network.request_pet_gift_open(gift_name, op_id, {"batchCount": count})
	while not bool(state.done):
		await gm.get_tree().process_frame
	if not bool(state.ok):
		result.message = str(state.message if state.message != "" else "%s批量开启失败，请稍后重试" % gift_name)
		return result
	var data: Dictionary = state.data if state.data is Dictionary else {}
	var reward_result: Dictionary = data.get("result", {}) if data.get("result") is Dictionary else {}
	if data.has("saveData") and data.get("saveData") is Dictionary:
		InventoryManager.apply_server_auth_pet_reward_save(gm, data.get("saveData"), reward_result)
		result["authoritative_save_applied"] = true
		result["reward_sync_policy"] = inv.REWARD_SYNC_NONE
	var summary_lines: Array = []
	var summary_variant: Variant = data.get("summaryLines", [])
	if summary_variant is Array:
		for line in summary_variant:
			summary_lines.append(str(line))
	if summary_lines.is_empty():
		summary_lines.append(str(data.get("message", state.message if state.message != "" else "%s批量开启成功" % gift_name)))
	result.success = true
	result.opened = int(reward_result.get("opened", count))
	result.total_gold = int(reward_result.get("grantedGold", 0))
	result.summary_lines = summary_lines
	result.message = "\n".join(summary_lines)
	var reward_display: = str(data.get("rewardDisplay", "批量开启奖励结算完成"))
	broadcast_festival_gift_open(gift_name, reward_display, str(data.get("rewardCode", "batch")), count)
	return result

static func use_festival_gift_single(gift_name: String) -> Dictionary:
	var result: Dictionary = {"success": false, "message": "", "show_dialog": false, "dialog_title": "", "dialog_message": ""}
	if not is_festival_gift(gift_name):
		result.message = "未知的礼包类型"
		return result
	var gm: = GameManager.instance
	if gm == null or gm.inventory_manager == null:
		result.message = "背包管理器未初始化，请稍后再试"
		return result
	if gm.network == null or not gm.network.is_logged_in():
		result.message = "%s需联网使用，请登录后重试" % gift_name
		return result
	var cfg: = get_festival_config(gift_name)
	var op_id: = "%s_gift_open_%d_%s" % [str(cfg.get("id", "festival")), Time.get_ticks_usec(), str(randi())]
	var state: = {"done": false, "ok": false, "data": {}, "message": ""}
	var on_success = func(data: Dictionary):
		state.done = true
		state.ok = true
		state.data = data if data is Dictionary else {}
		state.message = str(state.data.get("message", "%s开启成功" % gift_name))
	var on_failed = func(error: String):
		state.done = true
		state.ok = false
		state.message = error
	gm.network.pet_gift_open_success.connect(on_success, CONNECT_ONE_SHOT)
	gm.network.pet_gift_open_failed.connect(on_failed, CONNECT_ONE_SHOT)
	gm.network.request_pet_gift_open(gift_name, op_id)
	while not bool(state.done):
		await gm.get_tree().process_frame
	if not bool(state.ok):
		result.message = str(state.message if state.message != "" else "%s开启失败，请稍后重试" % gift_name)
		return result
	var data: Dictionary = state.data if state.data is Dictionary else {}
	var reward_result: Dictionary = data.get("result", {}) if data.get("result") is Dictionary else {}
	if data.has("saveData") and data.get("saveData") is Dictionary:
		InventoryManager.apply_server_auth_pet_reward_save(gm, data.get("saveData"), reward_result)
		result["authoritative_save_applied"] = true
		result["reward_sync_policy"] = gm.inventory_manager.REWARD_SYNC_NONE
	var open_message: = str(data.get("message", state.message if state.message != "" else "%s开启成功" % gift_name))
	var reward_display: = _resolve_reward_display(gift_name, data)
	result.success = true
	result.message = open_message
	result.show_dialog = true
	result.dialog_title = "%s开启成功" % gift_name
	result.dialog_message = open_message
	broadcast_festival_gift_open(gift_name, reward_display, str(data.get("rewardCode", "")))
	return result

static func _resolve_reward_display(gift_name: String, data: Dictionary) -> String:
	var reward_code: = str(data.get("rewardCode", ""))
	var reward_result: Dictionary = data.get("result", {}) if data.get("result") is Dictionary else {}
	var granted_items: Array = reward_result.get("grantedItems", []) if reward_result.has("grantedItems") else []
	var granted_pets: Array = reward_result.get("grantedPets", []) if reward_result.has("grantedPets") else []
	var granted_gold: int = int(reward_result.get("grantedGold", 0))
	if granted_gold > 0:
		return "%d金币" % granted_gold
	if granted_items.size() > 0 and granted_items[0] is Dictionary:
		return str((granted_items[0] as Dictionary).get("name", "神秘奖励"))
	if granted_pets.size() > 0 and granted_pets[0] is Dictionary:
		var first_pet: = granted_pets[0] as Dictionary
		var cfg: = get_festival_config(gift_name)
		var pet_reward: Dictionary = cfg.get("pet_reward", {}) if cfg.get("pet_reward") is Dictionary else {}
		var pet_code: = str(pet_reward.get("code", ""))
		var pet_name: = str(pet_reward.get("pet_name", "神秘宠物"))
		if reward_code == pet_code or str(first_pet.get("name", "")) == pet_name:
			var growth: = float(first_pet.get("growth", 0.0))
			return "%s（成长%.3f）" % [pet_name, growth]
		return str(first_pet.get("name", "神秘宠物"))
	return "神秘奖励"


static func _normalize_broadcast_reward_text(raw: String) -> String:
	var text: = str(raw).strip_edges()
	if text.is_empty():
		return "神秘奖励"
	var batch_prefix: = RegEx.new()
	batch_prefix.compile("^批量开启\\d+个，奖励[：:]")
	var matched: = batch_prefix.search(text)
	if matched:
		text = text.substr(matched.get_end()).strip_edges()
	if text.is_empty() or text == "奖励结算完成" or text.begins_with("批量开启"):
		return "多种奖励"
	return text

static func broadcast_festival_gift_open(gift_name: String, reward_text: String, reward_code: String = "", batch_count: int = 0) -> void :
	var gm: = GameManager.instance
	if gm == null or gm.player == null:
		return
	var player_name: = str(gm.player.player_name)
	if player_name.is_empty():
		return
	var cfg: = get_festival_config(gift_name)
	var event_id: = str(cfg.get("broadcast_event", "festival_gift_open"))
	var cleaned: = _normalize_broadcast_reward_text(reward_text)
	var msg: String
	if batch_count > 1:
		msg = "🎁 恭喜玩家【%s】批量开启%d个【%s】，获得【%s】！" % [player_name, batch_count, gift_name, cleaned]
	else:
		msg = "🎁 恭喜玩家【%s】开启【%s】，获得【%s】！" % [player_name, gift_name, cleaned]
	gm.broadcast_event(event_id, player_name, {
		"gift_name": gift_name, 
		"reward": cleaned, 
		"reward_code": reward_code, 
	}, msg)
