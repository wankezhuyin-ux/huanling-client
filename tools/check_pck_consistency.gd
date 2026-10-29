extends SceneTree
# 校验热更 pck 内部的脚本是否自洽（不参与游戏运行，也不随热更发给玩家）。
# 用法：
#   Godot --headless --path . --script tools/check_pck_consistency.gd -- --pck=/abs/path/hotfix-android.pck
#
# 背景：2.5.9.21 在手机上黑屏，logcat 报
#   SCRIPT ERROR: Compile Error: Identifier not found: _startup_offline_pending
#   at: res://ui/ink_home.gd:32
# 本地源码能编译，说明包里的 main_ui.gd 和 ink_home.gd 版本不一致。
# 这个脚本把 pck 挂上来，直接读包内的文件内容，和磁盘源码逐一对 hash。

const CHECK_FILES := [
	"ui/main_ui.gd",
	"ui/ink_home.gd",
	"scripts/player.gd",
	"scripts/network.gd",
	"scripts/game_manager.gd",
]

# 关键符号必须同时存在，任一侧缺失就是版本错配
const REQUIRED_SYMBOLS := [
	["ui/main_ui.gd", "_startup_offline_pending"],
	["ui/ink_home.gd", "_startup_offline_pending"],
	["scripts/player.gd", "coerce_bool"],
	["scripts/network.gd", "_is_high_priority_request"],
	["scripts/network.gd", "economy_offline_claim"],
]


func _initialize() -> void:
	var pck_path := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--pck="):
			pck_path = a.substr(6)
	if pck_path.is_empty():
		printerr("[check] 缺少 --pck=")
		quit(2)
		return
	if not FileAccess.file_exists(pck_path):
		printerr("[check] 找不到 pck: %s" % pck_path)
		quit(2)
		return

	var loaded: bool = ProjectSettings.load_resource_pack(pck_path, true)
	print("[check] load_resource_pack = %s" % str(loaded))
	if not loaded:
		quit(2)
		return

	var bad := 0
	print("[check] ---- 包内脚本 vs 磁盘源码 ----")
	for rel_v in CHECK_FILES:
		var rel: String = str(rel_v)
		var res_path: String = "res://" + rel
		var disk_path: String = ProjectSettings.globalize_path("res://") + rel
		var packed := _read_text(res_path)
		var disk := _read_disk(disk_path)
		var same: bool = packed == disk
		print("[check] %-24s packed=%6d disk=%6d %s"
			% [rel, packed.length(), disk.length(), "SAME" if same else "!!! DIFF"])
		if not same:
			bad += 1
			print("[check]     packed_head: %s" % packed.substr(0, 120).replace("\n", " | "))
			print("[check]     disk_head  : %s" % disk.substr(0, 120).replace("\n", " | "))

	print("[check] ---- 关键符号存在性（包内） ----")
	for pair in REQUIRED_SYMBOLS:
		var rel: String = pair[0]
		var sym: String = pair[1]
		var body := _read_text("res://" + rel)
		var has: bool = body.contains(sym)
		print("[check] %-24s %-28s %s" % [rel, sym, "OK" if has else "!!! MISSING"])
		if not has:
			bad += 1

	print("[check] 结论：%s（问题项 %d）" % ["PASS" if bad == 0 else "FAIL", bad])
	quit(0 if bad == 0 else 1)


func _read_text(res_path: String) -> String:
	if not FileAccess.file_exists(res_path):
		return ""
	var f := FileAccess.open(res_path, FileAccess.READ)
	if f == null:
		return ""
	return f.get_as_text()


func _read_disk(abs_path: String) -> String:
	if not FileAccess.file_exists(abs_path):
		return ""
	var f := FileAccess.open(abs_path, FileAccess.READ)
	if f == null:
		return ""
	return f.get_as_text()
