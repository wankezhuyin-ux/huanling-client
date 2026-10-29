extends Node
class_name GangNetwork

signal request_finished(action: String, success: bool, data: Dictionary)

var _http: HTTPRequest
var _mirror_http: HTTPRequest
var _pending_action: String = ""
var _game_manager = null
var _request_queue: Array = []
var _request_busy: = false

const MIRROR_HTTP_TIMEOUT_SEC: = 45.0

func setup(game_manager) -> void :
	_game_manager = game_manager
	if _http == null:
		_http = HTTPRequest.new()
		add_child(_http)
		_http.request_completed.connect(_on_request_completed)
	if _mirror_http == null:
		_mirror_http = HTTPRequest.new()
		_mirror_http.name = "GangMirrorHttp"
		_mirror_http.timeout = MIRROR_HTTP_TIMEOUT_SEC
		add_child(_mirror_http)

func _headers() -> PackedStringArray:
	var headers: PackedStringArray = ["Content-Type: application/json"]
	if _game_manager and _game_manager.network and _game_manager.network.has_method("get_auth_token"):
		var token: = str(_game_manager.network.get_auth_token()).strip_edges()
		if not token.is_empty():
			headers.append("Authorization: Bearer %s" % token)
	if _game_manager and _game_manager.network:
		headers.append("X-Client-Version: " + str(_game_manager.network.client_version_header))
	return headers

func _root_url() -> String:
	if _game_manager and _game_manager.network:
		return str(_game_manager.network.server_url).strip_edges().trim_suffix("/")
	return ""

func _new_operation_id() -> String:
	return "%d_%d" % [Time.get_ticks_msec(), randi()]

func _enqueue_request(path: String, action: String, method: int, body: String = "") -> void :
	_request_queue.append({
		"path": path, 
		"action": action, 
		"method": method, 
		"body": body, 
	})
	_process_request_queue()

func _process_request_queue() -> void :
	if _request_busy or _request_queue.is_empty() or _http == null:
		return
	var job: Dictionary = _request_queue.pop_front()
	var url: = _root_url() + str(job.get("path", ""))
	var action: = str(job.get("action", ""))
	var method: int = int(job.get("method", HTTPClient.METHOD_GET))
	var body: = str(job.get("body", ""))
	_pending_action = action
	_request_busy = true
	var err: = OK
	if method == HTTPClient.METHOD_POST:
		err = _http.request(url, _headers(), method, body)
	else:
		err = _http.request(url, _headers(), method)
	if err != OK:
		_request_busy = false
		_pending_action = ""
		request_finished.emit(action, false, {"error": "网络请求失败"})
		call_deferred("_process_request_queue")

func request_get(path: String, action: String) -> void :
	_enqueue_request(path, action, HTTPClient.METHOD_GET)

func request_post(path: String, action: String, body: Dictionary) -> void :
	var payload: = JSON.stringify(body)
	_enqueue_request(path, action, HTTPClient.METHOD_POST, payload)

func fetch_overview() -> void :
	request_get("/gang/overview", "overview")

func fetch_list() -> void :
	request_get("/gang/list", "list")

func fetch_other_gangs() -> void :
	request_get("/gang/list?limit=100", "other_gangs")

func fetch_kick_active() -> void :
	request_get("/gang/kick/active", "kick_active")

func fetch_kick_defending() -> void :
	request_get("/gang/kick/defending", "kick_defending")

func fetch_kick_history(limit: int = 30) -> void :
	request_get("/gang/kick/history?limit=%d" % clampi(limit, 1, 50), "kick_history")

func fetch_siege_history(limit: int = 30) -> void :
	request_get("/gang/siege/history?limit=%d" % clampi(limit, 1, 50), "siege_history")

func fetch_gang_mirror() -> void :
	request_get("/gang/mirror", "gang_mirror_get")

func update_gang_mirror() -> void :
	request_post("/gang/mirror/update", "gang_mirror_update", {"operationId": _new_operation_id()})

func fetch_gang_mirror_await() -> Dictionary:
	return await _mirror_http_request(HTTPClient.METHOD_GET, "/gang/mirror", "")

func update_gang_mirror_await() -> Dictionary:
	var body: = JSON.stringify({"operationId": _new_operation_id()})
	return await _mirror_http_request(HTTPClient.METHOD_POST, "/gang/mirror/update", body)

func _mirror_http_request(method: int, path: String, body: String) -> Dictionary:
	if _mirror_http == null:
		return {"success": false, "error": "网络未初始化"}
	if _root_url().is_empty():
		return {"success": false, "error": "未登录"}
	var url: = _root_url() + path
	var err: = OK
	if method == HTTPClient.METHOD_POST:
		err = _mirror_http.request(url, _headers(), method, body)
	else:
		err = _mirror_http.request(url, _headers(), method)
	if err != OK:
		return {"success": false, "error": "网络请求失败"}
	var completed: Array = await _mirror_http.request_completed
	var result: int = int(completed[0])
	var response_code: int = int(completed[1])
	var response_body: PackedByteArray = completed[3]
	var data: Dictionary = {}
	if response_body.size() > 0:
		var parsed = JSON.parse_string(response_body.get_string_from_utf8())
		if parsed is Dictionary:
			data = parsed
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		if not data.has("error"):
			data["error"] = "请求失败(%d)" % response_code
		data["success"] = false
		return data
	data["success"] = true
	return data

func kick_repair(session_id: int) -> void :
	request_post("/gang/kick/repair", "kick_repair", {"sessionId": session_id, "operationId": _new_operation_id()})

func kick_buy_attack_contribution(session_id: int) -> void :
	request_post("/gang/kick/buy-attack-contribution", "kick_buy_attack_contribution", {
		"sessionId": session_id, 
		"operationId": _new_operation_id(), 
	})

func kick_buy_attack(session_id: int) -> void :
	request_post("/gang/kick/buy-attack", "kick_buy_attack", {
		"sessionId": session_id, 
		"operationId": _new_operation_id(), 
	})

func kick_buy_defense(session_id: int) -> void :
	request_post("/gang/kick/buy-defense", "kick_buy_defense", {
		"sessionId": session_id, 
		"operationId": _new_operation_id(), 
	})

func fetch_members() -> void :
	request_get("/gang/members", "members")

func fetch_shop() -> void :
	request_get("/gang/shop", "shop")

func fetch_buffs() -> void :
	request_get("/gang/buffs", "buffs")

func fetch_territories() -> void :
	request_get("/gang/territories", "territories")

func fetch_war_reports() -> void :
	request_get("/gang/war/reports", "war_reports")

func fetch_siege_status() -> void :
	request_get("/gang/siege/status", "siege_status")

func siege_apply(territory_id: String, bid_amount: int, round_no: int = 0, siege_buff_id: String = "") -> void :
	var body: = {
		"territoryId": territory_id, 
		"bidAmount": bid_amount, 
		"operationId": _new_operation_id(), 
	}
	if round_no > 0:
		body["roundNo"] = round_no
	if not siege_buff_id.is_empty():
		body["siegeBuffId"] = siege_buff_id
	request_post("/gang/siege/apply", "siege_apply", body)

func siege_bid(territory_id: String, bid_amount: int, round_no: int = 0) -> void :
	var body: = {"territoryId": territory_id, "bidAmount": bid_amount}
	if round_no > 0:
		body["roundNo"] = round_no
	request_post("/gang/siege/bid", "siege_bid", body)

func siege_forfeit(territory_id: String, round_no: int = 0) -> void :
	var body: = {"territoryId": territory_id}
	if round_no > 0:
		body["roundNo"] = round_no
	request_post("/gang/siege/forfeit", "siege_forfeit", body)

func territory_abandon(territory_id: String) -> void :
	request_post("/gang/territory/abandon", "territory_abandon", {"territoryId": territory_id})

func fetch_siege_guards(territory_id: String) -> void :
	request_get("/gang/siege/guards?territoryId=%s" % territory_id.uri_encode(), "siege_guards")

func siege_set_guard(territory_id: String, mirror_user_id: int) -> void :
	request_post("/gang/siege/guards", "siege_guard_set", {
		"territoryId": territory_id, 
		"mirrorUserId": mirror_user_id, 
		"operationId": _new_operation_id(), 
	})

func siege_clear_guard(territory_id: String) -> void :
	request_post("/gang/siege/guards/clear", "siege_guard_clear", {"territoryId": territory_id})

func siege_guard_join(territory_id: String) -> void :
	request_post("/gang/siege/guards/join", "siege_guard_join", {
		"territoryId": territory_id, 
		"operationId": _new_operation_id(), 
	})

func fetch_territory_claim_status() -> void :
	request_get("/gang/territory/claim-status", "territory_claim_status")

func claim_territory_daily_all() -> void :
	request_post("/gang/territory/claim-daily-all", "territory_claim_daily_all", {
		"operationId": _new_operation_id(), 
	})

func update_settings(notice: String, auto_join: bool) -> void :
	request_post("/gang/settings", "gang_settings", {"notice": notice, "autoJoin": auto_join})

func siege_attack(round_id: int) -> void :
	if _game_manager and _game_manager.gang_manager:
		_game_manager.gang_manager.note_siege_attack_round(round_id)
	request_post("/gang/siege/attack", "siege_attack", {"roundId": round_id, "operationId": _new_operation_id()})

func siege_buy_attack_contribution(round_id: int) -> void :
	request_post("/gang/siege/buy-attack-contribution", "siege_buy_attack_contribution", {
		"roundId": round_id, 
		"operationId": _new_operation_id(), 
	})

func siege_buy_attack(round_id: int) -> void :
	request_post("/gang/siege/buy-attack", "siege_buy_attack", {
		"roundId": round_id, 
		"operationId": _new_operation_id(), 
	})

func siege_repair(round_id: int) -> void :
	request_post("/gang/siege/repair", "siege_repair", {"roundId": round_id, "operationId": _new_operation_id()})

func siege_buy_defense(round_id: int) -> void :
	request_post("/gang/siege/buy-defense", "siege_buy_defense", {
		"roundId": round_id, 
		"operationId": _new_operation_id(), 
	})

func fetch_ranking() -> void :
	request_get("/gang/ranking", "ranking")

func fetch_titles() -> void :
	request_get("/gang/titles", "titles")

func activate_title(title_id: String) -> void :
	request_post("/gang/titles/activate", "title_activate", {"titleId": title_id})

func create_gang(name: String, emblem_id: int, notice: String) -> void :
	request_post("/gang/create", "create", {
		"name": name, "emblemId": emblem_id, "notice": notice, "operationId": _new_operation_id()
	})

func apply_gang(gang_id: int) -> void :
	request_post("/gang/apply", "apply", {"gangId": gang_id})

func approve_application(application_id: int, approve: bool) -> void :
	request_post("/gang/approve", "approve", {"applicationId": application_id, "approve": approve})

func leave_gang() -> void :
	request_post("/gang/leave", "leave", {})

func donate(donate_type: String) -> void :
	request_post("/gang/donate", "donate", {"type": donate_type, "operationId": _new_operation_id()})

func upgrade_gang() -> void :
	request_post("/gang/upgrade", "upgrade", {"operationId": _new_operation_id()})

func kick_member(target_user_id: int) -> void :
	request_post("/gang/kick", "kick", {"targetUserId": target_user_id})

func set_member_role(target_user_id: int, role: int) -> void :
	request_post("/gang/set-role", "set_role", {"targetUserId": target_user_id, "role": role})

func transfer_leadership(target_user_id: int) -> void :
	request_post("/gang/transfer", "transfer", {"targetUserId": target_user_id})

func buy_shop_item(shop_item_id: String) -> void :
	request_post("/gang/shop/buy", "shop_buy", {"shopItemId": shop_item_id, "operationId": _new_operation_id()})

func kick_start(target_gang_id: int) -> void :
	request_post("/gang/kick/start", "kick_start", {"targetGangId": target_gang_id, "operationId": _new_operation_id()})

func kick_attack(session_id: int) -> void :
	request_post("/gang/kick/attack", "kick_attack", {"sessionId": session_id, "operationId": _new_operation_id()})

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void :
	var action: = _pending_action
	_pending_action = ""
	_request_busy = false
	var data: Dictionary = {}
	if body.size() > 0:
		var txt: = body.get_string_from_utf8()
		var parsed = JSON.parse_string(txt)
		if parsed is Dictionary:
			data = parsed
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		if not data.has("error"):
			data["error"] = "请求失败(%d)" % response_code
		request_finished.emit(action, false, data)
		call_deferred("_process_request_queue")
		return
	if _game_manager and _game_manager.network:
		_game_manager.network._update_server_time_from_response_data(data)
	request_finished.emit(action, true, data)
	call_deferred("_process_request_queue")
