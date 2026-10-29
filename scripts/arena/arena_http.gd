class_name ArenaHttp
extends Node



signal status_loaded(data: Dictionary)
signal ranking_loaded(data: Dictionary)
signal mirror_updated(data: Dictionary)
signal match_started(data: Dictionary)
signal challenge_started(data: Dictionary)
signal challenge_confirmed(data: Dictionary)
signal challenge_history_loaded(data: Dictionary)
signal shop_items_loaded(data: Dictionary)
signal shop_bought(data: Dictionary)
signal titles_loaded(data: Dictionary)
signal title_activated(data: Dictionary)
signal arena_request_failed(channel: String, error: String)

const HTTP_TIMEOUT_SEC: float = 45.0
const MAX_DEFER_ATTEMPTS: int = 45
const WALL_CLOCK_EXTRA_MS: int = 35000

var _network: Node = null

var _status_http: HTTPRequest
var _ranking_http: HTTPRequest
var _mirror_http: HTTPRequest
var _match_http: HTTPRequest
var _challenge_http: HTTPRequest
var _confirm_http: HTTPRequest
var _history_http: HTTPRequest
var _shop_http: HTTPRequest
var _titles_http: HTTPRequest

var _status_watchdog: Timer
var _ranking_watchdog: Timer
var _mirror_watchdog: Timer
var _match_watchdog: Timer
var _challenge_watchdog: Timer
var _confirm_watchdog: Timer
var _history_watchdog: Timer
var _shop_watchdog: Timer
var _titles_watchdog: Timer
var _await_timer: Timer

var _status_waiters: Array = []
var _ranking_waiters: Array = []
var _mirror_waiters: Array = []
var _match_waiters: Array = []
var _challenge_waiters: Array = []
var _confirm_waiters: Array = []
var _history_waiters: Array = []
var _shop_waiters: Array = []
var _titles_waiters: Array = []

var _status_defer_attempts: int = 0
var _ranking_defer_attempts: int = 0
var _mirror_defer_attempts: int = 0
var _match_defer_attempts: int = 0
var _challenge_defer_attempts: int = 0
var _confirm_defer_attempts: int = 0
var _history_defer_attempts: int = 0
var _shop_defer_attempts: int = 0
var _titles_defer_attempts: int = 0

var _status_in_flight: bool = false
var _ranking_in_flight: bool = false
var _mirror_in_flight: bool = false
var _match_in_flight: bool = false
var _challenge_in_flight: bool = false
var _confirm_in_flight: bool = false
var _history_in_flight: bool = false
var _shop_in_flight: bool = false
var _titles_in_flight: bool = false


func setup(network: Node) -> void :
	_network = network
	process_mode = Node.PROCESS_MODE_ALWAYS
	_status_http = _make_http("status")
	_ranking_http = _make_http("ranking")
	_mirror_http = _make_http("mirror")
	_match_http = _make_http("match")
	_challenge_http = _make_http("challenge")
	_confirm_http = _make_http("confirm")
	_history_http = _make_http("history")
	_shop_http = _make_http("shop")
	_titles_http = _make_http("titles")
	_status_http.request_completed.connect( func(r, c, h, b): _on_channel_completed("status", r, c, h, b))
	_ranking_http.request_completed.connect( func(r, c, h, b): _on_channel_completed("ranking", r, c, h, b))
	_mirror_http.request_completed.connect( func(r, c, h, b): _on_channel_completed("mirror", r, c, h, b))
	_match_http.request_completed.connect( func(r, c, h, b): _on_channel_completed("match", r, c, h, b))
	_challenge_http.request_completed.connect( func(r, c, h, b): _on_channel_completed("challenge", r, c, h, b))
	_confirm_http.request_completed.connect( func(r, c, h, b): _on_channel_completed("confirm", r, c, h, b))
	_history_http.request_completed.connect( func(r, c, h, b): _on_channel_completed("history", r, c, h, b))
	_shop_http.request_completed.connect( func(r, c, h, b): _on_channel_completed("shop", r, c, h, b))
	_titles_http.request_completed.connect( func(r, c, h, b): _on_channel_completed("titles", r, c, h, b))
	_status_watchdog = _make_watchdog(_status_http, "status")
	_ranking_watchdog = _make_watchdog(_ranking_http, "ranking")
	_mirror_watchdog = _make_watchdog(_mirror_http, "mirror")
	_match_watchdog = _make_watchdog(_match_http, "match")
	_challenge_watchdog = _make_watchdog(_challenge_http, "challenge")
	_confirm_watchdog = _make_watchdog(_confirm_http, "confirm")
	_history_watchdog = _make_watchdog(_history_http, "history")
	_shop_watchdog = _make_watchdog(_shop_http, "shop")
	_titles_watchdog = _make_watchdog(_titles_http, "titles")
	_await_timer = Timer.new()
	_await_timer.name = "ArenaAwaitTimer"
	_await_timer.one_shot = true
	_await_timer.wait_time = 0.05
	_await_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_await_timer)


func prepare_channels() -> void :
	for ch in ["status", "ranking", "mirror", "match", "challenge", "confirm", "history", "shop", "titles"]:
		_cancel_channel_http(ch)
		_set_defer_attempts(ch, 0)
		_fail_waiters(_get_waiters(ch), "请求已取消")
		_get_waiters(ch).clear()
		_set_in_flight(ch, false)


func fetch_status() -> Dictionary:
	return await _enqueue_and_wait("status", HTTPClient.METHOD_GET, "/arena/status", "")


func fetch_ranking(limit: int = 100) -> Dictionary:
	var lim: = maxi(1, limit)
	return await _enqueue_and_wait("ranking", HTTPClient.METHOD_GET, "/arena/ranking?limit=%d" % lim, "")


func fetch_mirror() -> Dictionary:
	return await _enqueue_and_wait("mirror", HTTPClient.METHOD_GET, "/arena/mirror", "")


func update_mirror() -> Dictionary:
	return await _enqueue_and_wait("mirror", HTTPClient.METHOD_POST, "/arena/mirror/update", "{}")


func start_match() -> Dictionary:
	return await _enqueue_and_wait("match", HTTPClient.METHOD_POST, "/arena/match/start", "{}")


func start_challenge(battle_token: String) -> Dictionary:
	var body: = JSON.stringify({"battleToken": battle_token})
	return await _enqueue_and_wait("challenge", HTTPClient.METHOD_POST, "/arena/challenge/start", body)


func confirm_challenge(battle_token: String, operation_id: String = "") -> Dictionary:
	var op: = operation_id.strip_edges()
	if op.is_empty():
		op = battle_token
	var body: = JSON.stringify({"battleToken": battle_token, "operationId": op})
	return await _enqueue_and_wait("confirm", HTTPClient.METHOD_POST, "/arena/challenge/confirm", body)


func fetch_challenge_history(limit: int = 20) -> Dictionary:
	var lim: = maxi(1, mini(30, limit))
	return await _enqueue_and_wait("history", HTTPClient.METHOD_GET, "/arena/challenge/history?limit=%d" % lim, "")


func fetch_shop_items() -> Dictionary:
	return await _enqueue_and_wait("shop", HTTPClient.METHOD_GET, "/arena/shop/items", "")


func buy_shop_item(item_id: String, operation_id: String = "", quantity: int = 1) -> Dictionary:
	var op: = operation_id.strip_edges()
	if op.is_empty():
		op = "arena_shop_%s_%d" % [item_id, Time.get_unix_time_from_system()]
	var qty: = clampi(quantity, 1, 999)
	var body: = JSON.stringify({"itemId": item_id, "operationId": op, "quantity": qty})
	return await _enqueue_and_wait("shop", HTTPClient.METHOD_POST, "/arena/shop/buy", body)


func fetch_titles() -> Dictionary:
	return await _enqueue_and_wait("titles", HTTPClient.METHOD_GET, "/arena/titles", "")


func activate_title(title_id: Variant) -> Dictionary:
	var body: = JSON.stringify({"titleId": str(title_id)})
	return await _enqueue_and_wait("titles", HTTPClient.METHOD_POST, "/arena/titles/activate", body)


func _make_http(channel_name: String) -> HTTPRequest:
	var http: = HTTPRequest.new()
	http.name = "ArenaHttp_%s" % channel_name
	http.timeout = HTTP_TIMEOUT_SEC
	http.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(http)
	return http


func _make_watchdog(http: HTTPRequest, channel_name: String) -> Timer:
	var timer: = Timer.new()
	timer.name = "ArenaWatchdog_%s" % channel_name
	timer.one_shot = true
	timer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(timer)
	timer.timeout.connect( func() -> void :
		if http:
			http.cancel_request()
	)
	return timer


func _auth_token() -> String:
	if _network == null:
		return ""
	return str(_network.get("auth_token"))


func _server_url() -> String:
	if _network == null:
		return ""
	return str(_network.get("server_url"))


func _client_version_header() -> String:
	if _network == null:
		return "1.3.3"
	return str(_network.get("client_version_header"))


func _build_headers() -> PackedStringArray:
	return PackedStringArray([
		"Content-Type: application/json", 
		"Authorization: Bearer " + _auth_token(), 
		"X-Client-Version: " + _client_version_header(), 
	])


func _enqueue_and_wait(channel: String, method: int, path: String, body: String) -> Dictionary:
	if _auth_token().is_empty():
		var err_out: = {"ok": false, "error": "未登录", "data": {}}
		arena_request_failed.emit(channel, "未登录")
		return err_out
	var waiter: = {"done": false, "ok": false, "data": {}, "error": ""}
	_get_waiters(channel).append(waiter)
	var http: = _get_http(channel)
	if http != null and not _is_in_flight(channel) and http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		http.cancel_request()
	call_deferred("_pump_channel", channel, method, path, body)
	var deadline_ms: = Time.get_ticks_msec() + int(HTTP_TIMEOUT_SEC * 1000.0) + WALL_CLOCK_EXTRA_MS
	while not bool(waiter.get("done", false)) and Time.get_ticks_msec() < deadline_ms:
		await _await_tick()
	if not bool(waiter.get("done", false)):
		_cancel_channel_http(channel)
		_fail_waiter(waiter, _timeout_message(channel))
		_remove_waiter(channel, waiter)
	if not bool(waiter.get("ok", false)):
		var err_text: = str(waiter.get("error", "请求失败"))
		arena_request_failed.emit(channel, err_text)
		return {
			"ok": false, 
			"error": err_text, 
			"data": waiter.get("data", {}) if waiter.get("data") is Dictionary else {}, 
		}
	var out: Dictionary = waiter.get("data", {}) if waiter.get("data") is Dictionary else {}
	if not out.has("ok"):
		out["ok"] = true
	_emit_channel_signal(channel, out)
	return out


func _emit_channel_signal(channel: String, data: Dictionary) -> void :
	match channel:
		"status":
			status_loaded.emit(data)
		"ranking":
			ranking_loaded.emit(data)
		"mirror":
			mirror_updated.emit(data)
		"match":
			match_started.emit(data)
		"challenge":
			if bool(data.get("pendingConfirm", data.get("pending_confirm", false))):
				challenge_started.emit(data)
			elif data.has("weeklyArenaPoints") or data.has("weekly_arena_points"):
				challenge_confirmed.emit(data)
			else:
				challenge_started.emit(data)
		"confirm":
			challenge_confirmed.emit(data)
		"history":
			challenge_history_loaded.emit(data)
		"shop":
			if data.has("items"):
				shop_items_loaded.emit(data)
			else:
				shop_bought.emit(data)
		"titles":
			if data.has("titles"):
				titles_loaded.emit(data)
			else:
				title_activated.emit(data)


func _timeout_message(channel: String) -> String:
	match channel:
		"match":
			return "匹配请求超时，请检查网络后重试"
		"challenge", "confirm":
			return "战斗请求超时"
		"mirror":
			return "更新镜像超时"
		_:
			return "竞技场请求超时"


func _get_waiters(channel: String) -> Array:
	match channel:
		"status": return _status_waiters
		"ranking": return _ranking_waiters
		"mirror": return _mirror_waiters
		"match": return _match_waiters
		"challenge": return _challenge_waiters
		"confirm": return _confirm_waiters
		"history": return _history_waiters
		"shop": return _shop_waiters
		"titles": return _titles_waiters
		_: return []


func _get_http(channel: String) -> HTTPRequest:
	match channel:
		"status": return _status_http
		"ranking": return _ranking_http
		"mirror": return _mirror_http
		"match": return _match_http
		"challenge": return _challenge_http
		"confirm": return _confirm_http
		"history": return _history_http
		"shop": return _shop_http
		"titles": return _titles_http
		_: return null


func _get_watchdog(channel: String) -> Timer:
	match channel:
		"status": return _status_watchdog
		"ranking": return _ranking_watchdog
		"mirror": return _mirror_watchdog
		"match": return _match_watchdog
		"challenge": return _challenge_watchdog
		"confirm": return _confirm_watchdog
		"history": return _history_watchdog
		"shop": return _shop_watchdog
		"titles": return _titles_watchdog
		_: return null


func _is_in_flight(channel: String) -> bool:
	match channel:
		"status": return _status_in_flight
		"ranking": return _ranking_in_flight
		"mirror": return _mirror_in_flight
		"match": return _match_in_flight
		"challenge": return _challenge_in_flight
		"confirm": return _confirm_in_flight
		"history": return _history_in_flight
		"shop": return _shop_in_flight
		"titles": return _titles_in_flight
		_: return false


func _set_in_flight(channel: String, value: bool) -> void :
	match channel:
		"status": _status_in_flight = value
		"ranking": _ranking_in_flight = value
		"mirror": _mirror_in_flight = value
		"match": _match_in_flight = value
		"challenge": _challenge_in_flight = value
		"confirm": _confirm_in_flight = value
		"history": _history_in_flight = value
		"shop": _shop_in_flight = value
		"titles": _titles_in_flight = value


func _get_defer_attempts(channel: String) -> int:
	match channel:
		"status": return _status_defer_attempts
		"ranking": return _ranking_defer_attempts
		"mirror": return _mirror_defer_attempts
		"match": return _match_defer_attempts
		"challenge": return _challenge_defer_attempts
		"confirm": return _confirm_defer_attempts
		"history": return _history_defer_attempts
		"shop": return _shop_defer_attempts
		"titles": return _titles_defer_attempts
		_: return 0


func _set_defer_attempts(channel: String, value: int) -> void :
	match channel:
		"status": _status_defer_attempts = value
		"ranking": _ranking_defer_attempts = value
		"mirror": _mirror_defer_attempts = value
		"match": _match_defer_attempts = value
		"challenge": _challenge_defer_attempts = value
		"confirm": _confirm_defer_attempts = value
		"history": _history_defer_attempts = value
		"shop": _shop_defer_attempts = value
		"titles": _titles_defer_attempts = value


func _pump_channel(channel: String, method: int, path: String, body: String) -> void :
	var http: = _get_http(channel)
	if http == null:
		_fail_channel_waiters(channel, "HTTP未初始化")
		return
	if _auth_token().is_empty():
		_fail_channel_waiters(channel, "未登录")
		return
	if _is_in_flight(channel):
		return
	if http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		var attempts: = _get_defer_attempts(channel) + 1
		_set_defer_attempts(channel, attempts)
		if attempts > MAX_DEFER_ATTEMPTS:
			_set_defer_attempts(channel, 0)
			http.cancel_request()
		call_deferred("_pump_channel", channel, method, path, body)
		return
	_set_defer_attempts(channel, 0)
	var url: = _server_url() + path
	var headers: = _build_headers()
	_set_in_flight(channel, true)
	_start_watchdog(channel)
	var err: = ERR_BUSY
	if method == HTTPClient.METHOD_GET:
		err = http.request(url, headers, method)
	else:
		err = http.request(url, headers, method, body)
	if err != OK:
		_stop_watchdog(channel)
		_set_in_flight(channel, false)
		_fail_channel_waiters(channel, "HTTP请求失败")


func _on_channel_completed(channel: String, result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void :
	_stop_watchdog(channel)
	_set_in_flight(channel, false)
	_set_defer_attempts(channel, 0)
	if _get_waiters(channel).is_empty():
		return
	if result != HTTPRequest.RESULT_SUCCESS:
		_fail_channel_waiters(channel, _http_result_message(result))
		return
	var parsed: Dictionary = {}
	if body.size() > 0:
		var json: = JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK and json.data is Dictionary:
			parsed = json.data
	if response_code < 200 or response_code >= 300:
		var err_text: = str(parsed.get("error", "请求失败"))
		_fail_channel_waiters(channel, err_text)
		return
	if not bool(parsed.get("success", false)):
		var err_text: = str(parsed.get("error", "请求失败"))
		_fail_channel_waiters(channel, err_text)
		return
	var out: = {"ok": true}
	out.merge(parsed, true)
	_succeed_channel_waiters(channel, out)


func _http_result_message(result: int) -> String:
	match result:
		HTTPRequest.RESULT_CANT_CONNECT: return "无法连接到服务器"
		HTTPRequest.RESULT_CANT_RESOLVE: return "无法解析服务器地址"
		HTTPRequest.RESULT_CONNECTION_ERROR: return "连接错误"
		HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR: return "TLS握手失败"
		HTTPRequest.RESULT_NO_RESPONSE: return "服务器无响应"
		HTTPRequest.RESULT_TIMEOUT: return "请求超时"
		_: return "请求失败"


func _succeed_channel_waiters(channel: String, data: Dictionary) -> void :
	var waiters: = _get_waiters(channel)
	for waiter in waiters:
		if waiter is Dictionary:
			waiter["done"] = true
			waiter["ok"] = true
			waiter["data"] = data
	waiters.clear()


func _fail_channel_waiters(channel: String, error_msg: String) -> void :
	var waiters: = _get_waiters(channel)
	_fail_waiters(waiters, error_msg)
	waiters.clear()


func _fail_waiters(waiters: Array, error_msg: String) -> void :
	for waiter in waiters:
		_fail_waiter(waiter, error_msg)


func _fail_waiter(waiter: Variant, error_msg: String) -> void :
	if waiter is Dictionary:
		waiter["done"] = true
		waiter["ok"] = false
		waiter["error"] = error_msg


func _remove_waiter(channel: String, waiter: Dictionary) -> void :
	var waiters: = _get_waiters(channel)
	var idx: = waiters.find(waiter)
	if idx >= 0:
		waiters.remove_at(idx)


func _cancel_channel_http(channel: String) -> void :
	_cancel_http(_get_http(channel))
	_stop_watchdog(channel)
	_set_in_flight(channel, false)


func _cancel_http(http: HTTPRequest) -> void :
	if http != null and http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		http.cancel_request()


func _start_watchdog(channel: String) -> void :
	var timer: = _get_watchdog(channel)
	var http: = _get_http(channel)
	if timer == null or http == null:
		return
	timer.wait_time = http.timeout + 30.0
	timer.start()


func _stop_watchdog(channel: String) -> void :
	var timer: = _get_watchdog(channel)
	if timer:
		timer.stop()


func _await_tick() -> void :
	if _await_timer == null:
		if get_tree():
			await get_tree().process_frame
		return
	_await_timer.start()
	await _await_timer.timeout
