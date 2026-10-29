class_name GameServerConfig
extends RefCounted

const LOCAL_OVERRIDE_PATH: = "res://local_server_override.json"
static var _override_cache: Dictionary = {}
static var _override_loaded: bool = false









const API_PUBLIC_HOST: = "127.0.0.1"

const API_HTTP_PORT: = 3000

const CHAT_HTTP_PORT: = 3001

static func _load_local_override() -> Dictionary:
	if _override_loaded:
		return _override_cache
	_override_loaded = true
	_override_cache = {}
	if not FileAccess.file_exists(LOCAL_OVERRIDE_PATH):
		return _override_cache
	var file: = FileAccess.open(LOCAL_OVERRIDE_PATH, FileAccess.READ)
	if file == null:
		push_warning("[GameServerConfig] 无法打开本地覆盖配置: %s" % LOCAL_OVERRIDE_PATH)
		return _override_cache
	var text: = file.get_as_text()
	file.close()
	var json: = JSON.new()
	if json.parse(text) != OK:
		push_warning("[GameServerConfig] 本地覆盖配置 JSON 解析失败: %s" % LOCAL_OVERRIDE_PATH)
		return _override_cache
	var data = json.get_data()
	if data is Dictionary:
		_override_cache = data.duplicate(true)
		print("[GameServerConfig] 已启用本地测试服覆盖: ", _override_cache)
	return _override_cache

static func _override_string(key: String, fallback: String) -> String:
	var data: = _load_local_override()
	var value: = String(data.get(key, fallback)).strip_edges()
	return value if not value.is_empty() else fallback

static func _override_int(key: String, fallback: int) -> int:
	var data: = _load_local_override()
	return int(data.get(key, fallback))

## Web 版是否走「同源」：直接用当前网页的 scheme+host，不写死任何域名/端口。
##
## 为什么需要：网页版是 https 页面，如果 pck 里写死 http://IP:3000，浏览器会按混合
## 内容直接拦掉请求，游戏启动就弹「无法连接游戏服务器」。而且隧道/域名一变就得重新导出。
## 走同源后 nginx 负责把 /api/、/updates/ 反代到本机 3000/3001，地址永远正确。
static var _origin_cache: String = ""
static var _origin_loaded: bool = false

static func _same_origin_enabled() -> bool:
	return bool(_load_local_override().get("same_origin", false))


static func _same_origin_base() -> String:
	if _origin_loaded:
		return _origin_cache
	_origin_loaded = true
	_origin_cache = ""
	if not _same_origin_enabled():
		return _origin_cache
	if not OS.has_feature("web"):
		return _origin_cache
	# 只在 web 导出里取 location.origin。用 Engine.get_singleton 而不是直接写
	# JavaScriptBridge.eval(...)：后者在安卓/iOS 导出里是未声明标识符，会导致
	# 整个脚本编译失败。
	var js_bridge: Object = Engine.get_singleton("JavaScriptBridge")
	if js_bridge == null:
		return _origin_cache
	var origin = js_bridge.call("eval", "window.location.origin")
	if origin is String:
		var text: = String(origin).strip_edges()
		while text.ends_with("/"):
			text = text.substr(0, text.length() - 1)
		_origin_cache = text
	if _origin_cache.is_empty():
		push_warning("[GameServerConfig] 同源地址获取失败，回退到配置里的固定地址")
	else:
		print("[GameServerConfig] 使用同源地址: ", _origin_cache)
	return _origin_cache


static func _scheme() -> String:
	return _override_string("scheme", "http")

static func api_host() -> String:
	return _override_string("api_host", API_PUBLIC_HOST)

static func api_port() -> int:
	return _override_int("api_port", API_HTTP_PORT)

static func chat_port() -> int:
	return _override_int("chat_port", CHAT_HTTP_PORT)


static func api_base() -> String:
	var origin: = _same_origin_base()
	if not origin.is_empty():
		return origin + "/api"
	return "%s://%s:%d/api" % [_scheme(), api_host(), api_port()]


static func updates_manifest_url() -> String:
	var override_manifest: = _override_string("manifest_url", "")
	if not override_manifest.is_empty():
		return override_manifest
	var origin: = _same_origin_base()
	if not origin.is_empty():
		# 同源：nginx 把 /updates/ 反代到游戏服 3000
		return origin + "/updates/manifest.json"
	# 主界面的在线检测（main_ui._main_ui_periodic_online_check）直接用这个地址探活。
	# 原来少了 :端口，会打到 80 端口（本服没有监听），每次都判成断网 → 弹「正在自动重连」。
	return "%s://%s:%d/updates/manifest.json" % [_scheme(), api_host(), api_port()]


static func updates_manifest_url_candidates() -> Array[String]:
	var out: Array[String] = []
	out.append(updates_manifest_url())
	var origin: = _same_origin_base()
	if not origin.is_empty():
		var same_origin_alt: = origin + "/updates/manifest.json"
		if same_origin_alt != updates_manifest_url() and not out.has(same_origin_alt):
			out.append(same_origin_alt)
		return out
	var alt: = "%s://%s:%d/updates/manifest.json" % [_scheme(), api_host(), api_port()]
	if alt != updates_manifest_url() and not out.has(alt):
		out.append(alt)
	return out


static func chat_service_root() -> String:
	var origin: = _same_origin_base()
	if not origin.is_empty():
		return origin
	return "%s://%s:%d" % [_scheme(), api_host(), chat_port()]


static func main_service_root() -> String:
	var origin: = _same_origin_base()
	if not origin.is_empty():
		return origin
	return "%s://%s:%d" % [_scheme(), api_host(), api_port()]


static func connectivity_fallback_url() -> String:
	var origin: = _same_origin_base()
	if not origin.is_empty():
		return origin + "/api/ranking"
	return "%s://%s:%d/api/ranking" % [_scheme(), api_host(), api_port()]


static func api_http_fallback_base() -> String:
	return api_base()

static func main_http_fallback_root() -> String:
	return "%s://%s:%d" % [_scheme(), api_host(), api_port()]

static func chat_http_fallback_root() -> String:
	return "%s://%s:%d" % [_scheme(), api_host(), chat_port()]


static func updates_manifest_http_same_host_url() -> String:
	return updates_manifest_url()

static func updates_manifest_ip_http_url() -> String:
	return updates_manifest_url()
