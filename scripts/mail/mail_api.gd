class_name MailAPI
extends RefCounted


const _SC_ERR_UNAVAILABLE: = 2
const _SC_ERR_INVALID_URL: = 43

const _GameServerConfig = preload("res://scripts/game_server_config.gd")

signal mail_list_received(mails: Array)
signal mail_detail_received(mail: MailData)
signal attachment_claimed(mail_id: int, attachments: Dictionary)
signal all_attachments_claimed(claimed_list: Array)
signal unread_count_received(count: int)
signal claimed_mails_deleted(deleted_count: int)

signal mail_delete_done(success: bool, deleted_count: int, error_message: String)
signal error_occurred(error_message: String)

signal finalize_claims_done(success: bool, error_message: String, payload: Dictionary)

signal pet_overflow_mail_done(success: bool, error_message: String, payload: Dictionary)


var _http_request: HTTPRequest

var _api_base_override: String = ""

var _client_version_header: String = ""

func set_client_version_header(version: String) -> void :
	var v: = String(version).strip_edges()
	_client_version_header = v

func set_api_base_override(url: String) -> void :
	var u: = String(url).strip_edges().rstrip("/")
	_api_base_override = u

func _mail_api_root() -> String:
	if not _api_base_override.is_empty():
		return _api_base_override
	return _GameServerConfig.api_base()

func get_effective_api_base() -> String:
	return _mail_api_root()

func _client_ver_for_header() -> String:
	var v: = _client_version_header.strip_edges()
	if not v.is_empty():
		return v
	return "1.3.3"


func get_resolved_client_version_header() -> String:
	return _client_ver_for_header()

func _auth_json_headers(token: String) -> PackedStringArray:
	return [
		"Authorization: Bearer %s" % token, 
		"Content-Type: application/json", 
		"X-Client-Version: %s" % _client_ver_for_header(), 

	]

func _header_value(headers: PackedStringArray, header_name: String) -> String:
	var want: = header_name.strip_edges().to_lower()
	for h in headers:
		var line: = str(h)
		var idx: = line.find(":")
		if idx < 0:
			continue
		var k: = line.substr(0, idx).strip_edges().to_lower()
		if k == want:
			return line.substr(idx + 1).strip_edges()
	return ""

func _request_start_failed_message(req_err: int) -> String:
	if req_err == _SC_ERR_INVALID_URL:
		return "邮件接口地址无效，请重新登录后再试"
	if req_err == _SC_ERR_UNAVAILABLE:
		return "邮件请求无法发起，请检查网络后重试"
	return "网络请求失败"

func _init():
	_http_request = HTTPRequest.new()

func _utf8_body_text(body: PackedByteArray) -> String:
	var s: = body.get_string_from_utf8()
	if s.is_empty() and body.size() > 0:
		s = body.get_string_from_ascii()
	s = s.strip_edges()
	if s.begins_with(""):
		s = s.substr(1)
	return s

func _http_transport_error_message(http_result: int) -> String:
	match http_result:
		HTTPRequest.RESULT_CANT_CONNECT:
			return "无法连接服务器"
		HTTPRequest.RESULT_CANT_RESOLVE:
			return "无法解析服务器地址"
		HTTPRequest.RESULT_CONNECTION_ERROR:
			return "网络连接异常"
		HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
			return "TLS握手失败"
		HTTPRequest.RESULT_NO_RESPONSE:
			return "服务器无响应"
		HTTPRequest.RESULT_TIMEOUT:
			return "请求超时"
		_:
			return "网络请求失败"


func _try_parse_json_loose(text: String, context: String) -> Variant:
	var json: = JSON.new()
	if json.parse(text) == OK:
		return json.data
	var t: = text.strip_edges()
	if t.is_empty():
		return null

	var brace0: = t.find("{")
	if brace0 > 0:
		var tail: = t.substr(brace0)
		if json.parse(tail) == OK:
			push_warning("[MailAPI] %s: JSON 已跳过前缀 %d 字符后解析成功" % [context, brace0])
			return json.data

	if not t.begins_with("{") and not t.begins_with("["):
		var q: = t
		if q.begins_with("\"success\"") or q.begins_with("'success'"):
			q = "{" + q
			if json.parse(q) == OK:
				push_warning("[MailAPI] %s: JSON 已补上根对象 { 后解析成功" % context)
				return json.data
	return null

func _parse_json_mail_response(body: PackedByteArray, context: String) -> Variant:
	if body.size() >= 2 and body[0] == 31 and body[1] == 139:
		push_warning("[MailAPI] %s: body is gzip bytes (HTTPRequest 未自动解压；请保持 accept_gzip 默认开启)" % context)
	var text: = _utf8_body_text(body)
	if text.is_empty():
		push_warning("[MailAPI] %s: empty body" % context)
		return null
	var parsed: Variant = _try_parse_json_loose(text, context)
	if parsed != null:
		return parsed
	var preview: = text
	if preview.length() > 180:
		preview = preview.substr(0, 180) + "..."
	push_warning("[MailAPI] %s JSON parse failed, preview: %s" % [context, preview])
	return null


func _non_json_response_user_message(body: PackedByteArray) -> String:
	var text: = _utf8_body_text(body)
	var t: = text.strip_edges()
	if t.is_empty():
		return "邮件服务返回空数据，请稍后重试"
	var tl: = t.to_lower()
	if tl.begins_with("<!doctype") or tl.begins_with("<html") or tl.contains("<head") or tl.contains("<body"):
		return "邮件接口返回了网页而非数据，请重新登录或检查网络（邮件地址须与当前登录服务器一致）"
	if t.length() < 400 and not t.contains("{") and not t.contains("["):
		return "邮件服务异常：%s" % t
	return "解析邮件数据失败（响应不是有效 JSON，请稍后重试）"

func _configure_http_request_child(req: HTTPRequest) -> void :
	req.timeout = 45.0
	req.max_redirects = 8
	req.accept_gzip = true


func setup_http_request(parent: Node) -> void :
	if _http_request.get_parent():
		_http_request.get_parent().remove_child(_http_request)
	parent.add_child(_http_request)
	_configure_http_request_child(_http_request)


func get_http_parent() -> Node:
	return _http_request.get_parent() if _http_request else null

func _request_once(url: String, headers: PackedStringArray, method: int, body: String, done: Callable, network_error: String, fail_signal: Callable = Callable()) -> void :
	var parent = get_http_parent()
	if parent == null:
		if fail_signal.is_valid():
			fail_signal.call()
		else:
			error_occurred.emit(network_error)
		return
	var req = HTTPRequest.new()
	parent.add_child(req)
	_configure_http_request_child(req)
	req.request_completed.connect( func(result: int, response_code: int, response_headers: PackedStringArray, response_body: PackedByteArray):
		if done.is_valid():
			done.call(result, response_code, response_body, response_headers)
		req.queue_free()
	, CONNECT_ONE_SHOT)
	var err = req.request(url, headers, method, body)
	if err != OK:
		push_warning("[MailAPI] request start failed: %s (%d) url=%s" % [error_string(err), err, url])
		req.queue_free()
		if fail_signal.is_valid():
			fail_signal.call()
		else:
			error_occurred.emit(_request_start_failed_message(err))


func process_mail_list_http_response(result: int, response_code: int, body: PackedByteArray, resp_headers: PackedStringArray = PackedStringArray()) -> void :
	if result != HTTPRequest.RESULT_SUCCESS:
		error_occurred.emit(_http_transport_error_message(result))
		return
	if response_code != 200:
		error_occurred.emit("获取邮件列表失败（HTTP %d）" % response_code)
		return

	var data_any = _parse_json_mail_response(body, "mail/list")
	if data_any == null:
		var ce: = _header_value(resp_headers, "content-encoding").to_lower()
		if ce.contains("br"):
			push_warning("[MailAPI] mail/list Content-Encoding=%s (Brotli); client cannot decompress" % ce)
			error_occurred.emit("邮件接口使用了 Brotli 压缩，客户端无法解压。请在 Nginx 中对 /api 关闭 brotli 或仅使用 gzip。")
			return
		error_occurred.emit(_non_json_response_user_message(body))
		return
	if not data_any is Dictionary:
		error_occurred.emit("邮件数据格式错误")
		return
	var data: Dictionary = data_any
	if not data.get("success", false):
		error_occurred.emit(str(data.get("error", "未知错误")))
		return

	var mails: Array[MailData] = []
	var mail_list = data.get("mails", [])
	if not mail_list is Array:
		error_occurred.emit("邮件列表格式错误")
		return
	for mail_data in mail_list:
		if mail_data is Dictionary:
			mails.append(MailData.from_server_data(mail_data))
		else:
			push_warning("[MailAPI] skip non-dict mail row: %s" % str(mail_data))

	mail_list_received.emit(mails)


func fetch_mail_list(token: String) -> void :
	var headers: = _auth_json_headers(token)
	var url: = _mail_api_root() + "/mail/list"
	if OS.is_debug_build():
		print("[MailAPI] GET ", url, " effective_base=", _mail_api_root())
	var done = func(result: int, response_code: int, body: PackedByteArray, resp_headers: PackedStringArray):
		process_mail_list_http_response(result, response_code, body, resp_headers)
	_request_once(url, headers, HTTPClient.METHOD_GET, "", done, "网络请求失败")


func fetch_mail_detail(mail_id: int, token: String) -> void :
	var headers: = _auth_json_headers(token)
	var done = func(result: int, response_code: int, body: PackedByteArray, _resp_headers: PackedStringArray):
		if result != HTTPRequest.RESULT_SUCCESS:
			error_occurred.emit(_http_transport_error_message(result))
			return
		if response_code != 200:
			error_occurred.emit("获取邮件详情失败（HTTP %d）" % response_code)
			return

		var data_any = _parse_json_mail_response(body, "mail/detail")
		if data_any == null:
			error_occurred.emit(_non_json_response_user_message(body))
			return
		if not data_any is Dictionary:
			error_occurred.emit("邮件数据格式错误")
			return
		var data: Dictionary = data_any
		if not data.get("success", false):
			error_occurred.emit(str(data.get("error", "未知错误")))
			return

		var mail_raw = data.get("mail", {})
		if not mail_raw is Dictionary:
			error_occurred.emit("邮件详情格式错误")
			return
		var mail = MailData.from_server_data(mail_raw)
		mail_detail_received.emit(mail)
	var url = _mail_api_root() + "/mail/detail/%d" % mail_id
	_request_once(url, headers, HTTPClient.METHOD_GET, "", done, "网络请求失败")


func claim_attachment(mail_id: int, token: String) -> void :
	var headers: = _auth_json_headers(token)

	var done = func(result: int, response_code: int, body: PackedByteArray, _resp_headers: PackedStringArray):
		if result != HTTPRequest.RESULT_SUCCESS:
			error_occurred.emit(_http_transport_error_message(result))
			return
		if response_code != 200:
			error_occurred.emit("领取附件失败（HTTP %d）" % response_code)
			return

		var data_any = _parse_json_mail_response(body, "mail/claim")
		if data_any == null:
			error_occurred.emit(_non_json_response_user_message(body))
			return
		if not data_any is Dictionary:
			error_occurred.emit("响应格式错误")
			return
		var data: Dictionary = data_any
		if not data.get("success", false):
			error_occurred.emit(str(data.get("error", "领取失败")))
			return

		var attachments = data.get("attachments", {})
		if not attachments is Dictionary:
			attachments = {}
		attachment_claimed.emit(mail_id, attachments)

	var url = _mail_api_root() + "/mail/claim/%d" % mail_id
	_request_once(url, headers, HTTPClient.METHOD_POST, "", done, "网络请求失败")


func fetch_unread_count(token: String) -> void :
	var headers: = _auth_json_headers(token)
	var done = func(result: int, response_code: int, body: PackedByteArray, _resp_headers: PackedStringArray):
		if result != HTTPRequest.RESULT_SUCCESS:
			return
		if response_code != 200:
			return

		var data_any = _parse_json_mail_response(body, "mail/unread")
		if data_any == null or not data_any is Dictionary:
			return
		var data: Dictionary = data_any
		if not data.get("success", false):
			return

		unread_count_received.emit(int(data.get("count", 0)))
	_request_once(_mail_api_root() + "/mail/unread", headers, HTTPClient.METHOD_GET, "", done, "网络请求失败")


func claim_all_attachments(token: String) -> void :
	var headers: = _auth_json_headers(token)

	var done = func(result: int, response_code: int, body: PackedByteArray, _resp_headers: PackedStringArray):
		if result != HTTPRequest.RESULT_SUCCESS:
			error_occurred.emit(_http_transport_error_message(result))
			return
		if response_code != 200:
			error_occurred.emit("一键领取失败（HTTP %d）" % response_code)
			return

		var data_any = _parse_json_mail_response(body, "mail/claim-all")
		if data_any == null:
			error_occurred.emit(_non_json_response_user_message(body))
			return
		if not data_any is Dictionary:
			error_occurred.emit("响应格式错误")
			return
		var data: Dictionary = data_any
		if not data.get("success", false):
			error_occurred.emit(str(data.get("error", "领取失败")))
			return

		var claimed = data.get("claimed", [])
		if claimed.is_empty():
			error_occurred.emit("没有可领取的邮件")
			return
		all_attachments_claimed.emit(claimed)

	_request_once(_mail_api_root() + "/mail/claim-all", headers, HTTPClient.METHOD_POST, "", done, "网络请求失败")


func finalize_claims(mail_ids: Array, token: String, operation_id: String = "") -> void :
	var headers: = _auth_json_headers(token)
	var body_dict = {"mailIds": mail_ids}
	if not operation_id.is_empty():
		body_dict["operationId"] = operation_id
	var body = JSON.stringify(body_dict)
	var done = func(result: int, response_code: int, response_body: PackedByteArray, _resp_headers: PackedStringArray):
		if result != HTTPRequest.RESULT_SUCCESS:
			finalize_claims_done.emit(false, _http_transport_error_message(result), {"updated": 0})
			return
		if response_code != 200:
			var error_text = "标记邮件失败（网络）"
			if response_code == 404 or response_code == 405:
				error_text = "服务端版本过旧，缺少 finalize-claims 接口。请更新服务端后再领取。"
			elif response_body.size() > 0:
				var err_json = JSON.new()
				if err_json.parse(response_body.get_string_from_utf8()) == OK:
					var err_data = err_json.data
					if err_data is Dictionary and err_data.has("error"):
						error_text = String(err_data.get("error", error_text))
			finalize_claims_done.emit(false, error_text, {"updated": 0})
			return
		var data_any = _parse_json_mail_response(response_body, "mail/finalize-claims")
		if data_any == null or not data_any is Dictionary:
			finalize_claims_done.emit(false, _non_json_response_user_message(response_body), {"updated": 0})
			return
		var data: Dictionary = data_any
		if not data.get("success", false):
			finalize_claims_done.emit(false, String(data.get("error", "标记邮件失败")), {"updated": 0})
			return
		var updated = int(data.get("updated", 0))
		var payload: = {"updated": updated}
		if data is Dictionary:
			if data.has("duplicate"):
				payload["duplicate"] = bool(data["duplicate"])
			if data.has("newGold"):
				payload["new_gold"] = int(data["newGold"])
			if data.has("newYuanbao"):
				payload["new_yuanbao"] = int(data["newYuanbao"])
			if data.has("newXianmoTotalScore"):
				payload["new_xianmo_total_score"] = int(data["newXianmoTotalScore"])
			var sd_any: Variant = data.get("saveData", data.get("save_data", null))
			if sd_any is Dictionary and not (sd_any as Dictionary).is_empty():
				payload["saveData"] = sd_any as Dictionary
		finalize_claims_done.emit(true, "", payload)
	var fail_signal = func():
		finalize_claims_done.emit(false, "标记邮件请求失败（请重试或重新登录）", {"updated": 0})
	_request_once(_mail_api_root() + "/mail/finalize-claims", headers, HTTPClient.METHOD_POST, body, done, "网络请求失败", fail_signal)


func delete_claimed_mails(token: String) -> void :
	var headers: = _auth_json_headers(token)
	var done = func(result: int, response_code: int, body: PackedByteArray, _resp_headers: PackedStringArray):
		if result != HTTPRequest.RESULT_SUCCESS:
			error_occurred.emit(_http_transport_error_message(result))
			return
		if response_code != 200:
			error_occurred.emit("删除邮件失败（HTTP %d）" % response_code)
			return

		var data_any = _parse_json_mail_response(body, "mail/delete-claimed")
		if data_any == null:
			error_occurred.emit(_non_json_response_user_message(body))
			return
		if not data_any is Dictionary:
			error_occurred.emit("响应格式错误")
			return
		var data: Dictionary = data_any
		if not data.get("success", false):
			error_occurred.emit(str(data.get("error", "删除失败")))
			return

		claimed_mails_deleted.emit(int(data.get("deleted", 0)))
	_request_once(_mail_api_root() + "/mail/delete-claimed", headers, HTTPClient.METHOD_POST, "", done, "网络请求失败")

func delete_mails_by_ids(mail_ids: Array, token: String) -> void :
	var ids: Array = []
	for x in mail_ids:
		var mid: = int(x)
		if mid > 0:
			ids.append(mid)
	if ids.is_empty():
		mail_delete_done.emit(false, 0, "无效的邮件ID")
		return
	var headers: = _auth_json_headers(token)
	var body: = JSON.stringify({"mailIds": ids})
	var done = func(result: int, response_code: int, response_body: PackedByteArray, _resp_headers: PackedStringArray):
		if result != HTTPRequest.RESULT_SUCCESS:
			mail_delete_done.emit(false, 0, _http_transport_error_message(result))
			return
		if response_code != 200:
			var err_text: = "删除邮件失败（HTTP %d）" % response_code
			if response_body.size() > 0:
				var ej: = JSON.new()
				if ej.parse(response_body.get_string_from_utf8()) == OK and ej.data is Dictionary:
					var ed: Dictionary = ej.data
					if ed.has("error"):
						err_text = String(ed.get("error", err_text))
			mail_delete_done.emit(false, 0, err_text)
			return
		var data_any = _parse_json_mail_response(response_body, "mail/delete")
		if data_any == null or not data_any is Dictionary:
			mail_delete_done.emit(false, 0, _non_json_response_user_message(response_body))
			return
		var data: Dictionary = data_any
		if not data.get("success", false):
			mail_delete_done.emit(false, 0, String(data.get("error", "删除失败")))
			return
		mail_delete_done.emit(true, int(data.get("deleted", 0)), "")
	var fail_signal = func():
		mail_delete_done.emit(false, 0, "删除邮件请求失败（请重试或重新登录）")
	_request_once(_mail_api_root() + "/mail/delete", headers, HTTPClient.METHOD_POST, body, done, "网络请求失败", fail_signal)

func send_pet_overflow_mail(token: String, pet_payload: Dictionary, operation_id: String = "") -> void :
	var headers: = _auth_json_headers(token)
	var body_dict: Dictionary = pet_payload.duplicate(true)
	if not operation_id.is_empty():
		body_dict["operationId"] = operation_id
	var body: = JSON.stringify(body_dict)
	var done = func(result: int, response_code: int, response_body: PackedByteArray, _resp_headers: PackedStringArray):
		if result != HTTPRequest.RESULT_SUCCESS:
			pet_overflow_mail_done.emit(false, _http_transport_error_message(result), {})
			return
		if response_code != 200:
			var err_text: = "宠物补发邮件失败（HTTP %d）" % response_code
			if response_body.size() > 0:
				var ej: = JSON.new()
				if ej.parse(response_body.get_string_from_utf8()) == OK and ej.data is Dictionary:
					var ed: Dictionary = ej.data
					if ed.has("error"):
						err_text = String(ed.get("error", err_text))
			pet_overflow_mail_done.emit(false, err_text, {})
			return
		var data_any = _parse_json_mail_response(response_body, "mail/pet-overflow")
		if data_any == null or not data_any is Dictionary:
			pet_overflow_mail_done.emit(false, _non_json_response_user_message(response_body), {})
			return
		var data: Dictionary = data_any
		if not data.get("success", false):
			pet_overflow_mail_done.emit(false, String(data.get("error", "宠物补发邮件失败")), data)
			return
		pet_overflow_mail_done.emit(true, "", data)
	var fail_signal = func():
		pet_overflow_mail_done.emit(false, "宠物补发邮件请求失败（请重试或重新登录）", {})
	_request_once(_mail_api_root() + "/mail/pet-overflow", headers, HTTPClient.METHOD_POST, body, done, "网络请求失败", fail_signal)
