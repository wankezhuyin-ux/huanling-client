extends Node

const GameData = preload("res://scripts/game_data.gd")


const MARTIAL_SKILL_BOOK_BROADCAST_POEMS: = [
	"展卷参悟，武道真谛显现，领悟神功！", 
	"熟读精研，心悟玄机，绝技自书中来！", 
	"灵光入简，意贯周天，武学大成！", 
	"翻阅秘籍，感悟天地，绝学现世！", 
	"口诵心会，一卷通神，武功领悟于心！", 
]



signal skill_book_success(data: Dictionary)
signal skill_book_failed(error_msg: String)

func request_use_skill_book(book_name: String) -> void :
	if not GameManager.instance or not GameManager.instance.network:
		skill_book_failed.emit("网络不可用")
		return
	var mgr: MartialArtsManager = GameManager.instance.martial_arts_manager
	if mgr == null:
		skill_book_failed.emit("武功系统未初始化")
		return
	var precheck: Dictionary = mgr.can_learn_from_skill_book()
	if not bool(precheck.get("ok", false)):
		skill_book_failed.emit(str(precheck.get("message", "无法学习")))
		return
	var cfg: Dictionary = GameData.MARTIAL_SKILL_BOOKS.get(book_name, {})
	if cfg.is_empty():
		skill_book_failed.emit("未知人物技能书")
		return
	var network = GameManager.instance.network
	network.martial_skill_book_success.connect(_on_success, CONNECT_ONE_SHOT)
	network.martial_skill_book_failed.connect(_on_failed, CONNECT_ONE_SHOT)
	var operation_id: = "martial_skill_book_%d_%d" % [Time.get_unix_time_from_system(), Time.get_ticks_usec()]
	network.request_martial_skill_book_use(book_name, operation_id)

func _on_success(data: Dictionary) -> void :
	var gm: = GameManager.instance
	if gm == null:
		skill_book_success.emit(data)
		return
	var sd: Variant = data.get("saveData", null)
	if sd is Dictionary and not (sd as Dictionary).is_empty():
		var save_dict: Dictionary = sd as Dictionary
		gm.apply_cloud_save(save_dict, {"authoritative_martial_arts": true})
		gm.align_cloud_save_timestamp_from_player_dict(save_dict.get("playerData", null))
		if gm.martial_arts_manager:
			gm.martial_arts_manager.martial_arts_changed.emit()
		if gm.inventory_manager:
			gm.inventory_manager.inventory_changed.emit()
		gm.refresh_martial_hall_panel_if_open()
	_broadcast_skill_book_success(gm, data)
	skill_book_success.emit(data)

func _broadcast_skill_book_success(gm: GameManager, data: Dictionary) -> void :
	if gm == null or gm.player == null:
		return
	var art_raw: Variant = data.get("art", null)
	if not (art_raw is Dictionary):
		return
	var art_dict: Dictionary = art_raw as Dictionary
	var martial_name: String = str(art_dict.get("name", "一击三伤"))
	var martial_effect: String = str(art_dict.get("effect_type", "triple_shot"))
	var martial_layer: int = int(art_dict.get("layer", data.get("layer", 1)))
	var poem: String = MARTIAL_SKILL_BOOK_BROADCAST_POEMS[randi() % MARTIAL_SKILL_BOOK_BROADCAST_POEMS.size()]
	var announce_msg: = "%s\n恭喜【%s】领悟武功【%s】第%d层！" % [
		poem, gm.player.player_name, martial_name, martial_layer
	]
	gm.broadcast_event(
		"martial_create", 
		gm.player.player_name, 
		{
			"martial_name": martial_name, 
			"effect_type": martial_effect, 
			"layer": martial_layer, 
			"source": "skill_book", 
			"poem": poem, 
		}, 
		announce_msg
	)

func _on_failed(error_msg: String) -> void :
	skill_book_failed.emit(error_msg)
