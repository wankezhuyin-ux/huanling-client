extends Node
class_name XianMoSystem

signal faction_assigned(faction: String)
signal event_triggered(event: Dictionary)
signal action_points_changed(current: int, max_points: int)
signal score_changed(weekly: int, total: int)
signal week_settled(winner: String, rankings: Dictionary)
signal fragments_changed(count: int)
signal data_loaded()
signal join_failed(error: String)
signal adventure_failed(error: String)

const XianMoDataClass = preload("res://scripts/xianmo/xianmo_data.gd")
const XianMoEventDataClass = preload("res://scripts/xianmo/xianmo_event_data.gd")
const TitleDataClass = preload("res://scripts/title/title_data.gd")
const VipBenefits = preload("res://scripts/vip_benefits.gd")

var xianmo_data: XianMoData = null
var game_manager = null
var network = null

var global_state: Dictionary = {
	"week_number": 1, 
	"week_start_time": 0, 

	"week_end_unix": 0, 
	"xian_count": 0, 
	"mo_count": 0, 
	"xian_total_score": 0, 
	"mo_total_score": 0, 
	"registration_open": true
}

var _pending_join_faction: String = ""
var _is_loading: bool = false
var _adventure_request_pending: bool = false

func is_loading() -> bool:
	return _is_loading

func is_adventure_pending() -> bool:
	return _adventure_request_pending

const WEEK_DURATION: int = 604800
const REGISTRATION_CLOSE_OFFSET: int = 7200

const BEIJING_OFFSET_SEC: int = 28800

func _ready():
	xianmo_data = XianMoDataClass.new()
	_init_global_state()

func set_network(net):
	network = net
	if network:
		network.xianmo_join_success.connect(_on_xianmo_join_success)
		network.xianmo_join_failed.connect(_on_xianmo_join_failed)
		network.xianmo_info_loaded.connect(_on_xianmo_info_loaded)
		network.xianmo_faction_stats_loaded.connect(_on_xianmo_faction_stats_loaded)
		network.xianmo_ranking_loaded.connect(_on_xianmo_ranking_loaded)
		network.xianmo_adventure_success.connect(_on_xianmo_adventure_success)
		network.xianmo_adventure_failed.connect(_on_xianmo_adventure_failed)
		network.xianmo_week_info_loaded.connect(_on_xianmo_week_info_loaded)
		network.xianmo_battle_result_success.connect(_on_xianmo_battle_result_success)

func _on_xianmo_join_success(faction: String, nickname: String, new_gold: int):
	print("[XianMoSystem] _on_xianmo_join_success: faction=", faction, ", nickname=", nickname, " new_gold=", new_gold)
	xianmo_data.faction = faction
	xianmo_data.join_time = int(Time.get_unix_time_from_system())
	xianmo_data.action_points = get_max_action_points()
	xianmo_data.last_recover_time = xianmo_data.join_time
	xianmo_data.week_number = global_state.week_number
	_pending_join_faction = ""

	if faction == "xian":
		global_state.xian_count += 1
	else:
		global_state.mo_count += 1

	if game_manager and game_manager.player and new_gold >= 0:
		game_manager.player.gold = new_gold
		game_manager.gold_changed.emit(new_gold)

	if network:
		network.xianmo_get_faction_stats()

	faction_assigned.emit(faction)

func _on_xianmo_join_failed(error: String):
	print("[XianMoSystem] _on_xianmo_join_failed: error=", error)
	join_failed.emit(error)

func _on_xianmo_info_loaded(data: Dictionary):
	print("[XianMoSystem] _on_xianmo_info_loaded: data=", data)
	print("[XianMoSystem] joined=", data.get("joined", false))
	if data.get("joined", false):
		var player = data.get("player", {})
		print("[XianMoSystem] player=", player)
		print("[XianMoSystem] player.faction=", player.get("faction", "MISSING"))
		var faction: = str(player.get("faction", ""))
		if faction != "xian" and faction != "mo":
			print("[XianMoSystem] joined=true but faction invalid, treating as not joined")
			xianmo_data.faction = ""
			xianmo_data.join_time = 0
			xianmo_data.action_points = 24
			xianmo_data.weekly_score = 0
			if player.has("totalScore"):
				xianmo_data.total_score = int(player.get("totalScore", 0))
			elif data.has("totalScore"):
				xianmo_data.total_score = int(data.get("totalScore", 0))
		else:
			xianmo_data.faction = faction
			xianmo_data.join_time = int(Time.get_unix_time_from_system())
			xianmo_data.action_points = int(player.get("actionPoints", 24))
			xianmo_data.weekly_score = int(player.get("weeklyScore", 0))
			xianmo_data.total_score = int(player.get("totalScore", 0))
			xianmo_data.week_number = int(player.get("weekNumber", 1))
			xianmo_data.treasure_fragments = int(player.get("fragments", 0))
			xianmo_data.last_recover_time = int(Time.get_unix_time_from_system())
			print("[XianMoSystem] Loaded action_points=", xianmo_data.action_points, ", faction=", xianmo_data.faction)

			var unclaimed_chests = player.get("unclaimedChests", [])
			if game_manager and game_manager.xianmo_chest_manager:
				var server_chest_counts: = {
					"bronze": 0, 
					"silver": 0, 
					"gold": 0
				}
				if unclaimed_chests is Array:
					for chest in unclaimed_chests:
						if chest is Dictionary:
							var chest_type = str(chest.get("type", ""))
							var chest_count = max(0, int(chest.get("count", 1)))
							if server_chest_counts.has(chest_type):
								server_chest_counts[chest_type] += chest_count
				game_manager.xianmo_chest_manager.sync_chests_from_server(server_chest_counts)
	else:
		print("[XianMoSystem] Not joined, resetting faction")
		xianmo_data.faction = ""
		xianmo_data.join_time = 0
		xianmo_data.action_points = 24
		xianmo_data.weekly_score = 0
		if data.has("totalScore"):
			xianmo_data.total_score = int(data.get("totalScore", 0))
		xianmo_data.total_score = 0

	_is_loading = false
	data_loaded.emit()

func _on_xianmo_faction_stats_loaded(data: Dictionary):
	print("[XianMoSystem] _on_xianmo_faction_stats_loaded: data=", data)
	if data.has("xian"):
		global_state.xian_count = int(data.xian.get("count", 0))
		global_state.xian_total_score = int(data.xian.get("totalScore", 0))
	if data.has("mo"):
		global_state.mo_count = int(data.mo.get("count", 0))
		global_state.mo_total_score = int(data.mo.get("totalScore", 0))
	if data.has("weekNumber"):
		global_state.week_number = data.weekNumber
	_apply_server_week_bounds_from_dict(data)
	print("[XianMoSystem] global_state updated: xian_count=", global_state.xian_count, ", mo_count=", global_state.mo_count, ", xian_score=", global_state.xian_total_score, ", mo_score=", global_state.mo_total_score)
	data_loaded.emit()

func _on_xianmo_ranking_loaded(rankings: Array, week_number: int, faction: String):
	print("[XianMoSystem] _on_xianmo_ranking_loaded: faction=", faction, " count=", rankings.size())
	global_state.week_number = week_number
	if game_manager and game_manager.xianmo_ranking:
		if faction != "":
			game_manager.xianmo_ranking.set_rankings(faction, rankings)
		else:
			print("[XianMoSystem] faction is empty, skipping set_rankings")
	else:
		print("[XianMoSystem] game_manager or xianmo_ranking is null")

func _on_xianmo_adventure_success(data: Dictionary):
	_adventure_request_pending = false
	print("[XianMoSystem] _on_xianmo_adventure_success: data=", data)
	print("[XianMoSystem] data keys=", data.keys() if data is Dictionary else "not_dict")
	var score_gain = int(data.get("scoreGain", 0))
	xianmo_data.action_points = int(data.get("actionPoints", xianmo_data.action_points - 1))
	xianmo_data.weekly_score = int(data.get("newWeeklyScore", xianmo_data.weekly_score + score_gain))
	xianmo_data.total_score = int(data.get("newTotalScore", xianmo_data.total_score + max(0, score_gain)))

	# 藏宝图残片：服务端把总数算好了放在 data.fragments 里。
	# 这里不落地的话，残片只有重新登录拉 /xianmo/info 才会出现在「藏宝图」页，
	# 玩家看到的就是「捡到残片了，但藏宝图里一直是 0 张」。
	if data.has("fragments"):
		var frag_total: int = max(0, int(data.get("fragments", 0)))
		if frag_total != xianmo_data.treasure_fragments:
			xianmo_data.treasure_fragments = frag_total
			fragments_changed.emit(frag_total)

	action_points_changed.emit(xianmo_data.action_points, get_max_action_points())
	score_changed.emit(xianmo_data.weekly_score, xianmo_data.total_score)

	if game_manager and game_manager.quest_manager:
		game_manager.quest_manager.on_xianmo_battle_joined()

	var event_id = data.get("eventId", "nothing_happened")
	var event_type = data.get("eventType", "empty")

	print("[XianMoSystem] event_id=", event_id, ", event_type=", event_type, ", has_reward=", data.has("reward"))
	if data.has("reward"):
		print("[XianMoSystem] reward=", data.reward)
		print("[XianMoSystem] reward type=", typeof(data.reward), ", is_dict=", data.reward is Dictionary)

	var event = {
		"type": event_type, 
		"event_id": event_id, 
		"score": score_gain, 
		"name": _get_event_name(event_id), 
		"description": _get_event_description(event_id), 
		"server_processed": true
	}

	if event_type == "battle":
		event["mirror_battle"] = true
		event["score_win"] = max(score_gain, 30)
		event["score_lose"] = min(score_gain, 10)
	elif event_type == "treasure":
		event["chest_type"] = "bronze"
	elif event_type == "trap":
		event["damage_percent"] = 10

	if data.has("reward"):
		event["reward"] = data.reward
		print("[XianMoSystem] event reward set to=", event["reward"])

	if data.has("reward") and data.reward is Dictionary:
		var faction_score_change = int(data.reward.get("factionScoreChange", 0))
		if faction_score_change > 0:
			print("[XianMoSystem] faction score changed, refreshing faction stats")
			load_faction_stats()

	print("[XianMoSystem] emitting event_triggered with event=", event)
	event_triggered.emit(event)


	if game_manager:
		game_manager.load_server_broadcasts()

func _convert_server_event_type(server_type: String) -> String:
	match server_type:
		"battle": return "battle"
		"treasure": return "treasure"
		"discovery": return "fortune"
		"rescue": return "fortune"
		"empty": return "empty"
		"trap": return "trap"
		_: return "fortune"

func _get_event_name(event_type: String) -> String:
	if XianMoEventData.EVENTS.has(event_type):
		return XianMoEventData.EVENTS[event_type].get("name", "未知事件")
	return "未知事件"

func _on_xianmo_adventure_failed(error: String):
	_adventure_request_pending = false
	adventure_failed.emit(error)

func _on_xianmo_week_info_loaded(data: Dictionary):
	if data.is_empty():
		return

	if data.has("weekNumber"):
		global_state.week_number = data.weekNumber
	_apply_server_week_bounds_from_dict(data)
	if data.has("winner"):
		var winner = data.winner
		var xian_score = data.get("xianScore", 0)
		var mo_score = data.get("moScore", 0)
		var player_rank = data.get("playerRank", 0)
		var rewards = data.get("rewards", {})

		if game_manager and game_manager.xianmo_reward and xianmo_data.is_joined():
			var is_winner = (winner == xianmo_data.faction)
			if player_rank > 0 and player_rank <= 10:
				game_manager.xianmo_reward.apply_ranking_rewards(xianmo_data.faction, player_rank, is_winner)
			else:
				game_manager.xianmo_reward.apply_participation_rewards()

		week_settled.emit(winner, rewards)

		if game_manager:
			game_manager.broadcast_event("xianmo_week_settled", "", {
				"winner": winner, 
				"xian_score": xian_score, 
				"mo_score": mo_score
			})

func get_week_info():
	if network and network.is_logged_in():
		network.xianmo_get_week_info()

func _get_event_description(event_id: String) -> String:
	if XianMoEventData.EVENT_DESCRIPTIONS.has(event_id):
		var descriptions = XianMoEventData.EVENT_DESCRIPTIONS[event_id]
		if descriptions.size() > 0:
			return descriptions[randi() % descriptions.size()]

	if XianMoEventData.EVENTS.has(event_id):
		var event_data = XianMoEventData.EVENTS[event_id]
		var event_type_cat = event_data.get("type", "")
		match event_type_cat:
			"pet": return "你遇到了一只灵兽！"
			"treasure": return "你发现了隐藏的宝藏！"
			"battle": return "你遭遇了一场激烈的战斗！"
			"fortune": return "你遇到了一次奇遇！"
			"training": return "你找到了一处修炼圣地！"
			"trap": return "你不小心触发了陷阱！"
			"empty": return "这里空无一物..."
			"fragment": return "你发现了神秘的残片！"
			_: return "你经历了一次冒险！"
	return "你经历了一次冒险！"

func load_from_server():
	print("[XianMoSystem] load_from_server called, network=", network, ", is_logged_in=", network.is_logged_in() if network else "no network")
	if network and network.is_logged_in():
		_is_loading = true
		network.xianmo_get_info()
		network.xianmo_get_faction_stats()
	else:
		print("[XianMoSystem] Network not available, skipping load")

func load_faction_stats():
	if network:
		network.xianmo_get_faction_stats()

func _init_global_state():
	var now = int(Time.get_unix_time_from_system())
	global_state.week_start_time = _get_week_start_beijing_unix(now)
	global_state.week_end_unix = global_state.week_start_time + WEEK_DURATION
	global_state.week_number = _calculate_week_number(global_state.week_start_time)
	global_state.registration_open = _is_registration_open(now)


func _beijing_datetime_dict(unix_sec: int) -> Dictionary:

	return Time.get_datetime_dict_from_unix_time(int(unix_sec) + BEIJING_OFFSET_SEC)


func _get_week_start_beijing_unix(current_unix: int) -> int:
	var d: = _beijing_datetime_dict(current_unix)
	var wd: int = int(d.get("weekday", 0))
	var days_since_monday: = 6 if wd == Time.WEEKDAY_SUNDAY else (wd - Time.WEEKDAY_MONDAY)
	var sec_into_week: = days_since_monday * 86400 + int(d.get("hour", 0)) * 3600 + int(d.get("minute", 0)) * 60 + int(d.get("second", 0))
	return int(current_unix) - sec_into_week


func _parse_server_timestamp(v: Variant) -> int:
	if v == null:
		return 0
	match typeof(v):
		TYPE_INT:
			return int(v)
		TYPE_FLOAT:
			return int(v)
	var s: = str(v).strip_edges()
	if s.is_empty():
		return 0
	if not s.contains("T") and s.contains(" "):
		s = s.replace(" ", "T")
	var u: = Time.get_unix_time_from_datetime_string(s)
	if u >= 0:
		return int(u)
	return 0


func _apply_server_week_bounds_from_dict(data: Dictionary) -> void :
	var start_u: = 0
	var end_u: = 0
	if data.has("startTime"):
		start_u = _parse_server_timestamp(data.get("startTime"))
	if data.has("endTime"):
		end_u = _parse_server_timestamp(data.get("endTime"))
	if start_u <= 0 and data.has("weekStartTime"):
		start_u = _parse_server_timestamp(data.get("weekStartTime"))
	if start_u > 0:
		global_state.week_start_time = start_u
	if end_u > 0:
		global_state.week_end_unix = end_u
	elif start_u > 0:
		global_state.week_end_unix = start_u + WEEK_DURATION


func _effective_week_end_unix() -> int:
	var we: = int(global_state.get("week_end_unix", 0))
	if we > 0:
		return we
	var ws: = int(global_state.get("week_start_time", 0))
	if ws > 0:
		return ws + WEEK_DURATION
	return 0

func _calculate_week_number(week_start: int) -> int:
	var base_week = 1
	var base_time = 0
	var weeks_elapsed = (week_start - base_time) / WEEK_DURATION
	return base_week + weeks_elapsed

func _is_registration_open(current_time: int) -> bool:
	var d: = _beijing_datetime_dict(current_time)
	if int(d.get("weekday", -1)) == Time.WEEKDAY_SUNDAY:
		if int(d.get("hour", 0)) >= 22:
			return false
	return true

func set_game_manager(manager):
	game_manager = manager

func join_xianmo() -> Dictionary:
	var result = {"success": false, "message": "", "faction": ""}

	if xianmo_data.is_joined():
		result.message = "你已经加入了仙魔战场！"
		result.faction = xianmo_data.faction
		return result

	if game_manager and game_manager.player:
		if game_manager.player.cultivation < 1000:
			result.message = "修行值需达到1000才能参与仙魔战场！"
			return result
		if game_manager.player.gold < 1000000:
			result.message = "需要100万金币才能参与仙魔战场！"
			return result

	if not global_state.registration_open:
		result.message = "本周报名已截止，请等待下周！"
		return result

	var faction = assign_faction()

	if network and network.is_logged_in():
		_pending_join_faction = faction
		network.xianmo_join(faction)
		result.message = "正在加入..."
		return result

	xianmo_data.faction = faction
	xianmo_data.join_time = int(Time.get_unix_time_from_system())
	xianmo_data.action_points = get_max_action_points()
	xianmo_data.last_recover_time = xianmo_data.join_time
	xianmo_data.week_number = global_state.week_number

	if faction == "xian":
		global_state.xian_count += 1
	else:
		global_state.mo_count += 1

	result.success = true
	result.message = "成功加入%s阵营！" % ("仙道" if faction == "xian" else "魔道")
	result.faction = faction

	faction_assigned.emit(faction)
	return result

func join_faction(faction: String) -> Dictionary:
	var result = {"success": false, "message": "", "faction": ""}

	print("[XianMoSystem] join_faction called, faction=", faction, ", is_joined=", xianmo_data.is_joined())

	if xianmo_data.is_joined():
		result.message = "你已经加入了仙魔战场！"
		result.faction = xianmo_data.faction
		return result

	if game_manager and game_manager.player:
		if game_manager.player.cultivation < 1000:
			result.message = "修行值需达到1000才能参与仙魔战场！"
			return result
		if game_manager.player.gold < 1000000:
			result.message = "需要100万金币才能参与仙魔战场！"
			return result

	if not global_state.registration_open:
		result.message = "本周报名已截止，请等待下周！"
		return result

	if faction != "xian" and faction != "mo":
		result.message = "无效的阵营选择！"
		return result

	if network and network.is_logged_in():
		print("[XianMoSystem] Sending join request to server...")
		_pending_join_faction = faction
		network.xianmo_join(faction)
		result.success = false
		result.message = "正在加入..."
		return result

	print("[XianMoSystem] No network, setting local data only")
	xianmo_data.faction = faction
	xianmo_data.join_time = int(Time.get_unix_time_from_system())
	xianmo_data.action_points = get_max_action_points()
	xianmo_data.last_recover_time = xianmo_data.join_time
	xianmo_data.week_number = global_state.week_number

	if faction == "xian":
		global_state.xian_count += 1
	else:
		global_state.mo_count += 1

	result.success = true
	result.message = "成功加入%s阵营！" % ("仙道" if faction == "xian" else "魔道")
	result.faction = faction

	faction_assigned.emit(faction)
	return result

func assign_faction() -> String:
	var xian_count = global_state.xian_count
	var mo_count = global_state.mo_count
	var total = xian_count + mo_count

	if total == 0:
		return ["xian", "mo"][randi() % 2]

	var xian_ratio = float(xian_count) / total

	if xian_ratio > 0.55:
		return "mo"
	elif xian_ratio < 0.45:
		return "xian"
	else:
		return ["xian", "mo"][randi() % 2]

func get_faction_comparison() -> Dictionary:
	if game_manager and game_manager.xianmo_ranking:
		return game_manager.xianmo_ranking.get_faction_comparison()
	return {
		"xian": {"count": global_state.xian_count, "total_score": global_state.xian_total_score, "leading": false}, 
		"mo": {"count": global_state.mo_count, "total_score": global_state.mo_total_score, "leading": false}
	}

func start_adventure() -> Dictionary:
	var result = {"success": false, "message": "", "event": {}}

	if not xianmo_data.is_joined():
		result.message = "请先加入仙魔战场！"
		return result

	print("[XianMoSystem] start_adventure: action_points=", xianmo_data.action_points)

	if xianmo_data.action_points < 1:
		result.message = "行动力不足！"
		return result

	if _adventure_request_pending:
		result.message = "正在探险中，请稍候..."
		return result

	if game_manager and game_manager.xianmo_battle_processor:
		game_manager.xianmo_battle_processor.request_mirror_data()

	if network and network.is_logged_in():
		_adventure_request_pending = true
		network.xianmo_adventure(1)
		result.success = true
		result.message = "正在探险..."
		return result

	xianmo_data.action_points -= 1
	action_points_changed.emit(xianmo_data.action_points, get_max_action_points())

	if game_manager and game_manager.quest_manager:
		game_manager.quest_manager.on_xianmo_battle_joined()

	var event = XianMoEventDataClass.get_random_event()
	event["description"] = XianMoEventDataClass.get_random_description(event.get("event_id", ""))

	result.success = true
	result.event = event

	event_triggered.emit(event)
	return result

func process_event_result(event: Dictionary, result_data: Dictionary) -> Dictionary:
	var result = {"success": true, "score": 0, "rewards": [], "message": ""}
	if network and network.is_logged_in() and not event.get("server_processed", false):
		result.success = false
		result.message = "事件尚未通过服务端结算"
		return result

	if event.get("server_processed", false):
		result.score = event.get("score", 0)
		var server_reward = result_data.get("reward", null)
		if server_reward:
			result.rewards = [server_reward]
		else:
			result.rewards = result_data.get("rewards", [])
		result.message = result_data.get("message", "")
		await grant_rewards(result.rewards, {
			"event_id": str(event.get("event_id", "")), 
			"event_type": str(event.get("type", ""))
		})
		return result

	var base_score = event.get("score", 0)
	if event.has("score_win") and result_data.get("won", false):
		base_score = event.score_win
	elif event.has("score_lose") and not result_data.get("won", true):
		base_score = event.score_lose

	if xianmo_data.buff_next_event_score > 0:
		base_score += xianmo_data.buff_next_event_score
		xianmo_data.buff_next_event_score = 0

	if base_score < 0:
		base_score = max(base_score, - xianmo_data.weekly_score)

	xianmo_data.weekly_score = max(0, xianmo_data.weekly_score + base_score)
	xianmo_data.total_score += max(0, base_score)
	xianmo_data.events_completed += 1

	if xianmo_data.faction == "xian":
		global_state.xian_total_score += max(0, base_score)
	elif xianmo_data.faction == "mo":
		global_state.mo_total_score += max(0, base_score)

	if game_manager and game_manager.xianmo_ranking:
		var player_id = game_manager.player.player_name if game_manager.player else "unknown"
		var player_name = player_id
		game_manager.xianmo_ranking.update_player_score(
			player_id, 
			player_name, 
			xianmo_data.faction, 
			xianmo_data.weekly_score
		)

	if event.get("next_event_score_bonus", 0) > 0:
		xianmo_data.buff_next_event_score = event.next_event_score_bonus

	result.score = base_score
	result.rewards = result_data.get("rewards", [])
	result.message = result_data.get("message", "")

	score_changed.emit(xianmo_data.weekly_score, xianmo_data.total_score)

	await grant_rewards(result.rewards, {
		"event_id": str(event.get("event_id", "")), 
		"event_type": str(event.get("type", ""))
	})

	return result

func grant_rewards(rewards: Array, reward_context: Dictionary = {}) -> void :
	if not game_manager:
		return

	var action_points_changed_local: = false
	var gold_online_total: = 0

	for reward in rewards:
		var reward_type = str(reward.get("type", ""))
		var amount = int(reward.get("amount", reward.get("value", reward.get("count", 0))))
		match reward_type:
			"pet":
				pass
			"chest":
				if game_manager.xianmo_chest_manager:
					game_manager.xianmo_chest_manager.add_chest(reward.chestType, 1)
			"item":
				if game_manager.inventory_manager:
					var item_id = str(reward.get("itemId", reward.get("item_id", reward.get("itemName", ""))))
					if not item_id.is_empty():
						game_manager.inventory_manager.add_item(item_id, reward.get("count", 1))
			"gold":
				if network and network.is_logged_in() and game_manager.player:
					gold_online_total += maxi(0, amount)
				elif game_manager.player:
					game_manager.player.gold += amount
			"exp":
				if game_manager.player:
					game_manager.player.add_exp(amount)
			"cultivation":
				if game_manager.player:
					game_manager.player.cultivation += amount
			"action_points", "action_point", "actionPoints":
				xianmo_data.action_points = min(get_max_action_points(), xianmo_data.action_points + amount)
				action_points_changed_local = true
			"action_points_cost", "action_points_loss", "actionPointsCost", "actionPointsLoss":
				xianmo_data.action_points = max(0, xianmo_data.action_points - amount)
				action_points_changed_local = true
			"fragment":
				xianmo_data.treasure_fragments += reward.get("count", 1)
			"score":
				xianmo_data.weekly_score += amount
				xianmo_data.total_score += amount
			"score_buff":
				xianmo_data.buff_next_event_score += amount
			"buff":
				if reward.get("buff_type") == "attack":
					xianmo_data.buff_attack_percent += reward.get("value", 0)
			"trap":

				var trap_cost = int(reward.get("action_points_cost", 0))
				var trap_loss = int(reward.get("action_points_loss", 0))
				var trap_total = trap_cost + trap_loss
				if trap_total > 0:
					xianmo_data.action_points = max(0, xianmo_data.action_points - trap_total)
					action_points_changed_local = true
			_:
				pass

	if gold_online_total > 0 and game_manager and game_manager.player and game_manager.network:
		var op_id: = "xianmo_misc_gold_%d_%s" % [Time.get_ticks_usec(), str(randi())]
		var context: = {
			"source": "adventure_event", 
			"eventId": str(reward_context.get("event_id", "")).strip_edges()
		}
		if str(context.get("eventId", "")).is_empty():
			context["eventId"] = "legacy_%d" % int(Time.get_unix_time_from_system())
		var er: Dictionary = await game_manager.wait_economy("economy_xianmo_misc_gold", func():
			game_manager.network.economy_xianmo_misc_gold(op_id, gold_online_total, context)
		)
		if er.get("ok", false):
			var xd: Variant = er.get("data", {})
			if xd is Dictionary and (xd as Dictionary).has("newGold"):
				game_manager.player.gold = int((xd as Dictionary).get("newGold", game_manager.player.gold))
			game_manager.gold_changed.emit(game_manager.player.gold)
		else:
			push_warning("[XianMoSystem] economy_xianmo_misc_gold failed: " + str(er.get("err", "")))

	if action_points_changed_local:
		action_points_changed.emit(xianmo_data.action_points, get_max_action_points())

func recover_action_points():
	var now = int(Time.get_unix_time_from_system())
	var elapsed = now - xianmo_data.last_recover_time
	var tier: = 0
	if game_manager and game_manager.player:
		tier = VipBenefits.tier_from_player(game_manager.player)
	var recover_rate: = VipBenefits.xianmo_recover_interval_seconds(tier)

	var points_to_recover = int(elapsed / recover_rate)
	if points_to_recover <= 0:
		return

	var max_points = get_max_action_points()
	xianmo_data.action_points = min(xianmo_data.action_points + points_to_recover, max_points)
	xianmo_data.last_recover_time += points_to_recover * recover_rate

	action_points_changed.emit(xianmo_data.action_points, max_points)

func get_max_action_points() -> int:
	var tier: = 0
	if game_manager and game_manager.player:
		tier = VipBenefits.tier_from_player(game_manager.player)
	return VipBenefits.xianmo_max_action_points(tier)

func get_action_points_info() -> Dictionary:
	var tier: = 0
	if game_manager and game_manager.player:
		tier = VipBenefits.tier_from_player(game_manager.player)
	return {
		"current": xianmo_data.action_points, 
		"max": get_max_action_points(), 
		"recover_rate": VipBenefits.xianmo_recover_interval_seconds(tier)
	}

func add_fragments(count: int):
	xianmo_data.treasure_fragments += count
	fragments_changed.emit(xianmo_data.treasure_fragments)

func use_fragments(count: int) -> bool:
	if xianmo_data.treasure_fragments < count:
		return false
	xianmo_data.treasure_fragments -= count
	fragments_changed.emit(xianmo_data.treasure_fragments)
	return true

func exchange_treasure_map() -> Dictionary:
	return {
		"success": false, 
		"message": "藏宝图兑换已改为服务端结算，请使用网络接口", 
		"gold": 0, 
		"jackpot": false
	}

func check_week_end() -> bool:
	var now = int(Time.get_unix_time_from_system())
	var week_end: = _effective_week_end_unix()
	if week_end <= 0:
		return false
	return now >= week_end

func get_week_remaining_time() -> int:
	var now = int(Time.get_unix_time_from_system())
	var week_end: = _effective_week_end_unix()
	if week_end <= 0:
		return 0
	return max(0, week_end - now)

func get_week_remaining_time_string() -> String:
	var remaining = get_week_remaining_time()
	if remaining <= 0:
		return "已结束"

	var days = remaining / 86400
	var hours = (remaining % 86400) / 3600
	var minutes = (remaining % 3600) / 60

	return "%d天%d时%d分" % [days, hours, minutes]

func settle_weekly_rewards() -> Dictionary:
	if network and network.is_logged_in():
		return {
			"winner": "", 
			"xian_total": 0, 
			"mo_total": 0, 
			"player_rank": 0, 
			"player_rewards": {}, 
			"message": "周结算由服务端处理"
		}
	var result = {
		"winner": "", 
		"xian_total": global_state.xian_total_score, 
		"mo_total": global_state.mo_total_score, 
		"player_rank": 0, 
		"player_rewards": {}
	}

	if global_state.xian_total_score > global_state.mo_total_score:
		result.winner = "xian"
	elif global_state.mo_total_score > global_state.xian_total_score:
		result.winner = "mo"
	else:
		result.winner = "draw"

	if game_manager and game_manager.xianmo_ranking and game_manager.player:
		var player_id = game_manager.player.player_name
		result.player_rank = game_manager.xianmo_ranking.get_player_rank(player_id, xianmo_data.faction)

	if game_manager and game_manager.xianmo_reward and xianmo_data.is_joined():
		var rewards
		var is_winner = (result.winner == xianmo_data.faction)
		if result.player_rank > 0 and result.player_rank <= 10:
			rewards = game_manager.xianmo_reward.generate_ranking_rewards(xianmo_data.faction, result.player_rank, is_winner)
		else:
			rewards = game_manager.xianmo_reward.generate_participation_rewards()

		result.player_rewards = rewards
		game_manager.xianmo_reward.apply_rewards_to_player(rewards)

	week_settled.emit(result.winner, result.player_rewards)

	xianmo_data.reset_weekly()

	return result

func get_faction_name(faction: String) -> String:
	match faction:
		"xian": return "仙道"
		"mo": return "魔道"
		_: return "未知"

func get_faction_icon(faction: String) -> String:
	match faction:
		"xian": return "☯️"
		"mo": return "☠️"
		_: return "❓"

func to_dict() -> Dictionary:
	return {
		"xianmo_data": xianmo_data.to_dict(), 
		"global_state": global_state
	}

func from_dict(data: Dictionary):
	if data.has("xianmo_data"):
		xianmo_data.from_dict(data.xianmo_data)
	if data.has("global_state"):
		global_state = data.global_state
		if not global_state.has("week_end_unix"):
			global_state["week_end_unix"] = 0

	recover_action_points()
	remove_expired_titles()

func check_week_settlement():
	_check_and_settle_week()

func _check_and_settle_week():
	var now = int(Time.get_unix_time_from_system())
	var current_week_start = _get_week_start_beijing_unix(now)
	var current_week_number = _calculate_week_number(current_week_start)

	if xianmo_data.week_number > 0 and xianmo_data.week_number < current_week_number:
		if xianmo_data.is_joined() and not xianmo_data.weekly_rewards_claimed:
			var result = settle_weekly_rewards()
			if game_manager:
				game_manager.broadcast_event("xianmo_week_settled", "", {
					"winner": result.winner, 
					"xian_score": result.xian_total, 
					"mo_score": result.mo_total
				})

		xianmo_data.reset_weekly()
		xianmo_data.week_number = current_week_number
		xianmo_data.faction = ""
		xianmo_data.join_time = 0
		xianmo_data.action_points = get_max_action_points()
		xianmo_data.last_recover_time = now

	global_state.week_start_time = current_week_start
	global_state.week_end_unix = current_week_start + WEEK_DURATION
	global_state.week_number = current_week_number
	global_state.registration_open = _is_registration_open(now)

func remove_expired_titles():
	if game_manager and game_manager.player:
		game_manager.player.remove_expired_titles()

func report_battle_result(event_id: String, victory: bool, score_gain: int, opponent: String):
	print("[XianMoSystem] report_battle_result: event_id=", event_id, ", victory=", victory, ", score_gain=", score_gain, ", opponent=", opponent)
	if network and network.is_logged_in():
		network.xianmo_report_battle_result(event_id, victory, score_gain, opponent)
	else:
		_apply_battle_result_locally(victory, score_gain)

func _on_xianmo_battle_result_success(data: Dictionary):
	print("[XianMoSystem] _on_xianmo_battle_result_success: data=", data)
	var new_weekly_score = data.get("newWeeklyScore", xianmo_data.weekly_score)
	var new_total_score = data.get("newTotalScore", xianmo_data.total_score)
	var score_gain = data.get("scoreGain", 0)

	xianmo_data.weekly_score = new_weekly_score
	xianmo_data.total_score = new_total_score

	score_changed.emit(xianmo_data.weekly_score, xianmo_data.total_score)

	if xianmo_data.faction == "xian":
		global_state.xian_total_score += max(0, score_gain)
	elif xianmo_data.faction == "mo":
		global_state.mo_total_score += max(0, score_gain)

func _apply_battle_result_locally(victory: bool, score_gain: int):
	xianmo_data.weekly_score = max(0, xianmo_data.weekly_score + score_gain)
	xianmo_data.total_score += max(0, score_gain)

	score_changed.emit(xianmo_data.weekly_score, xianmo_data.total_score)

	if xianmo_data.faction == "xian":
		global_state.xian_total_score += max(0, score_gain)
	elif xianmo_data.faction == "mo":
		global_state.mo_total_score += max(0, score_gain)
