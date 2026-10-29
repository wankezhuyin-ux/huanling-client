extends Node
class_name XianMoRanking

var xian_rankings: Array = []
var mo_rankings: Array = []
var last_update_time: int = 0
const UPDATE_INTERVAL: int = 300

var game_manager = null
var xianmo_system = null

signal rankings_updated()

func set_managers(gm, xm):
	game_manager = gm
	xianmo_system = xm

func update_rankings(force: bool = false):
	var now = int(Time.get_unix_time_from_system())
	if not force and now - last_update_time < UPDATE_INTERVAL:
		print("[XianMoRanking] update_rankings skipped due to interval")
		return

	print("[XianMoRanking] update_rankings called, force=", force)
	print("[XianMoRanking] game_manager=", game_manager, " network=", game_manager.network if game_manager else "null")

	if game_manager and game_manager.network:
		print("[XianMoRanking] sending ranking requests")
		game_manager.network.xianmo_get_ranking("xian")
		game_manager.network.xianmo_get_ranking("mo")
	else:
		print("[XianMoRanking] ERROR: game_manager or network is null!")

	last_update_time = now

func set_rankings(faction: String, rankings: Array):
	print("[XianMoRanking] set_rankings called: faction=", faction, " count=", rankings.size())
	if faction == "xian":
		xian_rankings = []
		for r in rankings:
			xian_rankings.append({
				"player_id": str(r.get("user_id", "")), 
				"player_name": r.get("nickname", "未知"), 
				"score": r.get("weekly_score", 0), 
				"faction": "xian"
			})
		print("[XianMoRanking] xian_rankings set, count=", xian_rankings.size())
	elif faction == "mo":
		mo_rankings = []
		for r in rankings:
			mo_rankings.append({
				"player_id": str(r.get("user_id", "")), 
				"player_name": r.get("nickname", "未知"), 
				"score": r.get("weekly_score", 0), 
				"faction": "mo"
			})
		print("[XianMoRanking] mo_rankings set, count=", mo_rankings.size())
	rankings_updated.emit()

func get_xian_rankings() -> Array:
	return xian_rankings

func get_mo_rankings() -> Array:
	return mo_rankings

func get_player_rank(player_id: String, faction: String) -> int:
	var rankings = xian_rankings if faction == "xian" else mo_rankings
	for i in range(rankings.size()):
		if rankings[i].player_id == player_id:
			return i + 1
	return -1

func update_player_score(player_id: String, player_name: String, faction: String, score: int):
	var rankings = xian_rankings if faction == "xian" else mo_rankings

	var found = false
	for i in range(rankings.size()):
		if rankings[i].player_id == player_id:
			rankings[i].score = score
			rankings[i].player_name = player_name
			found = true
			break

	if not found:
		rankings.append({
			"player_id": player_id, 
			"player_name": player_name, 
			"score": score, 
			"faction": faction
		})

	rankings.sort_custom( func(a, b): return a.score > b.score)

	if rankings.size() > 100:
		rankings.resize(100)

func get_top_players(faction: String, count: int = 10) -> Array:
	var rankings = xian_rankings if faction == "xian" else mo_rankings
	return rankings.slice(0, min(count, rankings.size()))

func get_faction_total_score(faction: String) -> int:
	if xianmo_system and xianmo_system.global_state:
		if faction == "xian":
			return int(xianmo_system.global_state.xian_total_score)
		else:
			return int(xianmo_system.global_state.mo_total_score)
	return 0

func get_faction_player_count(faction: String) -> int:
	if xianmo_system and xianmo_system.global_state:
		if faction == "xian":
			return int(xianmo_system.global_state.xian_count)
		else:
			return int(xianmo_system.global_state.mo_count)
	return 0

func get_ranking_display_data(faction: String, count: int = 10) -> Array:
	var rankings = get_top_players(faction, count)
	var result = []

	for i in range(rankings.size()):
		var player = rankings[i]
		result.append({
			"rank": i + 1, 
			"name": player.player_name, 
			"score": player.score, 
			"is_self": game_manager and game_manager.player and player.player_id == game_manager.player.player_name
		})

	return result

func get_faction_comparison() -> Dictionary:
	return {
		"xian": {
			"count": get_faction_player_count("xian"), 
			"total_score": get_faction_total_score("xian"), 
			"leading": get_faction_total_score("xian") > get_faction_total_score("mo")
		}, 
		"mo": {
			"count": get_faction_player_count("mo"), 
			"total_score": get_faction_total_score("mo"), 
			"leading": get_faction_total_score("mo") > get_faction_total_score("xian")
		}
	}

func clear_rankings():
	xian_rankings = []
	mo_rankings = []
	last_update_time = 0

func to_dict() -> Dictionary:
	return {
		"xian_rankings": xian_rankings, 
		"mo_rankings": mo_rankings, 
		"last_update_time": last_update_time
	}

func from_dict(data: Dictionary):
	xian_rankings = data.get("xian_rankings", [])
	mo_rankings = data.get("mo_rankings", [])
	last_update_time = data.get("last_update_time", 0)
