class_name WorldBossClient
extends RefCounted

static func fetch_status(game_manager) -> Dictionary:
	if game_manager == null or game_manager.network == null:
		return {"ok": false, "error": "网络未就绪"}
	var net = game_manager.network
	if not net.has_method("request_world_boss_status"):
		return {"ok": false, "error": "接口未实现"}
	return await net.request_world_boss_status()

static func fetch_ranking(game_manager, limit: int = 100) -> Dictionary:
	if game_manager == null or game_manager.network == null:
		return {"ok": false, "error": "网络未就绪"}
	var net = game_manager.network
	if not net.has_method("request_world_boss_ranking"):
		return {"ok": false, "error": "接口未实现"}
	return await net.request_world_boss_ranking(limit)

static func request_battle_start(game_manager) -> Dictionary:
	if game_manager == null or game_manager.network == null:
		return {"ok": false, "error": "网络未就绪"}
	var net = game_manager.network
	if not net.has_method("request_world_boss_battle_start"):
		return {"ok": false, "error": "接口未实现"}
	return await net.request_world_boss_battle_start()

static func report_battle_result(game_manager, battle_token: String, damage: int, pet_snapshot: Dictionary) -> Dictionary:
	if game_manager == null or game_manager.network == null:
		return {"ok": false, "error": "网络未就绪"}
	var net = game_manager.network
	if not net.has_method("request_world_boss_battle_report"):
		return {"ok": false, "error": "接口未实现"}
	return await net.request_world_boss_battle_report(battle_token, damage, pet_snapshot)
