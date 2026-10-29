extends Node
class_name GangManager

const TitleDataClass = preload("res://scripts/title/title_data.gd")

const TOAST_ACTIONS: Array = ["create", "donate", "shop_buy", "apply", "upgrade", "leave", "siege_apply", "siege_bid", "siege_forfeit", "siege_attack", "siege_buy_attack_contribution", "siege_buy_attack", "siege_repair", "siege_buy_defense", "siege_guard_set", "siege_guard_clear", "siege_guard_join", "territory_claim_daily_all", "territory_abandon", "gang_settings"]

const MEMBERS_REFRESH_INTERVAL_MS: = 300000

signal overview_updated(data: Dictionary)
signal overview_failed(error: String)
signal war_reports_updated()
signal kick_history_updated()
signal siege_history_updated()
signal buffs_updated(buffs: Dictionary)
signal titles_loaded(titles: Array)
signal title_activated(data: Dictionary)
signal ranking_updated(ranking: Array)
signal gang_toast(message: String, is_success: bool)
signal kick_battle_ready(data: Dictionary)

signal siege_battle_ready(data: Dictionary)

var game_manager = null
var gang_network: GangNetwork
var overview: Dictionary = {}
var buffs: Dictionary = {}
var gang_level_buffs: Dictionary = {}
var territory_buffs: Dictionary = {}
var members: Array = []
var applications: Array = []
var viewer_role: int = 4
var shop_data: Dictionary = {}
var territories: Array = []
var war_reports: Array = []
var war_reports_loading: = false
var war_reports_error: = ""
var siege_status: Dictionary = {}
var siege_active_sessions: Array = []
var siege_guards_cache: Dictionary = {}
var participation_logs: Array = []
var territory_claim_status: Dictionary = {}
var ranking: Array = []
var used_emblem_ids: Array = []
var other_gangs: Array = []
var kick_active_sessions: Array = []
var kick_defending_sessions: Array = []
var kick_activity_logs: Array = []
var kick_history: Array = []
var kick_history_loading: = false
var kick_history_error: = ""
var siege_history: Array = []
var siege_history_loading: = false
var siege_history_error: = ""
var has_gang_mirror: = false
var _members_last_fetch_ms: int = 0
var dialog_host: Control = null

func set_dialog_host(host: Control) -> void :
	if host != null and is_instance_valid(host):
		dialog_host = host
	else:
		dialog_host = null

func get_dialog_host() -> Control:
	if dialog_host != null and is_instance_valid(dialog_host):
		return dialog_host
	return null

func setup(game_manager_ref) -> void :
	game_manager = game_manager_ref
	if gang_network == null:
		gang_network = GangNetwork.new()
		add_child(gang_network)
		gang_network.setup(game_manager)
		gang_network.request_finished.connect(_on_network_finished)

func refresh_overview() -> void :
	if gang_network:
		gang_network.fetch_overview()

func refresh_members(force: bool = false) -> void :
	if not gang_network:
		return
	var now_ms: = Time.get_ticks_msec()
	if not force and not members.is_empty() and _members_last_fetch_ms > 0:
		if now_ms - _members_last_fetch_ms < MEMBERS_REFRESH_INTERVAL_MS:
			return
	gang_network.fetch_members()

func refresh_shop() -> void :
	if gang_network:
		gang_network.fetch_shop()

func refresh_buffs() -> void :
	if gang_network:
		gang_network.fetch_buffs()

func refresh_territories() -> void :
	if gang_network:
		gang_network.fetch_territories()

func refresh_war_reports() -> void :
	if gang_network:
		war_reports_loading = true
		war_reports_error = ""
		gang_network.fetch_war_reports()

func refresh_siege_status() -> void :
	if gang_network:
		gang_network.fetch_siege_status()

func refresh_ranking() -> void :
	if gang_network:
		gang_network.fetch_ranking()

func refresh_titles() -> void :
	if gang_network:
		gang_network.fetch_titles()

func refresh_other_gangs() -> void :
	if gang_network:
		gang_network.fetch_other_gangs()

func refresh_kick_active() -> void :
	if gang_network:
		gang_network.fetch_kick_active()

func refresh_kick_defending() -> void :
	if gang_network:
		gang_network.fetch_kick_defending()

func refresh_kick_history() -> void :
	if gang_network:
		kick_history_loading = true
		kick_history_error = ""
		gang_network.fetch_kick_history()

func refresh_siege_history() -> void :
	if gang_network:
		siege_history_loading = true
		siege_history_error = ""
		gang_network.fetch_siege_history()

func refresh_gang_mirror() -> void :
	if gang_network:
		gang_network.fetch_gang_mirror()

func update_gang_mirror() -> void :
	if gang_network:
		gang_network.update_gang_mirror()

func apply_gang_mirror_preview(data: Dictionary) -> void :
	if data.has("hasMirror"):
		has_gang_mirror = bool(data.get("hasMirror", false))

func get_kick_session_for_defender(defender_gang_id: int) -> Dictionary:
	for s in kick_active_sessions:
		if not s is Dictionary:
			continue
		if int(s.get("defenderGangId", s.get("defender_gang_id", 0))) == defender_gang_id:
			return s
	return {}

func has_kick_war_with_gang(gang_id: int) -> bool:

	return not get_kick_session_for_defender(gang_id).is_empty()

func notify_kick_attack_result(data: Dictionary) -> void :
	_emit_action_toast("kick_attack", true, data)

var _last_siege_attack_round_id: = 0
var _pending_siege_attack_result: Dictionary = {}

func note_siege_attack_round(round_id: int) -> void :
	_last_siege_attack_round_id = int(round_id)

func get_territory_id_for_siege_round(round_id: int = 0) -> String:
	var rid: = int(round_id if round_id > 0 else _last_siege_attack_round_id)
	if rid <= 0:
		return ""
	for s in siege_active_sessions:
		if s is Dictionary and int(s.get("roundId", 0)) == rid:
			return str(s.get("territoryId", ""))
	for s in siege_status.get("activeSessions", []):
		if s is Dictionary and int(s.get("roundId", 0)) == rid:
			return str(s.get("territoryId", ""))
	return ""

func _replay_watch_hint(data: Dictionary) -> String:
	var raw = data.get("battleLog", data.get("battle_log", []))
	if raw is Array and not (raw as Array).is_empty():
		return "\n完整过程可在帮派战报里查看"
	return ""

func format_siege_attack_result_message(data: Dictionary) -> String:
	var won: = bool(data.get("won", false))
	var auto_win: = bool(data.get("autoWin", data.get("auto_win", false)))
	var is_npc: = bool(data.get("isNpc", data.get("is_npc", false)))
	var defender_name: = str(data.get("defenderName", ""))
	var msg: = ""
	if bool(data.get("endedEarly", false)) or bool(data.get("captured", false)) or str(data.get("status", "")) == "attacker_won":
		msg = "领地战胜利！占领成功"
	elif auto_win:
		msg = "无人防守，直接获胜！"
	elif is_npc:
		msg = "进攻%s【%s】！" % [
			"胜利" if won else "失败", 
			defender_name if not defender_name.is_empty() else "领地守军", 
		]
	else:
		msg = "进攻%s！" % ["胜利" if won else "失败"]
	if not auto_win:
		msg += _replay_watch_hint(data)
	return msg

func consume_pending_siege_attack_result() -> Dictionary:
	var data: = _pending_siege_attack_result.duplicate(true)
	_pending_siege_attack_result = {}
	return data

func notify_siege_battle_replay_finished(data: Dictionary) -> void :
	_pending_siege_attack_result = data.duplicate(true)
	refresh_siege_status()
	refresh_war_reports()
	refresh_territories()

func is_emblem_used(emblem_id: int) -> bool:
	return int(emblem_id) in used_emblem_ids

func get_buff_percent(key: String) -> float:
	if buffs.is_empty():
		return 0.0
	match key:
		"attack":
			return float(buffs.get("attackBonusPercent", 0))
		"defense":
			return float(buffs.get("defenseBonusPercent", 0))
		"hp":
			return float(buffs.get("hpBonusPercent", 0))
		"agility":
			return float(buffs.get("agilityBonusPercent", 0))
		"exp":
			return float(buffs.get("expBonusPercent", 0))
		"gold_drop":
			return float(buffs.get("goldDropBonusPercent", 0))
	return 0.0

func get_gang_level_buff_percent(key: String) -> float:
	return _buff_dict_percent(gang_level_buffs, key)

func get_territory_buff_percent(key: String) -> float:
	return _buff_dict_percent(territory_buffs, key)

func _buff_dict_percent(src: Dictionary, key: String) -> float:
	if src.is_empty():
		return 0.0
	match key:
		"attack":
			return float(src.get("attackBonusPercent", 0))
		"defense":
			return float(src.get("defenseBonusPercent", 0))
		"hp":
			return float(src.get("hpBonusPercent", 0))
		"agility":
			return float(src.get("agilityBonusPercent", 0))
		"exp":
			return float(src.get("expBonusPercent", 0))
		"gold_drop":
			return float(src.get("goldDropBonusPercent", 0))
	return 0.0

func _apply_buff_payload(data: Dictionary) -> void :
	if data.has("buffs"):
		buffs = data.get("buffs", {})
		buffs_updated.emit(buffs)
	if data.has("gangLevelBuffs"):
		gang_level_buffs = data.get("gangLevelBuffs", {})
	if data.has("territoryBuffs"):
		territory_buffs = data.get("territoryBuffs", {})

func _clear_buffs() -> void :
	buffs = {}
	gang_level_buffs = {}
	territory_buffs = {}
	buffs_updated.emit(buffs)

func apply_heartbeat_buffs(data: Dictionary) -> void :
	if not data is Dictionary or data.is_empty():
		_clear_buffs()
		return
	buffs = data.duplicate(true)
	buffs_updated.emit(buffs)

func _apply_save_slice(data: Dictionary) -> void :
	if not game_manager:
		return
	var save_data = data.get("saveData", {})
	if not save_data is Dictionary or save_data.is_empty():
		return
	var pd: Dictionary = save_data.get("playerData", {})
	if pd is Dictionary and not pd.is_empty() and game_manager.player:

		if pd.has("yuanbao_currency"):
			game_manager.player.yuanbao_currency = maxi(0, int(pd.get("yuanbao_currency", 0)))
			game_manager.yuanbao_changed.emit(game_manager.player.yuanbao_currency)
		if pd.has("gold"):
			game_manager.player.gold = maxi(0, int(pd.get("gold", 0)))
			game_manager.gold_changed.emit(game_manager.player.gold)
		var ts: = float(pd.get("timestamp", 0))
		if ts > 0:
			game_manager._last_local_save_timestamp = max(game_manager._last_local_save_timestamp, ts)
	game_manager.apply_cloud_save(save_data, {"reward_inventory_slice": true})

func _update_used_emblem_ids(data: Dictionary) -> void :
	var raw = data.get("usedEmblemIds", data.get("used_emblem_ids", []))
	if not raw is Array:
		return
	var ids: Array = []
	for entry in raw:
		var emblem_id: = int(entry)
		if emblem_id >= 1 and emblem_id <= 32 and not emblem_id in ids:
			ids.append(emblem_id)
	used_emblem_ids = ids

func _normalize_shop_data(data: Dictionary) -> Dictionary:
	var out: Dictionary = data.duplicate(true)
	var shop_arr: Array = data.get("shop", [])
	var purchases: Dictionary = data.get("purchases", {})
	var gang_level: = int(data.get("gangLevel", 0))
	var items: Array = []
	for entry in shop_arr:
		if not entry is Dictionary:
			continue
		var item: Dictionary = entry.duplicate(true)
		var shop_id: = str(item.get("id", ""))
		var weekly_limit: = int(item.get("weeklyLimit", 0))
		var bought: = int(purchases.get(shop_id, 0))
		item["remaining"] = maxi(0, weekly_limit - bought)
		var min_lv: = int(item.get("minGangLevel", 1))
		item["locked"] = gang_level < min_lv
		items.append(item)
	out["items"] = items
	return out

func _emit_action_toast(action: String, success: bool, data: Dictionary) -> void :
	var member_actions: Array = ["kick", "set_role", "transfer", "approve", "kick_start", "kick_attack", "kick_repair"]
	if action not in TOAST_ACTIONS and action not in member_actions:
		return
	if not success:
		gang_toast.emit(str(data.get("error", "请求失败")), false)
		return
	match action:
		"create":
			if bool(data.get("duplicate", false)):
				return
			var create_contrib: = int(data.get("contributionGained", 2000))
			gang_toast.emit("创建成功！帮贡 +%d" % create_contrib, true)
		"donate":
			var mat_gained: = int(data.get("materialsGained", 0))
			var toast_msg: = "捐献成功！帮贡 +%d，帮派资金 +%d" % [
				int(data.get("contributionGained", 0)), 
				int(data.get("fundsGained", 0)), 
			]
			if mat_gained > 0:
				toast_msg += "，帮派建设材料 +%d" % mat_gained
			gang_toast.emit(toast_msg, true)
		"shop_buy":
			gang_toast.emit("兑换成功！", true)
		"apply":
			if bool(data.get("joined", false)):
				gang_toast.emit("加入帮派成功！", true)
			elif bool(data.get("pending", false)):
				gang_toast.emit("申请已提交，等待帮主审批", true)
			else:
				gang_toast.emit("申请已提交", true)
		"upgrade":
			gang_toast.emit("帮派升级成功！", true)
		"leave":
			gang_toast.emit("已退出帮派", true)
		"kick":
			gang_toast.emit("已踢出成员", true)
		"set_role":
			gang_toast.emit("职位已更新", true)
		"transfer":
			gang_toast.emit("禅让成功", true)
		"approve":
			if bool(data.get("approved", false)):
				gang_toast.emit("已批准入帮", true)
			else:
				gang_toast.emit("已拒绝申请", true)
		"kick_start":
			var kick_cost: = int(overview.get("config", {}).get("kickHallCost", 50000))
			var defender_name: = str(data.get("defenderGangName", "")).strip_edges()
			var prep_m: = int(data.get("prepMinutes", overview.get("config", {}).get("kickPrepMinutes", 30)))
			if defender_name.is_empty():
				gang_toast.emit("宣战成功！%d 分钟后开战 · 消耗帮派资金 %d" % [prep_m, kick_cost], true)
			else:
				gang_toast.emit("已向【%s】宣战！%d 分钟后开战 · 消耗帮派资金 %d" % [defender_name, prep_m, kick_cost], true)
		"kick_attack":
			var won: = bool(data.get("won", false))
			var auto_win: = bool(data.get("autoWin", data.get("auto_win", false)))
			var status: = str(data.get("status", ""))
			var contrib: = int(data.get("contributionGained", 0))
			var kick_msg: = ""
			if status == "won":
				var mat_steal: = int(data.get("materialSteal", data.get("material_steal", -1)))
				var fund_steal: = int(data.get("fundSteal", data.get("fund_steal", -1)))
				if mat_steal >= 0 and fund_steal >= 0:
					kick_msg = "帮战胜利！夺取帮派资金 %d、建设材料 %d · 帮贡 +%d" % [fund_steal, mat_steal, contrib]
				else:
					kick_msg = "帮战胜利！已夺取对方帮派资源 · 帮贡 +%d" % contrib
			elif auto_win:
				kick_msg = "对方无人防守，直接获胜！帮贡 +%d" % contrib
			else:
				kick_msg = "进攻%s！帮贡 +%d" % ["胜利" if won else "失败", contrib]
			if not auto_win:
				kick_msg += _replay_watch_hint(data)
			gang_toast.emit(kick_msg, true)
		"kick_repair":
			var dq: Dictionary = data.get("defenseQuota", {})
			var repairs_left: = int(data.get("repairsLeft", dq.get("repairLeft", 0)))
			gang_toast.emit("补防成功！耐久 +1，已增加 1 个防守槽（剩余 %d 次）" % repairs_left, true)
		"kick_buy_attack_contribution":
			gang_toast.emit("已购买 1 次帮贡进攻次数", true)
		"kick_buy_attack":
			gang_toast.emit("已购买 1 次元宝进攻次数", true)
		"kick_buy_defense":
			gang_toast.emit("元宝补防成功！耐久 +1（剩余 %d 次）" % int(data.get("defenseQuota", {}).get("yuanbaoDefenseBoughtLeft", 0)), true)
		"siege_apply":
			gang_toast.emit("申请已提交，资金已冻结", true)
		"siege_bid":
			gang_toast.emit("出价已提交（盲盒保密）", true)
		"siege_forfeit":
			gang_toast.emit("已放弃竞价，资金已退还", true)
		"territory_abandon":
			gang_toast.emit("已放弃领地，该领地变为中立", true)
		"siege_attack":
			gang_toast.emit(format_siege_attack_result_message(data), true)
		"siege_buy_attack_contribution":
			gang_toast.emit("已购买 1 次帮贡进攻次数", true)
		"siege_buy_attack":
			gang_toast.emit("已购买 1 次元宝进攻次数", true)
		"siege_repair":
			gang_toast.emit("加固成功！耐久 +1，已增加防守槽（剩余 %d 次）" % int(data.get("defenseQuota", {}).get("repairLeft", 0)), true)
		"siege_buy_defense":
			gang_toast.emit("元宝加固成功！耐久 +1（剩余 %d 次）" % int(data.get("defenseQuota", {}).get("yuanbaoDefenseBoughtLeft", 0)), true)
		"siege_guard_set":
			gang_toast.emit("驻守镜像已更新", true)
		"siege_guard_clear":
			gang_toast.emit("已清除驻守配置", true)
		"siege_guard_join":
			gang_toast.emit("驻守成功", true)
		"territory_claim_daily_all":
			if bool(data.get("duplicate", false)):
				return
			var total_gold: = int(data.get("totalGold", 0))
			var total_materials: = int(data.get("totalMaterials", 0))
			var names: = _territory_claim_names(data.get("granted", []))
			var msg: = "领地收益领取成功"
			if not names.is_empty():
				msg += " · %s" % "、".join(names)
			if total_gold > 0:
				msg += " · 金币 +%s" % _format_reward_number(total_gold)
			if total_materials > 0:
				msg += " · 建设材料 +%d" % total_materials
			gang_toast.emit(msg, true)
		"gang_settings":
			gang_toast.emit("帮派设置已保存", true)

func _territory_claim_names(granted: Variant) -> PackedStringArray:
	var names: = PackedStringArray()
	if not granted is Array:
		return names
	for entry in granted:
		if not entry is Dictionary:
			continue
		var territory_name: = str(entry.get("name", "")).strip_edges()
		if territory_name.is_empty():
			territory_name = str(entry.get("territoryId", "")).strip_edges()
		if territory_name.is_empty() or names.has(territory_name):
			continue
		names.append(territory_name)
	return names

func _format_reward_number(value: int) -> String:
	if value <= 0:
		return "0"
	var yi: = value / 100000000
	var remainder: = value % 100000000
	var wan: = remainder / 10000
	var rest: = remainder % 10000
	var text: = ""
	if yi > 0:
		text += "%d亿" % yi
	if wan > 0:
		text += "%d万" % wan
	if rest > 0:
		text += str(rest)
	if text.is_empty():
		return str(value)
	return text

func _on_network_finished(action: String, success: bool, data: Dictionary) -> void :
	if not success:
		var err_msg: = str(data.get("error", "请求失败"))
		push_warning("[GangManager] %s failed: %s" % [action, err_msg])
		_emit_action_toast(action, false, data)
		if action == "title_activate":
			title_activated.emit({"success": false, "error": err_msg})
		if action == "overview":
			overview_failed.emit(err_msg)
		if action == "war_reports":
			war_reports_loading = false
			war_reports_error = err_msg
			war_reports_updated.emit()
		if action == "kick_history":
			kick_history_loading = false
			kick_history_error = err_msg
			kick_history_updated.emit()
		if action == "siege_history":
			siege_history_loading = false
			siege_history_error = err_msg
			siege_history_updated.emit()
		return
	match action:
		"overview":
			overview = data
			viewer_role = int(data.get("membership", {}).get("role", viewer_role))
			_update_used_emblem_ids(data)
			if not bool(data.get("hasGang", false)):
				_clear_buffs()
			else:
				_apply_buff_payload(data)
			overview_updated.emit(data)
		"members":
			members = data.get("members", [])
			applications = data.get("applications", [])
			viewer_role = int(data.get("viewerRole", overview.get("membership", {}).get("role", 4)))
			_members_last_fetch_ms = Time.get_ticks_msec()
		"shop":
			shop_data = _normalize_shop_data(data)
		"buffs":
			_apply_buff_payload(data)
		"territories":
			territories = data.get("territories", [])
		"war_reports":
			var raw_reports: Variant = data.get("reports", [])
			war_reports = raw_reports if raw_reports is Array else []
			war_reports_loading = false
			war_reports_error = ""
			war_reports_updated.emit()
		"siege_status":
			siege_status = data
			siege_active_sessions = data.get("activeSessions", [])
			participation_logs = data.get("participationLogs", [])
			if data.has("hasMirror"):
				has_gang_mirror = bool(data.get("hasMirror", false))
		"territory_claim_status":
			territory_claim_status = data
		"siege_guards":
			var tid: = str(data.get("territoryId", ""))
			if not tid.is_empty():
				siege_guards_cache[tid] = data
		"ranking":
			ranking = data.get("ranking", [])
			ranking_updated.emit(ranking)
		"list":
			_update_used_emblem_ids(data)
			if overview.is_empty():
				overview = {"hasGang": false, "recommended": data.get("gangs", [])}
			else:
				overview["recommended"] = data.get("gangs", [])
			overview_updated.emit(overview)
		"other_gangs":
			other_gangs = data.get("gangs", [])
		"kick_active":
			kick_active_sessions = data.get("asAttacker", [])
			has_gang_mirror = bool(data.get("hasMirror", has_gang_mirror))
			if data.has("kickActivityLogs"):
				kick_activity_logs = data.get("kickActivityLogs", [])
		"kick_defending":
			kick_defending_sessions = data.get("asDefender", [])
			if data.has("kickActivityLogs"):
				kick_activity_logs = data.get("kickActivityLogs", [])
		"kick_history":
			kick_history = data.get("records", [])
			kick_history_loading = false
			kick_history_error = ""
			kick_history_updated.emit()
		"siege_history":
			siege_history = data.get("records", [])
			siege_history_loading = false
			siege_history_error = ""
			siege_history_updated.emit()
		"gang_mirror_get", "gang_mirror_update":
			has_gang_mirror = bool(data.get("hasMirror", false))
		"titles":
			var titles: Array = data.get("titles", [])
			titles_loaded.emit(titles)
			if game_manager and game_manager.title_manager:
				var gang_active_id: = ""
				for td in titles:
					if not td is Dictionary:
						continue
					var d = {
						"title_id": str(td.get("titleId", td.get("title_id", ""))), 
						"title_name": str(td.get("titleName", td.get("title_name", "一方霸主"))), 
						"attack_bonus": int(td.get("attackBonus", td.get("attack_bonus", 5000))), 
						"defense_bonus": int(td.get("defenseBonus", td.get("defense_bonus", 5000))), 
						"agility_bonus": int(td.get("agilityBonus", td.get("agility_bonus", 5000))), 
						"hp_bonus": int(td.get("hpBonus", td.get("hp_bonus", 15000))), 
						"source": "gang", 
						"expire_time": td.get("expireTime", td.get("expire_time", 0)), 
					}
					if bool(td.get("isActive", td.get("is_active", false))):
						gang_active_id = d["title_id"]
					var title = TitleDataClass.new()
					title.from_dict(d)
					game_manager.title_manager.add_title(title)
				if not gang_active_id.is_empty():
					game_manager.title_manager.apply_active_title_id(gang_active_id)
				game_manager.title_manager.titles_updated.emit()
		"title_activate":
			var activated_id: = str(data.get("titleId", data.get("title_id", "")))
			if activated_id.is_empty() and game_manager and game_manager.player:

				pass
			elif not activated_id.is_empty() and game_manager and game_manager.title_manager:
				game_manager.title_manager.apply_active_title_id(activated_id)
			title_activated.emit({"success": true, "titleId": activated_id})
			refresh_titles()
			if game_manager and game_manager.title_manager:
				game_manager.title_manager.load_server_titles()
		"create", "donate", "shop_buy":
			_emit_action_toast(action, true, data)
			_apply_save_slice(data)
			refresh_overview()
			if action == "shop_buy":
				refresh_shop()
		"apply", "approve", "leave", "upgrade", "kick", "set_role", "transfer":
			_emit_action_toast(action, true, data)
			refresh_overview()
			refresh_members(true)
			if action == "leave":
				_clear_buffs()
				refresh_territories()
				refresh_siege_status()
				refresh_war_reports()
		"kick_start", "kick_repair", "kick_buy_attack_contribution", "kick_buy_attack", "kick_buy_defense":
			_emit_action_toast(action, true, data)
			if action in ["kick_buy_attack", "kick_buy_defense"] and data.has("saveData"):
				_apply_save_slice(data)
			refresh_overview()
			refresh_kick_active()
			refresh_kick_defending()
		"kick_attack":
			kick_battle_ready.emit(data)
			refresh_overview()
			refresh_kick_active()
			refresh_kick_defending()
		"siege_apply", "siege_bid", "siege_forfeit", "siege_buy_attack_contribution", "siege_buy_attack", "siege_repair", "siege_buy_defense", "siege_guard_set", "siege_guard_clear", "siege_guard_join", "territory_abandon":
			_emit_action_toast(action, true, data)
			if action in ["siege_buy_attack", "siege_buy_defense"] and data.has("saveData"):
				_apply_save_slice(data)
			refresh_overview()
			refresh_territories()
			refresh_siege_status()
			refresh_war_reports()
		"territory_claim_daily_all":
			_emit_action_toast(action, true, data)
			if data.has("saveData"):
				_apply_save_slice(data)
			if gang_network:
				gang_network.fetch_territory_claim_status()
			refresh_overview()
		"gang_settings":
			_emit_action_toast(action, true, data)
			refresh_overview()
		"siege_attack":
			if data.has("saveData"):
				_apply_save_slice(data)
			siege_battle_ready.emit(data)
			refresh_overview()
			refresh_territories()
			refresh_siege_status()
			refresh_war_reports()
