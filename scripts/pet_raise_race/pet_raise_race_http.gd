class_name PetRaiseRaceHttp
extends Node



const HTTP_TIMEOUT_SEC: float = 45.0
const MAX_DEFER_ATTEMPTS: int = 45
const WALL_CLOCK_EXTRA_MS: int = 35000

var _network: Node = null

var _status_http: HTTPRequest
var _ranking_http: HTTPRequest
var _submit_http: HTTPRequest

var _status_watchdog: Timer
var _ranking_watchdog: Timer
var _submit_watchdog: Timer
var _await_timer: Timer

var _status_waiters: Array = []
var _ranking_waiters: Array = []
var _submit_waiters: Array = []

var _status_defer_attempts: int = 0
var _ranking_defer_attempts: int = 0
var _submit_defer_attempts: int = 0

var _status_in_flight: bool = false
var _ranking_in_flight: bool = false
var _submit_in_flight: bool = false


func setup(network: Node) -> void :
	_network = network
	process_mode = Node.PROCESS_MODE_ALWAYS
	_status_http = _make_http("status")
	_ranking_http = _make_http("ranking")
	_submit_http = _make_http("submit")
	_status_http.request_completed.connect( func(r, c, h, b): _on_channel_completed("status", r, c, h, b))
	_ranking_http.request_completed.connect( func(r, c, h, b): _on_channel_completed("ranking", r, c, h, b))
	_submit_http.request_completed.connect( func(r, c, h, b): _on_channel_completed("submit", r, c, h, b))
	_status_watchdog = _make_watchdog(_status_http, "status")
	_ranking_watchdog = _make_watchdog(_ranking_http, "ranking")
	_submit_watchdog = _make_watchdog(_submit_http, "submit")
	_await_timer = Timer.new()
	_await_timer.name = "PetRaiseRaceAwaitTimer"
	_await_timer.one_shot = true
	_await_timer.wait_time = 0.05
	_await_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_await_timer)


func prepare_channels() -> void :
	_cancel_http(_status_http)
	_cancel_http(_ranking_http)
	_cancel_http(_submit_http)
	_stop_watchdog("status")
	_stop_watchdog("ranking")
	_stop_watchdog("submit")
	_status_defer_attempts = 0
	_ranking_defer_attempts = 0
	_submit_defer_attempts = 0
	_fail_waiters(_status_waiters, "请求已取消")
	_fail_waiters(_ranking_waiters, "请求已取消")
	_fail_waiters(_submit_waiters, "请求已取消")
	_status_waiters.clear()
	_ranking_waiters.clear()
	_submit_waiters.clear()
	_status_in_flight = false
	_ranking_in_flight = false
	_submit_in_flight = false


func fetch_status() -> Dictionary:
	return await _enqueue_and_wait("status", HTTPClient.METHOD_GET, "/pet-raise-race/status", "")


func fetch_ranking(limit: int = 100) -> Dictionary:
	var lim: = maxi(1, mini(100, limit))
	return await _enqueue_and_wait(
		"ranking", 
		HTTPClient.METHOD_GET, 
		"/pet-raise-race/ranking?limit=%d" % lim, 
		""
	)


func submit_pet(pet_id: String, operation_id: String = "") -> Dictionary:
	var body: = JSON.stringify({
		"petId": str(pet_id), 
		"operationId": str(operation_id), 
	})
	return await _enqueue_and_wait("submit", HTTPClient.METHOD_POST, "/pet-raise-race/submit", body)


func _make_http(channel_name: String) -> HTTPRequest:
	var http: = HTTPRequest.new()
	http.name = "PetRaiseRaceHttp_%s" % channel_name
	http.timeout = HTTP_TIMEOUT_SEC
	http.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(http)
	return http


func _make_watchdog(http: HTTPRequest, channel_name: String) -> Timer:
	var timer: = Timer.new()
	timer.name = "PetRaiseRaceWatchdog_%s" % channel_name
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
		return {"ok": false, "error": "未登录", "data": {}}
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
		_fail_waiter(waiter, "请求超时")
		_remove_waiter(channel, waiter)
	if not bool(waiter.get("ok", false)):
		return {
			"ok": false, 
			"error": str(waiter.get("error", "请求失败")), 
			"data": waiter.get("data", {}) if waiter.get("data") is Dictionary else {}, 
		}
	var out: Dictionary = waiter.get("data", {}) if waiter.get("data") is Dictionary else {}
	if not out.has("ok"):
		out["ok"] = true
	return out


func _get_waiters(channel: String) -> Array:
	match channel:
		"status":
			return _status_waiters
		"ranking":
			return _ranking_waiters
		"submit":
			return _submit_waiters
		_:
			return []


func _get_http(channel: String) -> HTTPRequest:
	match channel:
		"status":
			return _status_http
		"ranking":
			return _ranking_http
		"submit":
			return _submit_http
		_:
			return null


func _get_watchdog(channel: String) -> Timer:
	match channel:
		"status":
			return _status_watchdog
		"ranking":
			return _ranking_watchdog
		"submit":
			return _submit_watchdog
		_:
			return null


func _is_in_flight(channel: String) -> bool:
	match channel:
		"status":
			return _status_in_flight
		"ranking":
			return _ranking_in_flight
		"submit":
			return _submit_in_flight
		_:
			return false


func _set_in_flight(channel: String, value: bool) -> void :
	match channel:
		"status":
			_status_in_flight = value
		"ranking":
			_ranking_in_flight = value
		"submit":
			_submit_in_flight = value


func _get_defer_attempts(channel: String) -> int:
	match channel:
		"status":
			return _status_defer_attempts
		"ranking":
			return _ranking_defer_attempts
		"submit":
			return _submit_defer_attempts
		_:
			return 0


func _set_defer_attempts(channel: String, value: int) -> void :
	match channel:
		"status":
			_status_defer_attempts = value
		"ranking":
			_ranking_defer_attempts = value
		"submit":
			_submit_defer_attempts = value


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
		return


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
		_fail_channel_waiters(channel, str(parsed.get("error", "请求失败")))
		return
	if not bool(parsed.get("success", false)):
		_fail_channel_waiters(channel, str(parsed.get("error", "请求失败")))
		return
	var out: = {"ok": true}
	out.merge(parsed, true)
	_succeed_channel_waiters(channel, out)


func _http_result_message(result: int) -> String:
	match result:
		HTTPRequest.RESULT_CANT_CONNECT:
			return "无法连接到服务器"
		HTTPRequest.RESULT_TIMEOUT:
			return "请求超时"
		_:
			return "请求失败"


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
