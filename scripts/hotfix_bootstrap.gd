extends Node



const PATCH_FILE: = "user://patches/hotfix.pck"
const PATCH_VERSION_FILE: = "user://patch_version.txt"
const MAIN_GD_PATH: = "res://main.gd"
# 底包版本号的单一来源：**绝不能**为了取版本去 load(main.gd)，
# 那会把 ui/main_ui.gd 提前编译进缓存，pck 就再也换不掉了。
const BUILD_VERSION: = preload("res://scripts/client_version.gd")
# 必须在 pck 挂载后强制刷新的脚本：编译 main.gd 时解析 class_name MainUI，
# 会把底包那份 main_ui.gd 拉进资源缓存，之后 pck 里的新版永远不生效。
const REFRESH_AFTER_PATCH: = [
	"res://main.gd",
	"res://ui/main_ui.gd",
	"res://ui/ink_home.gd",
]

static var _patch_loaded: bool = false
static var _restart_after_stale_patch: bool = false


func _init() -> void :
	_try_load_patch_early()


func _ready() -> void :
	if _restart_after_stale_patch:
		print("[HotfixBootstrap] 旧热更已清理，重启以加载正确底包版本…")
		OS.set_restart_on_exit(true)
		get_tree().quit()
		return
	if not _patch_loaded:
		_try_load_patch_early()


static func _try_load_patch_early() -> void :
	if _patch_loaded:
		return
	if OS.has_feature("editor"):
		return
	if not FileAccess.file_exists(PATCH_FILE):
		return

	var apk_base: = str(BUILD_VERSION.VALUE).strip_edges()
	var local_patch_ver: = _read_patch_version_file()
	if not local_patch_ver.is_empty() and not apk_base.is_empty():
		var patch_base: = _extract_base_version(local_patch_ver)
		if patch_base != apk_base:
			push_warning(
				"[HotfixBootstrap] 本地 patch 版本(%s) 与底包(%s) 不匹配，清理旧热更"
				%[local_patch_ver, apk_base]
			)
			clear_local_patch_files(true)
			return

	var loaded: = ProjectSettings.load_resource_pack(PATCH_FILE, true)
	if not loaded:
		push_warning("[HotfixBootstrap] 本地 patch 存在但加载失败: %s" % PATCH_FILE)
		clear_local_patch_files(true)
		return

	var effective_base: = _read_main_gd_client_version(true)
	if not apk_base.is_empty() and not effective_base.is_empty() and effective_base != apk_base:
		push_warning(
			"[HotfixBootstrap] patch 覆盖了底包版本(%s→%s)，清理旧热更并重启"
			%[apk_base, effective_base]
		)
		clear_local_patch_files(true)
		_patch_loaded = false
		_restart_after_stale_patch = true
		return

	_refresh_cached_scripts_after_patch()

	_patch_loaded = true
	print("[HotfixBootstrap] 已加载本地 patch: %s" % PATCH_FILE)


static func _read_main_gd_client_version(ignore_cache: bool) -> String:
	var script: Variant
	if ignore_cache:
		script = ResourceLoader.load(MAIN_GD_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	else:
		script = load(MAIN_GD_PATH)
	if script is GDScript:
		var constants: Dictionary = script.get_script_constant_map()
		return str(constants.get("CLIENT_VERSION", "")).strip_edges()
	return ""


static func _read_patch_version_file() -> String:
	if not FileAccess.file_exists(PATCH_VERSION_FILE):
		return ""
	var f: = FileAccess.open(PATCH_VERSION_FILE, FileAccess.READ)
	if f == null:
		return ""
	return f.get_as_text().strip_edges()


static func _extract_base_version(version: String) -> String:
	var parts: PackedStringArray = version.strip_edges().split(".")
	if parts.size() >= 3:
		return parts[0] + "." + parts[1] + "." + parts[2]
	return version.strip_edges()


static func clear_local_patch_files(include_download: bool = true) -> bool:
	var cleared: = false
	if FileAccess.file_exists(PATCH_FILE):
		DirAccess.remove_absolute(PATCH_FILE)
		cleared = true
	if include_download and FileAccess.file_exists("user://patches/hotfix.pck.download"):
		DirAccess.remove_absolute("user://patches/hotfix.pck.download")
		cleared = true
	if FileAccess.file_exists(PATCH_VERSION_FILE):
		DirAccess.remove_absolute(PATCH_VERSION_FILE)
		cleared = true
	if cleared:
		_patch_loaded = false
		print("[HotfixBootstrap] 已清理本地 patch 文件")
	return cleared


static func _refresh_cached_scripts_after_patch() -> void:
	for path in REFRESH_AFTER_PATCH:
		if not ResourceLoader.exists(path):
			continue
		var reloaded: Variant = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
		if reloaded == null:
			push_warning("[HotfixBootstrap] 刷新脚本失败，继续用底包版本: %s" % path)
		else:
			print("[HotfixBootstrap] 已用 patch 版本替换: %s" % path)
