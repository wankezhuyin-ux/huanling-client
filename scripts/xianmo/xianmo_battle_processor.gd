extends Node
class_name XianMoBattleProcessor

var game_manager = null
var xianmo_system = null
var network = null

var _mirror_data_cache: Dictionary = {}

signal mirror_data_loaded(mirror: Dictionary)

func set_managers(gm, xm):
	game_manager = gm
	xianmo_system = xm

func set_network(net):
	network = net
	if network:
		network.xianmo_mirror_loaded.connect(_on_mirror_data_loaded)

func _on_mirror_data_loaded(mirror: Dictionary):
	if mirror.is_empty():
		print("[XianMoBattle] 镜像数据为空，使用本地生成")
		_use_local_mirror()
	else:
		_mirror_data_cache = mirror
		mirror_data_loaded.emit(mirror)

func _use_local_mirror():
	var player = game_manager.player if game_manager else null
	var player_level = player.level if player else 100
	var level_range = _get_level_range(player_level)
	var enemy_level = randi_range(level_range[0], level_range[1])
	var base_stats = _calculate_base_stats(enemy_level)
	var variance = 0.9 + randf() * 0.2

	_mirror_data_cache = {
		"id": 0, 
		"nickname": _get_random_enemy_name(), 
		"level": enemy_level, 
		"hp": int(base_stats.hp * variance), 
		"attack": int(base_stats.attack * variance), 
		"defense": int(base_stats.defense * variance), 
		"agility": int(base_stats.agility * variance), 
		"element": _get_random_element(), 
		"pet": null
	}
	mirror_data_loaded.emit(_mirror_data_cache)

func request_mirror_data():
	if network and network.is_logged_in():
		network.xianmo_get_mirror()
	else:
		_use_local_mirror()

func get_cached_mirror_data() -> Dictionary:
	return _mirror_data_cache

func clear_mirror_cache():
	_mirror_data_cache = {}

func start_xianmo_battle(battle_type: String, event: Dictionary) -> Dictionary:

	push_warning("[XianMoBattle] start_xianmo_battle 已停用 battle_type=" + battle_type)
	return {
		"success": false, 
		"won": false, 
		"message": "仙魔战斗已改为服务端结算，请使用探险服务端结果", 
		"rewards": [], 
		"legacy_disabled": true, 
		"event_id": str(event.get("event_id", ""))
	}

func _get_level_range(level: int) -> Array:
	if level <= 200:
		return [max(1, level - 20), level + 20]
	elif level <= 400:
		return [201, 400]
	elif level <= 600:
		return [401, 600]
	elif level <= 800:
		return [601, 800]
	elif level <= 1000:
		return [801, 1000]
	elif level <= 1200:
		return [1001, 1200]
	else:
		return [1201, 1500]

func _calculate_base_stats(level: int) -> Dictionary:
	var base_hp = 100 + level * 50
	var base_attack = 10 + level * 5
	var base_defense = 5 + level * 3
	var base_agility = 5 + level * 2

	return {
		"hp": base_hp, 
		"attack": base_attack, 
		"defense": base_defense, 
		"agility": base_agility
	}

func _get_random_enemy_name() -> String:
	var names = [
		"剑修", "符师", "阵法师", "丹师", "体修", 
		"剑仙", "刀客", "拳师", "气修", "魂修", 
		"青云子", "玄真子", "无尘子", "明月子", "清风子"
	]
	return names[randi() % names.size()]

func _get_random_element() -> String:
	var elements = ["金", "木", "水", "火", "土"]
	return elements[randi() % elements.size()]
