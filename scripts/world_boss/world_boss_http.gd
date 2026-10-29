class_name WorldBossHttp
extends Node




const HTTP_TIMEOUT_SEC: float = 45.0
const MAX_DEFER_ATTEMPTS: int = 45
const WALL_CLOCK_EXTRA_MS: int = 35000

var _network: Node = null

var _status_http: HTTPRequest
var _ranking_http: HTTPRequest
var _battle_http: HTTPRequest
var _report_http: HTTPRequest

var _status_watchdog: Timer
var _ranking_watchdog: Timer
var _battle_watchdog: Timer
var _report_watchdog: Timer
var _await_timer: Timer

var _status_waiters: Array = []
var _ranking_waiters: Array = []
var _battle_waiters: Array = []
var _report_waiters: Array = []

var _status_defer_attempts: int = 0
var _ranking_defer_attempts: int = 0
var _battle_defer_attempts: int = 0
var _report_defer_attempts: int = 0

var _status_in_flight: bool = false
var _ranking_in_flight: bool = false
var _battle_in_flight: bool = false
var _report_in_flight: bool = false


func setup(network: Node) -> void :
	_network = network
	process_mode = Node.PROCESS_MODE_ALWAYS
	_status_http = _make_http("status")
	_ranking_http = _make_http("ranking")
	_battle_http = _make_http("battle")
	_report_http = _make_http("report")
	_status_http.request_completed.connect( func(r, c, h, b): _on_channel_completed("status", r, c, h, b))
	_ranking_http.request_completed.connect( func(r, c, h, b): _on_channel_completed("ranking", r, c, h, b))
	_battle_http.request_completed.connect( func(r, c, h, b): _on_channel_completed("battle", r, c, h, b))
	_report_http.request_completed.connect( func(r, c, h, b): _on_channel_completed("report", r, c, h, b))
	_status_watchdog = _make_watchdog(_status_http, "status")
	_ranking_watchdog = _make_watchdog(_ranking_http, "ranking")
	_battle_watchdog = _make_watchdog(_battle_http, "battle")
	_report_watchdog = _make_watchdog(_report_http, "report")
	_await_timer = Timer.new()
	_await_timer.name = "WorldBossAwaitTimer"
	_await_timer.one_shot = true
	_await_timer.wait_time = 0.05
	_await_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_await_timer)


func prepare_channels() -> void :
	_cancel_http(_status_http)
	_cancel_http(_ranking_http)
	_cancel_http(_battle_http)
	_cancel_http(_report_http)
	_stop_watchdog("status")
	_stop_watchdog("ranking")
	_stop_watchdog("battle")
	_stop_watchdog("report")
	_status_defer_attempts = 0
	_ranking_defer_attempts = 0
	_battle_defer_attempts = 0
	_report_defer_attempts = 0
	_fail_waiters(_status_waiters, "请求已取消")
	_fail_waiters(_ranking_waiters, "请求已取消")
	_fail_waiters(_battle_waiters, "请求已取消")
	_fail_waiters(_report_waiters, "请求已取消")
	_status_waiters.clear()
	_ranking_waiters.clear()
	_battle_waiters.clear()
	_report_waiters.clear()
	_status_in_flight = false
	_ranking_in_flight = false
	_battle_in_flight = false
	_report_in_flight = false
	print("[WorldBossHttp] prepare_channels: all channels reset")


func fetch_status() -> Dictionary:
	return await _enqueue_and_wait("status", HTTPClient.METHOD_GET, "/world-boss/status", "")


func fetch_ranking(limit: int = 100) -> Dictionary:
	var lim: = maxi(1, limit)
	return await _enqueue_and_wait(
		"ranking", 
		HTTPClient.METHOD_GET, 
		"/world-boss/ranking?limit=%d" % lim, 
		""
	)


func start_battle() -> Dictionary:
	return await _enqueue_and_wait("battle", HTTPClient.METHOD_POST, "/world-boss/battle-start", "{}")


func report_damage(battle_token: String, damage: int, pet_snapshot: Dictionary) -> Dictionary:
	var body: = JSON.stringify({
		"battleToken": battle_token, 
		"damage": damage, 
		"petSnapshot": pet_snapshot, 
	})
	return await _enqueue_and_wait("report", HTTPClient.METHOD_POST, "/world-boss/battle-report", body)


func _make_http(channel_name: String) -> HTTPRequest:
	var http: = HTTPRequest.new()
	http.name = "WorldBossHttp_%s" % channel_name
	http.timeout = HTTP_TIMEOUT_SEC
	http.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(http)
	return http


func _make_watchdog(http: HTTPRequest, channel_name: String) -> Timer:
	var timer: = Timer.new()
	timer.name = "WorldBossWatchdog_%s" % channel_name
	timer.one_shot = true
	timer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(timer)
	timer.timeout.connect( func() -> void :
		print("[WorldBossHttp] watchdog timeout channel=%s" % channel_name)
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
		print("[WorldBossHttp] cancel stale channel=%s before new request" % channel)
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
		return {
			"ok": false, 
			"error": str(waiter.get("error", "请求失败")), 
			"data": waiter.get("data", {}) if waiter.get("data") is Dictionary else {}, 
		}
	var out: Dictionary = waiter.get("data", {}) if waiter.get("data") is Dictionary else {}
	if not out.has("ok"):
		out["ok"] = true
	return out


func _timeout_message(channel: String) -> String:
	match channel:
		"battle":
			return "开战请求超时，请检查网络后重试"
		"report":
			return "伤害上报超时"
		_:
			return "排行同步失败：请求超时"


func _get_waiters(channel: String) -> Array:
	match channel:
		"status":
			return _status_waiters
		"ranking":
			return _ranking_waiters
		"battle":
			return _battle_waiters
		"report":
			return _report_waiters
		_:
			return []


func _get_http(channel: String) -> HTTPRequest:
	match channel:
		"status":
			return _status_http
		"ranking":
			return _ranking_http
		"battle":
			return _battle_http
		"report":
			return _report_http
		_:
			return null


func _get_watchdog(channel: String) -> Timer:
	match channel:
		"status":
			return _status_watchdog
		"ranking":
			return _ranking_watchdog
		"battle":
			return _battle_watchdog
		"report":
			return _report_watchdog
		_:
			return null


func _is_in_flight(channel: String) -> bool:
	match channel:
		"status":
			return _status_in_flight
		"ranking":
			return _ranking_in_flight
		"battle":
			return _battle_in_flight
		"report":
			return _report_in_flight
		_:
			return false


func _set_in_flight(channel: String, value: bool) -> void :
	match channel:
		"status":
			_status_in_flight = value
		"ranking":
			_ranking_in_flight = value
		"battle":
			_battle_in_flight = value
		"report":
			_report_in_flight = value


func _get_defer_attempts(channel: String) -> int:
	match channel:
		"status":
			return _status_defer_attempts
		"ranking":
			return _ranking_defer_attempts
		"battle":
			return _battle_defer_attempts
		"report":
			return _report_defer_attempts
		_:
			return 0


func _set_defer_attempts(channel: String, value: int) -> void :
	match channel:
		"status":
			_status_defer_attempts = value
		"ranking":
			_ranking_defer_attempts = value
		"battle":
			_battle_defer_attempts = value
		"report":
			_report_defer_attempts = value


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
			print("[WorldBossHttp] defer cap channel=%s, cancel_request" % channel)
			_set_defer_attempts(channel, 0)
			http.cancel_request()
		call_deferred("_pump_channel", channel, method, path, body)
		return
	_set_defer_attempts(channel, 0)
	var url: = _server_url() + path
	var headers: = _build_headers()
	print("[WorldBossHttp] request_sent channel=%s %s" % [channel, path])
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
	print("[WorldBossHttp] completed channel=%s result=%d http=%d" % [channel, result, response_code])
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
		HTTPRequest.RESULT_CANT_CONNECT:
			return "无法连接到服务器"
		HTTPRequest.RESULT_CANT_RESOLVE:
			return "无法解析服务器地址"
		HTTPRequest.RESULT_CONNECTION_ERROR:
			return "连接错误"
		HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
			return "TLS握手失败"
		HTTPRequest.RESULT_NO_RESPONSE:
			return "服务器无响应"
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
