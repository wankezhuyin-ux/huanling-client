extends SceneTree
# 启动页 / 登录页截图自检（开发期用，不随包发）
#
# 一次跑出三张图：
#   1) 登录页（书法标题 + 无 logo）
#   2) 启动加载页（logo 自转）— 第 1 帧
#   3) 启动加载页 — 第 2 帧（用来对比 logo 角度，确认真的在转）
#
# 用法：
#   Godot --path . --resolution 720x1280 --script tools/startup_shot.gd \
#     -- --out=/tmp/login.png --out2=/tmp/load1.png --out3=/tmp/load2.png

var _out := "/tmp/login_new.png"
var _out2 := "/tmp/load_a.png"
var _out3 := "/tmp/load_b.png"


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out = a.substr(6)
		elif a.begins_with("--out2="):
			_out2 = a.substr(7)
		elif a.begins_with("--out3="):
			_out3 = a.substr(7)
	var scene: PackedScene = load("res://main.tscn")
	if scene == null:
		printerr("[shot] 载入 main.tscn 失败")
		quit(1)
		return
	get_root().add_child(scene.instantiate())
	_start.call_deferred()


func _walk(node: Node, out: Array) -> void:
	out.append(node)
	for c in node.get_children():
		_walk(c, out)


func _find_by_script(root_node: Node, script_name: String) -> Node:
	var all: Array = []
	_walk(root_node, all)
	for n in all:
		var sc = n.get_script()
		if sc != null and str(sc.resource_path).ends_with(script_name):
			return n
	return null


func _save(path: String) -> void:
	await process_frame
	await process_frame
	var img := get_root().get_texture().get_image()
	if img == null:
		printerr("[shot] 拿不到画面")
		return
	print("[shot] save err=", img.save_png(path), " -> ", path, " ", img.get_width(), "x", img.get_height())


func _start() -> void:
	var root_node := get_root()
	var login: Node = null
	for i in 900:
		await process_frame
		login = _find_by_script(root_node, "login_ui.gd")
		if login != null:
			break
	if login == null:
		printerr("[shot] 没找到登录界面")
		quit(1)
		return
	# 版本门禁会去拉 manifest；没有服务器时也要能出图，最多等 6 秒
	for i in 360:
		await process_frame
		if bool(login.get("_version_check_done")):
			break
	await create_timer(1.2).timeout
	await _save(_out)

	# 启动加载页：直接让 main 把 overlay 建出来，再把进度拨到 42%
	var main := _find_by_script(root_node, "main.gd")
	if main == null:
		printerr("[shot] 没找到 main.gd")
		quit(2)
		return
	main.call("_show_loading_overlay")
	var bar = main.get("_loading_progress_bar")
	if bar != null:
		(bar as ProgressBar).value = 0.42
	var logo = main.get("_loading_logo")
	if logo != null:
		print("[shot] logo size=", (logo as Control).size, " pivot=", (logo as Control).pivot_offset)
	await create_timer(0.5).timeout
	await _save(_out2)
	await create_timer(0.42).timeout
	if logo != null:
		print("[shot] 第二帧 logo rotation=", (logo as Control).rotation)
	await _save(_out3)
	print("[shot] 完成")
	quit(0)
