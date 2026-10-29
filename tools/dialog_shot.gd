extends SceneTree
# 启动弹窗 / 登录页截图自检（开发期用，不随包发）
#
# 一次跑出三张图：
#   1) 登录页（新底图 + 文字标题）
#   2) 「欢迎回来」面板（金属包边）
#   3) 「离线奖励」面板（金属包边）
#
# 用法：
#   Godot --path . --resolution 720x1280 --script tools/dialog_shot.gd \
#     -- --user=metaldemo --pass=metal123 --out=/tmp/login.png \
#        --out2=/tmp/welcome.png --out3=/tmp/offline.png

var _user := "metaldemo"
var _pass := "metal123"
var _out := "/tmp/login_metal.png"
var _out2 := "/tmp/welcome_metal.png"
var _out3 := "/tmp/offline_metal.png"


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--user="):
			_user = a.substr(7)
		elif a.begins_with("--pass="):
			_pass = a.substr(7)
		elif a.begins_with("--out="):
			_out = a.substr(6)
		elif a.begins_with("--out2="):
			_out2 = a.substr(7)
		elif a.begins_with("--out3="):
			_out3 = a.substr(7)
	var scene: PackedScene = load("res://main.tscn")
	if scene == null:
		printerr("[dlg] 载入 main.tscn 失败")
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


func _find_main_ui(root_node: Node) -> Node:
	var n := _find_by_script(root_node, "ink_home.gd")
	if n == null:
		n = _find_by_script(root_node, "main_ui.gd")
	return n


func _press_any(keywords: Array) -> String:
	var all: Array = []
	_walk(get_root(), all)
	for n in all:
		if n is Button and (n as Button).visible and not (n as Button).disabled:
			var txt := str((n as Button).text)
			for k in keywords:
				if txt.find(str(k)) >= 0:
					(n as Button).pressed.emit()
					return txt
	return ""


func _visible_windows() -> Array:
	var all: Array = []
	_walk(get_root(), all)
	var out: Array = []
	for n in all:
		if n is Window and n != get_root() and (n as Window).visible:
			out.append(n)
	return out


func _save(path: String) -> void:
	await process_frame
	await process_frame
	var img := get_root().get_texture().get_image()
	if img == null:
		printerr("[dlg] 拿不到画面")
		return
	var e := img.save_png(path)
	print("[dlg] save_png err=", e, " -> ", path, " ", img.get_width(), "x", img.get_height())


func _start() -> void:
	var root_node := get_root()
	var login := _find_by_script(root_node, "login_ui.gd")
	for i in 600:
		if login != null:
			break
		await process_frame
		login = _find_by_script(root_node, "login_ui.gd")
	if login == null:
		printerr("[dlg] 没找到登录界面")
		quit(1)
		return
	for i in 3600:
		await process_frame
		if bool(login.get("_version_check_done")) and bool(login.get("_version_allows_login")):
			break

	# ① 登录页：等标题/背景渲染稳定再截
	await create_timer(1.2).timeout
	await _save(_out)

	(login.get("login_username") as LineEdit).text = _user
	(login.get("login_password") as LineEdit).text = _pass
	login.call("_on_login_pressed")
	print("[dlg] 已提交登录 ", _user)

	var main_ui: Node = null
	for i in 1800:
		await process_frame
		main_ui = _find_main_ui(root_node)
		if main_ui != null:
			break
	if main_ui == null:
		printerr("[dlg] 没进主界面")
		quit(2)
		return
	print("[dlg] 主界面就绪")

	# 把真实的启动弹窗（离线奖励 → 欢迎回来）点掉，后面再手动重建来截图
	var misses := 0
	for round_i in 30:
		await create_timer(0.4).timeout
		var hit := _press_any(["领取奖励", "进入游戏", "开始游戏", "创建角色", "确定", "确认"])
		if hit == "":
			misses += 1
			if misses >= 20:
				break
			continue
		misses = 0
		print("[dlg] 关闭启动弹窗：", hit)
	for w in _visible_windows():
		(w as Window).queue_free()
	await create_timer(0.6).timeout

	# ② 「欢迎回来」面板
	main_ui.set("startup_dialog", null)
	main_ui.call("_show_login_dialog")
	await create_timer(1.4).timeout
	var welcome = main_ui.get("startup_dialog")
	if welcome != null and is_instance_valid(welcome):
		print("[dlg] 欢迎回来面板 size=", (welcome as Window).size)
		var panel = (welcome as Window).get_node_or_null("MainPanel")
		print("[dlg]   面板 rect=", (panel as Control).get_global_rect() if panel is Control else "null",
			" 金属框=", (panel as Node).get_node_or_null("MetalFrame") != null if panel != null else false)
	else:
		printerr("[dlg] 欢迎回来面板没弹出来")
	await _save(_out2)

	# ③ 「离线奖励」面板
	if welcome != null and is_instance_valid(welcome):
		(welcome as Window).queue_free()
	main_ui.set("startup_dialog", null)
	await create_timer(0.4).timeout
	main_ui.call("_on_post_login_offline_rewards_ready", 0.3, 0, 4540, {}, 0, false,
		{"playerLevelBefore": 1200, "playerLevelAfter": 1200,
		 "petLevelBefore": 1500, "petLevelAfter": 1500, "petName": "变异阿努"})
	await create_timer(1.4).timeout
	for w in _visible_windows():
		print("[dlg] 离线面板 size=", (w as Window).size, " title=", (w as Window).title)
	await _save(_out3)
	print("[dlg] 完成")
	quit(0)
