extends SceneTree
# 周末双倍经验战斗日志自检（开发期用，不随包发）
#
# 用法：
#   Godot --path . --resolution 720x1280 --script tools/weekend_log_check.gd \
#     -- --user=probe1 --pass=probe1123 --out=/tmp/weekend_log.png
#
# 验证三件事：
#   1. 服务端回包带 weekendExpBonus=1.0 时，战斗日志出现「周末双倍经验」一行
#   2. 同一个结算窗口内重复调用不会重复刷
#   3. weekendExpBonus=0.0（非周末）时不出这一行

var _user := "probe1"
var _pass := "probe1123"
var _out := "/tmp/weekend_log.png"


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--user="):
			_user = a.substr(7)
		elif a.begins_with("--pass="):
			_pass = a.substr(7)
		elif a.begins_with("--out="):
			_out = a.substr(6)
	var scene: PackedScene = load("res://main.tscn")
	if scene == null:
		printerr("[wk] 载入 main.tscn 失败")
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


func _press_button_with(root_node: Node, keywords: Array) -> String:
	var all: Array = []
	_walk(root_node, all)
	for n in all:
		if n is Button and (n as Button).visible and not (n as Button).disabled:
			var txt := str((n as Button).text)
			for k in keywords:
				if txt.find(str(k)) >= 0:
					(n as Button).pressed.emit()
					return txt
	return ""


func _hide_popup_windows() -> void:
	var all: Array = []
	_walk(get_root(), all)
	for n in all:
		if n is Window and n != get_root() and (n as Window).visible:
			(n as Window).hide()


func _count_weekend(logs: Array) -> int:
	var n := 0
	for line in logs:
		if str(line).find("周末双倍经验") >= 0:
			n += 1
	return n


func _start() -> void:
	var root_node := get_root()
	var login := _find_by_script(root_node, "login_ui.gd")
	for i in 600:
		if login != null:
			break
		await process_frame
		login = _find_by_script(root_node, "login_ui.gd")
	if login == null:
		printerr("[wk] 没找到登录界面")
		quit(1)
		return
	for i in 3600:
		await process_frame
		if bool(login.get("_version_check_done")) and bool(login.get("_version_allows_login")):
			break
	(login.get("login_username") as LineEdit).text = _user
	(login.get("login_password") as LineEdit).text = _pass
	login.call("_on_login_pressed")
	print("[wk] 已提交登录 ", _user)

	var home: Node = null
	for i in 1800:
		await process_frame
		home = _find_by_script(root_node, "ink_home.gd")
		if home != null:
			break
	if home == null:
		printerr("[wk] 没进主界面")
		quit(2)
		return
	var d = home.get("startup_dialog")
	if d != null and is_instance_valid(d):
		_press_button_with(d, ["进入游戏", "进入", "确定"])
	for i in 600:
		await process_frame
		var bn = home.get("bottom_nav")
		if bn is CanvasItem and (bn as CanvasItem).visible:
			break

	var gm: Node = _find_by_script(root_node, "game_manager.gd")
	if gm == null:
		printerr("[wk] 找不到 GameManager 节点")
		quit(3)
		return
	var bs = gm.get("battle_system")
	if bs == null:
		printerr("[wk] battle_system 还没建")
		quit(3)
		return
	bs.call("clear_log")

	# ---- 场景 1：周末生效（服务端权威字段 = 1.0）----
	gm.call("_begin_field_exp_settlement_window")
	gm.call("_log_field_battle_exp_bonuses_once", {"weekendExpBonus": 1.0})
	await create_timer(0.2).timeout
	print("[wk] 场景1 计数=", _count_weekend(bs.call("get_battle_log")))

	# 同窗口重复调用：应当不再增加
	gm.call("_log_field_battle_exp_bonuses_once", {"weekendExpBonus": 1.0})
	await create_timer(0.2).timeout
	print("[wk] 场景2(同窗口重复) 计数=", _count_weekend(bs.call("get_battle_log")))

	# ---- 场景 3：非周末（字段 = 0.0）----
	bs.call("clear_log")
	gm.call("_begin_field_exp_settlement_window")
	gm.call("_log_field_battle_exp_bonuses_once", {"weekendExpBonus": 0.0})
	await create_timer(0.2).timeout
	print("[wk] 场景3(非周末) 计数=", _count_weekend(bs.call("get_battle_log")))

	# ---- 场景 4：旧服务端不回字段（-1）→ 按本机星期兜底 ----
	bs.call("clear_log")
	gm.call("_begin_field_exp_settlement_window")
	gm.call("_log_field_battle_exp_bonuses_once", {})
	await create_timer(0.2).timeout
	var wd := int(Time.get_datetime_dict_from_system().get("weekday", 0))
	print("[wk] 本机 weekday=", wd, "（0=周日） 场景4(缺字段兜底) 计数=",
		_count_weekend(bs.call("get_battle_log")))

	print("[wk] 最近日志：")
	for line in bs.call("get_battle_log"):
		print("[wk]   ", line)

	await _save(_out)
	quit(0)


func _save(path: String) -> void:
	_hide_popup_windows()
	await process_frame
	await process_frame
	var img := get_root().get_texture().get_image()
	if img == null:
		printerr("[wk] 拿不到画面")
		return
	var e := img.save_png(path)
	print("[wk] save_png err=", e, " -> ", path)
