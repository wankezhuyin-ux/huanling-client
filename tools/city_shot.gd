extends SceneTree
# 主城截图 + 瀑布自检（开发期用，不随包发）
#
# 用法：
#   Godot --path . --resolution 720x1280 --script tools/city_shot.gd \
#     -- --user=chattest --pass=chat123 --out=/tmp/city_falls.png

var _user := "chattest"
var _pass := "chat123"
var _out := "/tmp/city_falls.png"


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
		printerr("[city] 载入 main.tscn 失败")
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


func _start() -> void:
	var root_node := get_root()
	var login := _find_by_script(root_node, "login_ui.gd")
	for i in 600:
		if login != null:
			break
		await process_frame
		login = _find_by_script(root_node, "login_ui.gd")
	if login == null:
		printerr("[city] 没找到登录界面")
		quit(1)
		return
	for i in 3600:
		await process_frame
		if bool(login.get("_version_check_done")) and bool(login.get("_version_allows_login")):
			break
	(login.get("login_username") as LineEdit).text = _user
	(login.get("login_password") as LineEdit).text = _pass
	login.call("_on_login_pressed")
	print("[city] 已提交登录 ", _user)

	var main_ui: Node = null
	for i in 1800:
		await process_frame
		main_ui = _find_by_script(root_node, "ink_home.gd")
		if main_ui != null:
			break
	if main_ui == null:
		printerr("[city] 没进主界面")
		quit(2)
		return
	var d = main_ui.get("startup_dialog")
	if d != null and is_instance_valid(d):
		var pressed := _press_button_with(d, ["进入游戏", "进入", "确定"])
		print("[city] 启动弹窗按钮: ", pressed if not pressed.is_empty() else "(没找到)")
	for i in 600:
		await process_frame
		var bn0 = main_ui.get("bottom_nav")
		if bn0 is CanvasItem and (bn0 as CanvasItem).visible:
			break
	main_ui.call("_show_view", "city")

	var city: Node = null
	for i in 2400:
		await process_frame
		city = _find_by_script(root_node, "city_ui.gd")
		if city != null:
			break
	if city == null:
		printerr("[city] 没进主城")
		quit(2)
		return
	city.call("_hide_content")
	await create_timer(1.0).timeout
	var bd = city.get("_backdrop")
	if bd is CanvasItem:
		(bd as CanvasItem).visible = false
	var mc = main_ui.get("main_content")
	if mc is CanvasItem and not (mc as CanvasItem).visible:
		(mc as CanvasItem).visible = true
	_hide_popup_windows()
	await create_timer(3.0).timeout

	# ---- 瀑布自检 ----
	var fx := _find_by_script(root_node, "city_fx.gd")
	if fx == null:
		printerr("[city] 没找到 CityFx")
	else:
		var falls: Array = fx.get("_falls_nodes")
		print("[city] 瀑布层数=", falls.size())
		for layer in range(falls.size()):
			var segs: Array = falls[layer]["segs"]
			var mats: Array = falls[layer]["mats"]
			print("[city] layer", layer, " 片数=", segs.size(), " 材质数=", mats.size(),
				" 材质各不相同=", _all_distinct(mats))
			for k in range(segs.size()):
				var r: Control = segs[k]
				var band := Vector3.ZERO
				if k < mats.size() and mats[k] is ShaderMaterial:
					band = (mats[k] as ShaderMaterial).get_shader_parameter("band")
				print("[city]   片", k, " y=", "%0.1f" % r.position.y,
					" h=", "%0.1f" % r.size.y, " band=", band,
					" 可见=", r.visible, " alpha=", "%0.2f" % r.modulate.a)

	await _save(_out)
	quit(0)


func _all_distinct(mats: Array) -> bool:
	var seen := {}
	for m in mats:
		seen[m] = true
	return seen.size() == mats.size()


func _save(path: String) -> void:
	_hide_popup_windows()
	await process_frame
	await process_frame
	var img := get_root().get_texture().get_image()
	if img == null:
		printerr("[city] 拿不到画面")
		return
	var e := img.save_png(path)
	print("[city] save_png err=", e, " size=", img.get_width(), "x", img.get_height(), " -> ", path)
