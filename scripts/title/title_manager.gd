extends Node
class_name TitleManager

const TitleDataClass = preload("res://scripts/title/title_data.gd")

var game_manager = null
var network = null

signal title_added(title)
signal title_removed(title_id: String)
signal active_title_changed(title_id: String)
signal titles_updated()
signal server_titles_loaded(titles: Array)

func set_game_manager(gm):
	game_manager = gm

func set_network(net):
	if network:
		if network.xianmo_titles_loaded.is_connected(_on_server_titles_loaded):
			network.xianmo_titles_loaded.disconnect(_on_server_titles_loaded)
		if network.xianmo_title_activated.is_connected(_on_title_activated):
			network.xianmo_title_activated.disconnect(_on_title_activated)
		if network.xianmo_title_deactivated.is_connected(_on_title_deactivated):
			network.xianmo_title_deactivated.disconnect(_on_title_deactivated)
		if network.arena_titles_loaded.is_connected(_on_arena_titles_loaded):
			network.arena_titles_loaded.disconnect(_on_arena_titles_loaded)
		if network.arena_title_activated.is_connected(_on_arena_title_activated):
			network.arena_title_activated.disconnect(_on_arena_title_activated)
	network = net
	if network:
		network.xianmo_titles_loaded.connect(_on_server_titles_loaded)
		network.xianmo_title_activated.connect(_on_title_activated)
		network.xianmo_title_deactivated.connect(_on_title_deactivated)
		network.arena_titles_loaded.connect(_on_arena_titles_loaded)
		network.arena_title_activated.connect(_on_arena_title_activated)

func _on_server_titles_loaded(titles: Array):
	if titles.is_empty():
		print("[TitleManager] 服务器称号数据为空")
		if game_manager and game_manager.player:
			game_manager.player.repair_active_title_reference_after_load()
			titles_updated.emit()
		server_titles_loaded.emit([])
		return

	var server_active = ""
	for title_data in titles:
		if int(title_data.get("is_active", 0)) == 1:
			server_active = str(title_data.get("title_id", ""))

	for title_data in titles:
		var d = {
			"title_id": title_data.get("title_id", ""), 
			"title_name": title_data.get("title_name", ""), 
			"attack_bonus": title_data.get("attack_bonus", 0), 
			"defense_bonus": title_data.get("defense_bonus", 0), 
			"agility_bonus": title_data.get("agility_bonus", 0), 
			"hp_bonus": title_data.get("hp_bonus", 0), 
			"source": "xianmo", 
			"expire_time_unix": title_data.get("expire_time_unix", null), 
			"expire_time": title_data.get("expire_time", 0), 
			"week_number": title_data.get("week_number", 0)
		}
		var title = TitleDataClass.new()
		title.from_dict(d)

		if _has_title(title.title_id):
			for t in get_all_titles():
				if t is TitleDataClass and t.title_id == title.title_id:
					t.from_dict(d)
					break
		else:
			add_title(title)

	if game_manager and game_manager.player:
		if not server_active.is_empty():
			if game_manager.player.active_title_id != server_active:
				game_manager.player.active_title_id = server_active
				active_title_changed.emit(server_active)
		else:

			var local_id: = str(game_manager.player.active_title_id)
			if not local_id.is_empty():
				var local_title = _find_title_by_id(local_id)
				if local_title is TitleDataClass and str(local_title.source) == "xianmo":
					game_manager.player.active_title_id = ""
					active_title_changed.emit("")
		game_manager.player.repair_active_title_reference_after_load()

	server_titles_loaded.emit(titles)
	titles_updated.emit()

	if game_manager:
		game_manager.call_deferred("save_game", true)

func _on_title_activated(data: Dictionary):
	if bool(data.get("success", false)):
		print("[TitleManager] 称号激活成功")
		var tid: = str(data.get("titleId", data.get("title_id", "")))
		if not tid.is_empty():
			apply_active_title_id(tid)
	else:
		print("[TitleManager] 称号激活失败")

func _on_title_deactivated(data: Dictionary):
	if bool(data.get("success", false)):
		print("[TitleManager] 称号已卸下")
		deactivate_title()
		if game_manager:
			game_manager.call_deferred("save_game", true)
	else:
		print("[TitleManager] 称号卸下失败")

func _on_arena_titles_loaded(titles: Array):
	if titles.is_empty():
		server_titles_loaded.emit([])
		return
	var server_active: = ""
	for title_data in titles:
		if typeof(title_data) != TYPE_DICTIONARY:
			continue
		var d = {
			"title_id": str(title_data.get("titleId", title_data.get("title_id", ""))), 
			"title_name": title_data.get("titleName", title_data.get("title_name", "")), 
			"attack_bonus": title_data.get("attackBonus", title_data.get("attack_bonus", 0)), 
			"defense_bonus": title_data.get("defenseBonus", title_data.get("defense_bonus", 0)), 
			"agility_bonus": title_data.get("agilityBonus", title_data.get("agility_bonus", 0)), 
			"hp_bonus": title_data.get("hpBonus", title_data.get("hp_bonus", 0)), 
			"source": "arena", 
			"expire_time": title_data.get("expireTime", title_data.get("expire_time", 0)), 
			"week_number": title_data.get("weekNumber", title_data.get("week_number", 0)), 
		}
		if bool(title_data.get("isActive", title_data.get("is_active", false))):
			server_active = d["title_id"]
		var title = TitleDataClass.new()
		title.from_dict(d)
		if _has_title(title.title_id):
			for t in get_all_titles():
				if t is TitleDataClass and t.title_id == title.title_id:
					t.from_dict(d)
					break
		else:
			add_title(title)
	if not server_active.is_empty():
		apply_active_title_id(server_active)
	titles_updated.emit()

func _on_arena_title_activated(data: Dictionary):
	if bool(data.get("success", false)):
		print("[TitleManager] 竞技场称号已激活（与仙魔/帮派称号互斥，由服务端处理）")
		var tid: = str(data.get("titleId", data.get("title_id", "")))
		if not tid.is_empty():
			apply_active_title_id(tid)
		else:
			load_server_titles()
	else:
		print("[TitleManager] 竞技场称号激活失败")

func apply_active_title_id(title_id: String) -> void :
	if title_id.is_empty() or not game_manager or not game_manager.player:
		return
	if game_manager.player.activate_title(title_id):
		active_title_changed.emit(title_id)
		game_manager.call_deferred("save_game", true)

func _has_title(title_id: String) -> bool:
	if not game_manager or not game_manager.player:
		return false
	for title in game_manager.player.titles:
		if title is TitleDataClass and title.title_id == title_id:
			return true
	return false

func load_server_titles():
	if network and network.is_logged_in():
		network.xianmo_get_titles()
		network.arena_get_titles()
		if game_manager and game_manager.gang_manager:
			game_manager.gang_manager.refresh_titles()
	else:
		server_titles_loaded.emit([])

func activate_title_server(title_id: String) -> bool:
	if network and network.is_logged_in():
		var title = _find_title_by_id(title_id)
		if title is TitleDataClass and str(title.source) == "arena":
			network.arena_activate_title(title_id)
			return true
		if title is TitleDataClass and str(title.source) == "gang":
			if game_manager and game_manager.gang_manager and game_manager.gang_manager.gang_network:
				game_manager.gang_manager.gang_network.activate_title(title_id)
			return true
		network.xianmo_activate_title(title_id)
		return true
	return activate_title(title_id)

func deactivate_title_server() -> bool:
	if network and network.is_logged_in():
		network.xianmo_deactivate_title()
		return true
	deactivate_title()
	return true

func _find_title_by_id(title_id: String):
	for title in get_all_titles():
		if title is TitleDataClass and title.title_id == title_id:
			return title
	return null

func add_title(title):
	if not game_manager or not game_manager.player:
		return

	game_manager.player.add_title(title)
	title_added.emit(title)

func remove_title(title_id: String):
	if not game_manager or not game_manager.player:
		return

	var titles = game_manager.player.titles
	for i in range(titles.size()):
		if titles[i] is TitleDataClass and titles[i].title_id == title_id:
			titles.remove_at(i)
			if game_manager.player.active_title_id == title_id:
				game_manager.player.active_title_id = ""
			title_removed.emit(title_id)
			return

func activate_title(title_id: String) -> bool:
	if not game_manager or not game_manager.player:
		return false

	var success = game_manager.player.activate_title(title_id)
	if success:
		active_title_changed.emit(title_id)
	return success

func deactivate_title():
	if not game_manager or not game_manager.player:
		return

	game_manager.player.deactivate_title()
	active_title_changed.emit("")

func get_active_title():
	if not game_manager or not game_manager.player:
		return null
	return game_manager.player.get_active_title()

func get_active_title_name() -> String:
	if not game_manager or not game_manager.player:
		return ""
	return game_manager.player.get_active_title_name()

func get_all_titles() -> Array:
	if not game_manager or not game_manager.player:
		return []
	return game_manager.player.titles

func get_valid_titles() -> Array:
	var result = []
	for title in get_all_titles():
		if title is TitleDataClass and not title.is_expired():
			result.append(title)
	return result

func check_expired_titles():
	if not game_manager or not game_manager.player:
		return

	game_manager.player.remove_expired_titles()
	titles_updated.emit()

func get_title_display_name() -> String:
	var title = get_active_title()
	if title:
		return "[%s] " % title.title_name
	return ""

func get_title_colored_name(player_name: String) -> String:
	var title = get_active_title()
	if title:
		return "[color=#9B30FF][%s][/color] %s" % [title.title_name, player_name]
	return player_name

func get_title_bonus_summary() -> Dictionary:
	var title = get_active_title()
	if not title:
		return {"attack": 0, "defense": 0, "agility": 0, "hp": 0}

	return {
		"attack": title.attack_bonus, 
		"defense": title.defense_bonus, 
		"agility": title.agility_bonus, 
		"hp": title.hp_bonus
	}

func create_xianmo_title(faction: String, rank: int, is_winner: bool, week_num: int):
	return TitleDataClass.create_xianmo_title(faction, rank, is_winner, week_num)
