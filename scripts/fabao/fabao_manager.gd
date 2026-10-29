extends Node
class_name FabaoManager

const FabaoConfigRef = preload("res://scripts/fabao/fabao_config.gd")

signal fabao_changed
signal difficulty_changed(tier_id: String)
signal request_failed(msg: String)
signal reroll_preview(pending: Dictionary)
signal reroll_confirm_done(accepted: bool)
signal reset_preview(pending: Dictionary)
signal reset_confirm_done(accepted: bool)
signal synthesize_done(inst: Dictionary)
signal dismantle_done(msg: String)
signal affix_lock_done(fabao_id: String, locked: bool, group: String)

var current_difficulty: String = "normal"
var equipped_fabao = null
var fabao_inventory: Array = []
var fabao_warehouse: Array = []
var pending_reroll: Dictionary = {}
var pending_reset: Dictionary = {}
var _http: HTTPRequest
var _busy: = false
var _pending_diff_tier: String = ""
var _pending_kind: = ""
var _pending_confirm_apply: = false
var _pending_lock_fabao_id: = ""
var _pending_lock_group: = ""
var _pending_lock_want: = false


func _ready() -> void :
	_http = HTTPRequest.new()
	_http.timeout = 20
	add_child(_http)
	_http.request_completed.connect(_on_http_done)


func to_dict() -> Dictionary:
	return {
		"current_difficulty": current_difficulty, 
		"equipped": equipped_fabao, 
		"inventory": fabao_inventory.duplicate(true), 
		"warehouse": fabao_warehouse.duplicate(true), 
	}


func from_dict(data) -> void :
	if data == null or not (data is Dictionary):
		return
	var d: Dictionary = data
	if d.has("current_difficulty") or d.has("tier"):
		current_difficulty = FabaoConfigRef.normalize_map_tier(str(d.get("current_difficulty", d.get("tier", "normal"))))
		difficulty_changed.emit(current_difficulty)
	equipped_fabao = d.get("equipped", d.get("equipped_fabao", null))
	if equipped_fabao != null and not (equipped_fabao is Dictionary):
		equipped_fabao = null
	var inv = d.get("inventory", d.get("fabao_inventory", []))
	fabao_inventory = inv.duplicate(true) if inv is Array else []
	var wh = d.get("warehouse", d.get("fabao_warehouse", []))
	fabao_warehouse = wh.duplicate(true) if wh is Array else []
	fabao_changed.emit()


func apply_from_game_settings(settings: Dictionary) -> void :
	if settings.has("fabaoData") and settings.get("fabaoData") is Dictionary:
		from_dict(settings.get("fabaoData"))
	elif settings.has("fabao_data") and settings.get("fabao_data") is Dictionary:
		from_dict(settings.get("fabao_data"))
	if settings.has("current_map_difficulty"):
		current_difficulty = FabaoConfigRef.normalize_map_tier(str(settings.get("current_map_difficulty", "normal")))
		difficulty_changed.emit(current_difficulty)
	var pending: Variant = settings.get("pending_fabao_reroll", {})
	if pending is Dictionary and not (pending as Dictionary).is_empty():
		pending_reroll = (pending as Dictionary).duplicate(true)
	else:
		pending_reroll = {}
	var pending_r: Variant = settings.get("pending_fabao_reset", {})
	if pending_r is Dictionary and not (pending_r as Dictionary).is_empty():
		pending_reset = (pending_r as Dictionary).duplicate(true)
	else:
		pending_reset = {}


func reincarnation() -> int:
	if GameManager.instance and GameManager.instance.player:
		return int(GameManager.instance.player.reincarnation)
	return 0


func map_difficulty_for_upload() -> String:
	if not _pending_diff_tier.is_empty():
		return ""
	return current_difficulty


func request_set_difficulty(tier_id: String) -> void :
	var want: = FabaoConfigRef.normalize_map_tier(tier_id)
	if not FabaoConfigRef.is_map_tier(want):
		request_failed.emit("无效的地图难度")
		difficulty_changed.emit(current_difficulty)
		return
	if not FabaoConfigRef.is_tier_unlocked(want, reincarnation()):
		request_failed.emit(FabaoConfigRef.unlock_hint(want))
		difficulty_changed.emit(current_difficulty)
		return
	if _busy:
		request_failed.emit("操作繁忙，请稍后再试")
		difficulty_changed.emit(current_difficulty)
		return
	var gm = GameManager.instance
	_pending_diff_tier = want
	if gm == null or gm.network == null or not gm.network.is_logged_in():
		current_difficulty = want
		difficulty_changed.emit(want)
		_pending_diff_tier = ""
		if gm:
			gm.save_game(false)
		return
	_post("/fabao/set-difficulty", {"tier": want, "operationId": _op("diff")}, "set_diff")


func request_synthesize(tier_id: String) -> void :
	_post("/fabao/synthesize", {"tier": FabaoConfigRef.normalize_tier(tier_id), "operationId": _op("syn")}, "synthesize")


func request_equip(fabao_id: String) -> void :
	_post("/fabao/equip", {"fabaoId": fabao_id, "operationId": _op("eq")}, "equip")


func request_unequip() -> void :
	_post("/fabao/unequip", {"operationId": _op("uneq")}, "unequip")


func request_store_warehouse(fabao_id: String) -> void :
	_post("/fabao/store-warehouse", {"fabaoId": fabao_id, "operationId": _op("stwh")}, "store_wh")


func request_retrieve_warehouse(fabao_id: String) -> void :
	_post("/fabao/retrieve-warehouse", {"fabaoId": fabao_id, "operationId": _op("rtwh")}, "retrieve_wh")


func request_discard(fabao_id: String) -> void :
	_post("/fabao/discard", {"fabaoId": fabao_id, "operationId": _op("disc")}, "discard")


func request_dismantle(fabao_id: String) -> void :
	_post("/fabao/dismantle", {"fabaoId": fabao_id, "operationId": _op("dism")}, "dismantle")


func request_reroll(fabao_id: String) -> void :
	_post("/fabao/reroll", {"fabaoId": fabao_id, "operationId": _op("reroll")}, "reroll")


func request_reroll_confirm(token: String, apply: bool) -> void :
	_pending_confirm_apply = apply
	_post("/fabao/reroll/confirm", {"token": token, "apply": apply, "operationId": _op("rrcf")}, "reroll_confirm")


func request_reset(fabao_id: String) -> void :
	_post("/fabao/reset", {"fabaoId": fabao_id, "operationId": _op("reset")}, "reset")


func request_reset_confirm(token: String, apply: bool) -> void :
	_pending_confirm_apply = apply
	_post("/fabao/reset/confirm", {"token": token, "apply": apply, "operationId": _op("rscf")}, "reset_confirm")


func request_lock_affix(fabao_id: String, group: String) -> void :
	_pending_lock_fabao_id = fabao_id.strip_edges()
	_pending_lock_group = group.strip_edges()
	_pending_lock_want = true
	_post("/fabao/affix/lock", {"fabaoId": _pending_lock_fabao_id, "group": _pending_lock_group, "operationId": _op("lkaf")}, "affix_lock")


func request_unlock_affix(fabao_id: String, group: String) -> void :
	_pending_lock_fabao_id = fabao_id.strip_edges()
	_pending_lock_group = group.strip_edges()
	_pending_lock_want = false
	_post("/fabao/affix/unlock", {"fabaoId": _pending_lock_fabao_id, "group": _pending_lock_group, "operationId": _op("ulaf")}, "affix_unlock")


func _op(kind: String) -> String:
	return "fabao_%s_%d_%d" % [kind, Time.get_unix_time_from_system(), randi()]


func _apply_authoritative_yuanbao(save_data: Dictionary) -> void :
	var pd: Variant = save_data.get("playerData", {})
	if not (pd is Dictionary):
		return
	if not (pd as Dictionary).has("yuanbao_currency"):
		return
	var gm = GameManager.instance
	if gm == null or gm.player == null:
		return
	gm.player.yuanbao_currency = maxi(0, int((pd as Dictionary).get("yuanbao_currency", 0)))
	gm.yuanbao_changed.emit(gm.player.yuanbao_currency)


func _post(path: String, body: Dictionary, kind: String) -> void :
	if _busy:
		if kind == "set_diff":
			_pending_diff_tier = ""
			difficulty_changed.emit(current_difficulty)
		request_failed.emit("操作繁忙，请稍后再试")
		return
	var gm = GameManager.instance
	if gm == null or gm.network == null or not gm.network.is_logged_in():
		if kind == "set_diff":
			_pending_diff_tier = ""
			difficulty_changed.emit(current_difficulty)
		request_failed.emit("未登录")
		return
	var net = gm.network
	var headers = PackedStringArray([
		"Content-Type: application/json", 
		"Authorization: Bearer " + str(net.auth_token), 
		"X-Client-Version: " + str(net.client_version_header), 
	])
	_busy = true
	_pending_kind = kind
	var err: = _http.request(str(net.server_url) + path, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_busy = false
		_pending_kind = ""
		if kind == "set_diff":
			_pending_diff_tier = ""
			difficulty_changed.emit(current_difficulty)
		request_failed.emit("网络请求失败")


func _on_http_done(_result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void :
	_busy = false
	var kind: = _pending_kind
	_pending_kind = ""
	var text: = body.get_string_from_utf8()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY and code == 409 and bool((parsed as Dictionary).get("needsConfirm", false)):
		var data409: Dictionary = parsed
		if data409.has("saveData") and data409.get("saveData") is Dictionary:
			var gm409 = GameManager.instance
			if gm409:
				gm409.apply_cloud_save(data409.get("saveData"), {
					"skip_deferred_cloud_save": true, 
					"skip_title_gang_refresh": true, 
					"reconcile_treasure_chests": false, 
				})
		var p409: Variant = data409.get("pending", {})
		if p409 is Dictionary and not (p409 as Dictionary).is_empty():
			_apply_pending_preview(p409 as Dictionary)
		else:
			request_failed.emit(str(data409.get("error", "请先处理上次法宝结果")))
		if kind == "set_diff":
			_pending_diff_tier = ""
			difficulty_changed.emit(current_difficulty)
		return
	if code < 200 or code >= 300 or typeof(parsed) != TYPE_DICTIONARY:
		var err: = "操作失败"
		if typeof(parsed) == TYPE_DICTIONARY:
			err = str(parsed.get("error", parsed.get("message", err)))
		if kind == "set_diff":
			_pending_diff_tier = ""
			difficulty_changed.emit(current_difficulty)
		request_failed.emit(err)
		return
	var data: Dictionary = parsed
	if not bool(data.get("success", false)) and not data.has("saveData"):
		if kind == "set_diff":
			_pending_diff_tier = ""
			difficulty_changed.emit(current_difficulty)
		request_failed.emit(str(data.get("error", data.get("message", "操作失败"))))
		return
	if data.has("saveData") and data.get("saveData") is Dictionary:
		var gm = GameManager.instance
		if gm:
			gm.apply_cloud_save(data.get("saveData"), {
				"skip_deferred_cloud_save": true, 
				"skip_title_gang_refresh": true, 
				"reconcile_treasure_chests": false, 
			})
		if kind == "affix_lock" or kind == "affix_unlock":
			_apply_authoritative_yuanbao(data.get("saveData"))
	if data.has("fabaoData") and data.get("fabaoData") is Dictionary:
		from_dict(data.get("fabaoData"))
	if data.has("current_map_difficulty"):
		current_difficulty = FabaoConfigRef.normalize_map_tier(str(data.get("current_map_difficulty")))
		difficulty_changed.emit(current_difficulty)
	elif kind == "set_diff" and not _pending_diff_tier.is_empty():
		current_difficulty = FabaoConfigRef.normalize_map_tier(_pending_diff_tier)
		difficulty_changed.emit(current_difficulty)
	if kind == "set_diff":
		_pending_diff_tier = ""
	if bool(data.get("needsConfirm", false)):
		var p: Variant = data.get("pending", {})
		if p is Dictionary and not (p as Dictionary).is_empty():
			_apply_pending_preview(p as Dictionary)
		elif data.has("saveData") and data.get("saveData") is Dictionary:
			var gs: Variant = (data.get("saveData") as Dictionary).get("gameSettings", {})
			if gs is Dictionary:
				var pp: Variant = (gs as Dictionary).get("pending_fabao_reroll", {})
				if pp is Dictionary and not (pp as Dictionary).is_empty():
					_apply_pending_preview(pp as Dictionary)
				else:
					var pr: Variant = (gs as Dictionary).get("pending_fabao_reset", {})
					if pr is Dictionary and not (pr as Dictionary).is_empty():
						_apply_pending_preview(pr as Dictionary)
	elif kind == "reroll_confirm":
		pending_reroll = {}
	elif kind == "reset_confirm":
		pending_reset = {}
	if kind == "synthesize":
		var made: Variant = data.get("fabao", data.get("instance", {}))
		if ( not (made is Dictionary) or (made as Dictionary).is_empty()) and not bool(data.get("duplicate", false)):
			if fabao_inventory.size() > 0 and fabao_inventory[fabao_inventory.size() - 1] is Dictionary:
				made = fabao_inventory[fabao_inventory.size() - 1]
		if made is Dictionary and not (made as Dictionary).is_empty():
			synthesize_done.emit((made as Dictionary).duplicate(true))
		else:
			synthesize_done.emit({})
	if kind == "dismantle":
		dismantle_done.emit(str(data.get("message", "分解成功")))
	if kind == "affix_lock" or kind == "affix_unlock":
		var gid: = str(data.get("group", _pending_lock_group))
		var fid: = _pending_lock_fabao_id
		var locked: = bool(data.get("locked", _pending_lock_want))
		_pending_lock_fabao_id = ""
		_pending_lock_group = ""
		affix_lock_done.emit(fid, locked, gid)
	fabao_changed.emit()
	if kind == "reroll_confirm":
		reroll_confirm_done.emit(_pending_confirm_apply)
	if kind == "reset_confirm":
		reset_confirm_done.emit(_pending_confirm_apply)
	if kind == "set_diff" and GameManager.instance:
		GameManager.instance.save_game(false)


func _apply_pending_preview(pending: Dictionary) -> void :
	var kind: = str(pending.get("kind", "")).strip_edges()
	if kind.is_empty() and pending.has("previewAffixes"):
		kind = "reroll"
	if kind == "reset":
		pending_reset = pending.duplicate(true)
		reset_preview.emit(pending_reset)
	else:
		pending_reroll = pending.duplicate(true)
		reroll_preview.emit(pending_reroll)
