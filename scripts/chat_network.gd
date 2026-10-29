extends Node
class_name ChatNetwork

const _GameServerConfig = preload("res://scripts/game_server_config.gd")
const ANNOUNCEMENT_CURSOR_CONFIG_PATH: = "user://announcement_cursor.cfg"

signal message_received(message_data)
signal announcement_received(announcement_data)
signal message_send_succeeded(payload)
signal message_send_failed(error_code, error_message, payload)

var http_request: HTTPRequest
var send_request: HTTPRequest
var announcement_request: HTTPRequest
var _history_http: HTTPRequest
var _history_fetch_busy: bool = false
var poll_timer: Timer
var announcement_timer: Timer
var last_message_id: int = 0
var _world_last_message_id: int = 0
var _gang_last_message_id: Dictionary = {}
var last_announcement_id: int = 0
var _announcement_first_poll_done: bool = false
var is_polling: bool = false
var _pending_send_payload: Dictionary = {}
var chat_channel: String = "world"
var chat_gang_id: int = 0
var server_url: String = _GameServerConfig.chat_service_root()
var main_server_url: String = _GameServerConfig.main_service_root()

func _load_server_urls() -> void :
	var chat_cfg = str(ProjectSettings.get_setting("application/config/chat_server_url", _GameServerConfig.chat_service_root())).strip_edges()
	var main_cfg = str(ProjectSettings.get_setting("application/config/main_server_url", _GameServerConfig.main_service_root())).strip_edges()
	if not chat_cfg.is_empty():
		server_url = chat_cfg
	if not main_cfg.is_empty():
		main_server_url = main_cfg


func sync_from_api_session(network_api_root: String) -> void :
	var raw: = String(network_api_root).strip_edges().rstrip("/")
	var fb: = _GameServerConfig.api_http_fallback_base().strip_edges().rstrip("/")
	if raw.is_empty():
		server_url = _GameServerConfig.chat_service_root()
		main_server_url = _GameServerConfig.main_service_root()
		_load_server_urls()
		return
	var use_direct_ip: = raw == fb
	if use_direct_ip:
		server_url = _GameServerConfig.chat_http_fallback_root()
		main_server_url = _GameServerConfig.main_http_fallback_root()
	else:
		server_url = _GameServerConfig.chat_service_root()
		main_server_url = _GameServerConfig.main_service_root()
	_load_server_urls()
	if use_direct_ip:
		server_url = _GameServerConfig.chat_http_fallback_root()
		main_server_url = _GameServerConfig.main_http_fallback_root()

func _get_main_auth_token() -> String:
	var gm = GameManager.instance
	if gm != null and gm.network != null and gm.network.has_method("get_auth_token"):
		return String(gm.network.get_auth_token())
	var network_node = get_node_or_null("/root/Network")
	if network_node and network_node.has_method("get_auth_token"):
		return String(network_node.get_auth_token())
	return ""

func _get_main_wipe_id() -> String:
	var gm = GameManager.instance
	if gm != null and gm.network != null and gm.network.has_method("get_server_wipe_id"):
		return String(gm.network.get_server_wipe_id()).strip_edges()
	var network_node = get_node_or_null("/root/Network")
	if network_node and network_node.has_method("get_server_wipe_id"):
		return String(network_node.get_server_wipe_id()).strip_edges()
	return ""


func _sync_urls_from_game_network() -> void :
	var gm = GameManager.instance
	if gm == null or gm.network == null:
		return
	var su: = str(gm.network.get("server_url")).strip_edges()
	if su.is_empty():
		return
	sync_from_api_session(su)

func _chat_client_version_header() -> String:
	var gm = GameManager.instance
	if gm != null and gm.network != null:
		var v = gm.network.get("client_version_header")
		if v != null:
			var s: = String(v).strip_edges()
			if not s.is_empty():
				return s
	return "1.3.3"

func _ready():
	_load_server_urls()
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_poll_completed)

	send_request = HTTPRequest.new()
	add_child(send_request)
	send_request.request_completed.connect(_on_send_completed)

	announcement_request = HTTPRequest.new()
	add_child(announcement_request)
	announcement_request.request_completed.connect(_on_announcement_completed)

	_history_http = HTTPRequest.new()
	add_child(_history_http)

	poll_timer = Timer.new()
	poll_timer.wait_time = 5.0
	poll_timer.one_shot = false
	poll_timer.timeout.connect(_poll_messages)
	add_child(poll_timer)

	announcement_timer = Timer.new()
	announcement_timer.wait_time = 10.0
	announcement_timer.one_shot = false
	announcement_timer.timeout.connect(_poll_announcements)
	add_child(announcement_timer)

func start_polling():
	if GameManager.instance and GameManager.instance.has_method("local_feature_action"):
		return
	_load_announcement_cursor()
	is_polling = true
	poll_timer.start()
	announcement_timer.start()
	_poll_messages()
	_poll_announcements()

func stop_polling():
	is_polling = false
	poll_timer.stop()
	announcement_timer.stop()

func set_world_channel() -> void :
	_persist_last_message_id_for_active_channel()
	chat_channel = "world"
	chat_gang_id = 0
	last_message_id = _world_last_message_id

func set_gang_channel(gang_id: int) -> void :
	_persist_last_message_id_for_active_channel()
	chat_channel = "gang"
	chat_gang_id = maxi(0, gang_id)
	last_message_id = int(_gang_last_message_id.get(chat_gang_id, 0))

func _persist_last_message_id_for_active_channel() -> void :
	if chat_channel == "gang" and chat_gang_id > 0:
		_gang_last_message_id[chat_gang_id] = last_message_id
	else:
		_world_last_message_id = last_message_id

func _update_channel_cursor(channel_type: String, gang_id: int, new_id: int) -> void :
	if new_id <= 0:
		return
	if channel_type == "gang" and gang_id > 0:
		if new_id > int(_gang_last_message_id.get(gang_id, 0)):
			_gang_last_message_id[gang_id] = new_id
	else:
		if new_id > _world_last_message_id:
			_world_last_message_id = new_id
	if chat_channel == channel_type and (channel_type != "gang" or chat_gang_id == gang_id):
		if new_id > last_message_id:
			last_message_id = new_id

func poll_messages_now() -> void :
	_poll_messages()

func _poll_request_headers() -> PackedStringArray:
	var headers: = PackedStringArray(["X-Client-Version: " + _chat_client_version_header()])
	if chat_channel == "gang":
		var token: = _get_main_auth_token()
		if token != "":
			headers.append("Authorization: Bearer " + token)
	return headers

func send_message(player_name: String, message: String, event_type: String = "chat", is_vip: bool = false, title: String = "", vip_level: int = 0):
	if GameManager.instance and GameManager.instance.has_method("local_feature_action"):
		var gm = GameManager.instance
		var rows: Array = gm._local_metadata.get("local_chat", [])
		var row := {"id": rows.size() + 1, "player_name": player_name, "message": "【本地模拟】" + message, "event_type": event_type, "is_vip": is_vip, "vip_level": vip_level, "title": title, "channel": chat_channel, "gangId": chat_gang_id}
		rows.append(row)
		if rows.size() > 100:
			rows.pop_front()
		gm._local_metadata.local_chat = rows
		if gm.save_game():
			message_received.emit(row)
		return
	_sync_urls_from_game_network()
	_pending_send_payload = {
		"player_name": player_name, 
		"message": message, 
		"event_type": event_type, 
		"is_vip": is_vip, 
		"title": title, 
		"vip_level": vip_level
	}
	var body = JSON.stringify({
		"player_name": player_name, 
		"message": message, 
		"event_type": event_type, 
		"is_vip": is_vip, 
		"title": title, 
		"vip_level": vip_level, 
		"channel": chat_channel, 
		"gangId": chat_gang_id
	})

	var headers = ["Content-Type: application/json", "X-Client-Version: " + _chat_client_version_header()]
	var token = _get_main_auth_token()
	if token != "":
		headers.append("Authorization: Bearer " + token)
	print("[ChatNetwork] 发送聊天: url=", server_url + "/api/messages", " token=", token != "")
	var err = send_request.request(server_url + "/api/messages", headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		print("[ChatNetwork] 发送消息失败: ", err)
		message_send_failed.emit(-1, "request_error_%s" % str(err), _pending_send_payload.duplicate())

func send_world_message(player_name: String, message: String, event_type: String = "chat", is_vip: bool = false, title: String = "", vip_level: int = 0) -> void :
	var prev_channel: = chat_channel
	var prev_gang_id: = chat_gang_id
	chat_channel = "world"
	chat_gang_id = 0
	send_message(player_name, message, event_type, is_vip, title, vip_level)
	chat_channel = prev_channel
	chat_gang_id = prev_gang_id

func _on_send_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	var payload: = _pending_send_payload.duplicate()
	_pending_send_payload.clear()
	if result != HTTPRequest.RESULT_SUCCESS:
		print("[ChatNetwork] 发送消息网络失败: result=", result)
		message_send_failed.emit(response_code, "network_result_%s" % str(result), payload)
		return
	if response_code < 200 or response_code >= 300:
		var reason: = "http_%s" % str(response_code)
		var body_text: String = body.get_string_from_utf8().strip_edges()
		if not body_text.is_empty():
			var json: = JSON.new()
			if json.parse(body_text) == OK and json.data is Dictionary:
				reason = String((json.data as Dictionary).get("error", reason))
		print("[ChatNetwork] 发送消息被拒绝: code=", response_code, " reason=", reason)
		message_send_failed.emit(response_code, reason, payload)
		return
	# 旧版服务端的聊天接口是空桩：不管发什么，POST 都回 {"success":true,"messages":[]}，
	# 一条不存。客户端拿到 200 就以为发成功，界面上却永远什么都不出现 —— 玩家看到
	# 的就是「点了发送没反应」。这里认「有 messages 数组却没有 id」的响应，报失败。
	var resp_text: String = body.get_string_from_utf8().strip_edges()
	if not resp_text.is_empty():
		var parsed: = JSON.new()
		if parsed.parse(resp_text) == OK and parsed.data is Dictionary:
			var resp: Dictionary = parsed.data
			if not resp.has("id") and resp.get("messages") is Array:
				print("[ChatNetwork] 服务端聊天接口仍是空桩，消息没有被存储")
				message_send_failed.emit(200, "server-stub", payload)
				return
	message_send_succeeded.emit(payload)
	# 轮询是 5 秒一轮：发完立刻拉一次，否则玩家点完「发送」要愣等好几秒
	# 才看见自己那句话，体感就是「点了没反应」。
	poll_messages_now()

func _poll_messages():
	if GameManager.instance and GameManager.instance.has_method("local_feature_action"):
		return
	if not is_polling:
		return

	_sync_urls_from_game_network()
	var poll_headers: = _poll_request_headers()
	var url = server_url + "/api/messages?lastId=" + str(last_message_id) + "&limit=50&channel=" + chat_channel
	if chat_channel == "gang" and chat_gang_id > 0:
		url += "&gangId=" + str(chat_gang_id)
	var err = http_request.request(url, poll_headers, HTTPClient.METHOD_GET)
	if err != OK:
		print("[ChatNetwork] 获取消息失败: ", err)

func _normalize_message_dict(d: Dictionary) -> void :
	var t = d.get("title", "")
	if str(t).is_empty():
		t = d.get("Title", d.get("TITLE", ""))
	if not str(t).is_empty():
		d["title"] = str(t)
	var channel_type: = str(d.get("channel_type", d.get("channelType", ""))).strip_edges()
	if channel_type.is_empty():
		channel_type = "world"
	d["channel_type"] = channel_type
	d["gang_id"] = int(d.get("gang_id", d.get("gangId", 0)))

func _fetch_chat_history(url: String, channel_type: String, gang_id: int, limit: int) -> Array:
	var out: Array = []
	if _history_fetch_busy or not is_instance_valid(_history_http):
		return out
	var lim: = clampi(limit, 1, 100)
	_history_fetch_busy = true
	_sync_urls_from_game_network()
	var hist_headers: = _poll_request_headers() if channel_type == "gang" else PackedStringArray(["X-Client-Version: " + _chat_client_version_header()])
	var err: = _history_http.request(url, hist_headers, HTTPClient.METHOD_GET)
	if err != OK:
		_history_fetch_busy = false
		return out
	var args = await _history_http.request_completed
	_history_fetch_busy = false
	var result: int = args[0]
	var response_code: int = args[1]
	var body: PackedByteArray = args[3]
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		return out
	var json = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		return out
	var data = json.data
	if not data is Array:
		return out
	var max_id: = 0
	if channel_type == "gang" and gang_id > 0:
		max_id = int(_gang_last_message_id.get(gang_id, 0))
	else:
		max_id = _world_last_message_id
	for msg in data:
		if not msg is Dictionary:
			continue
		var d: Dictionary = (msg as Dictionary).duplicate()
		_normalize_message_dict(d)
		d["channel_type"] = channel_type
		if channel_type == "gang":
			d["gang_id"] = gang_id
		var mid: = int(d.get("id", 0))
		if mid > max_id:
			max_id = mid
		out.append(d)
	_update_channel_cursor(channel_type, gang_id, max_id)
	return out


func fetch_world_chat_history(limit: int = 30) -> Array:
	if GameManager.instance and GameManager.instance.has_method("local_feature_action"):
		return GameManager.instance._local_metadata.get("local_chat", []).duplicate(true)
	var lim: = clampi(limit, 1, 100)
	var url: = server_url + "/api/messages?lastId=0&limit=" + str(lim) + "&channel=world"
	return await _fetch_chat_history(url, "world", 0, lim)

func fetch_gang_chat_history(gang_id: int, limit: int = 30) -> Array:
	if GameManager.instance and GameManager.instance.has_method("local_feature_action"):
		return GameManager.instance._local_metadata.get("local_chat", []).duplicate(true)
	var gid: = maxi(0, gang_id)
	if gid <= 0:
		return []
	var lim: = clampi(limit, 1, 100)
	var url: = server_url + "/api/messages?lastId=0&limit=" + str(lim) + "&channel=gang&gangId=" + str(gid)
	return await _fetch_chat_history(url, "gang", gid, lim)

func _poll_announcements():
	if GameManager.instance and GameManager.instance.has_method("local_feature_action"):
		return
	if not is_polling:
		return

	_sync_urls_from_game_network()
	var ann_headers: = PackedStringArray(["X-Client-Version: " + _chat_client_version_header()])
	var url = main_server_url + "/api/announcements?lastId=" + str(last_announcement_id)
	var err = announcement_request.request(url, ann_headers, HTTPClient.METHOD_GET)
	if err != OK:
		print("[ChatNetwork] 获取公告失败: ", err)

func _on_poll_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		return
	if response_code < 200 or response_code >= 300:
		return

	var json = JSON.new()
	var err = json.parse(body.get_string_from_utf8())
	if err != OK:
		return

	var data = json.data

	if data is Array:
		for msg in data:
			if not msg is Dictionary:
				continue
			var d: Dictionary = msg
			_normalize_message_dict(d)
			var mid = int(d.get("id", 0))
			_update_channel_cursor(chat_channel, chat_gang_id, mid)
			message_received.emit(d)

func _on_announcement_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		return
	if response_code < 200 or response_code >= 300:
		return

	var json = JSON.new()
	var err = json.parse(body.get_string_from_utf8())
	if err != OK:
		return

	var data = json.data

	if data is Array:
		var first_without_cursor: = ( not _announcement_first_poll_done and last_announcement_id <= 0)
		var max_id: = last_announcement_id
		for announcement in data:
			var aid: = _announcement_id_from_entry(announcement)
			if aid > max_id:
				max_id = aid
		if first_without_cursor and data.size() > 0:
			print("[ChatNetwork] 首次公告拉取且本地游标为空，仅推进游标不回放历史")
			if max_id > last_announcement_id:
				last_announcement_id = max_id
				_save_announcement_cursor()
			elif max_id <= 0:
				push_warning("[ChatNetwork] 公告列表无法解析 id，请检查 /api/announcements 返回格式")
			_announcement_first_poll_done = true
			return
		for announcement in data:
			var aid2: = _announcement_id_from_entry(announcement)
			if aid2 <= last_announcement_id:
				continue
			last_announcement_id = aid2
			_save_announcement_cursor()
			announcement_received.emit(announcement)
		_announcement_first_poll_done = true

func _announcement_id_from_entry(announcement: Variant) -> int:

	if typeof(announcement) != TYPE_DICTIONARY:
		return 0
	var d: Dictionary = announcement
	if d.has("id"):
		return int(d["id"])
	if d.has("Id"):
		return int(d["Id"])
	return 0

func _load_announcement_cursor() -> void :
	var cfg: = ConfigFile.new()
	if cfg.load(ANNOUNCEMENT_CURSOR_CONFIG_PATH) != OK:
		return
	var remote_wipe_id: = _get_main_wipe_id()
	var saved_wipe_id: = String(cfg.get_value("announcements", "wipe_id", "")).strip_edges()
	if remote_wipe_id != "" and saved_wipe_id != "" and saved_wipe_id != remote_wipe_id:
		last_announcement_id = 0
		_announcement_first_poll_done = false
		print("[ChatNetwork] 检测到 wipe_id 变化，重置公告游标: ", saved_wipe_id, " -> ", remote_wipe_id)
		return
	var saved: = int(cfg.get_value("announcements", "last_id", 0))
	if saved > last_announcement_id:
		last_announcement_id = saved
		print("[ChatNetwork] 加载公告游标: ", last_announcement_id)

func _save_announcement_cursor() -> void :
	var cfg: = ConfigFile.new()
	cfg.set_value("announcements", "last_id", last_announcement_id)
	var remote_wipe_id: = _get_main_wipe_id()
	if remote_wipe_id != "":
		cfg.set_value("announcements", "wipe_id", remote_wipe_id)
	var save_result: = cfg.save(ANNOUNCEMENT_CURSOR_CONFIG_PATH)
	if save_result != OK:
		push_warning("[ChatNetwork] 公告游标落盘失败: %s" % str(save_result))
