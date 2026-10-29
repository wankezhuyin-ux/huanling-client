extends SceneTree
# 「创建角色」面板专用截图/自检脚本（只在开发期用，不随包发出去）
#
# 流程：登录一个「还没建角色」的账号 → 等创建角色面板弹出 → 填名字核验 → 截图
#      → 点创建 → 再截一张主界面，确认名字/形象真的生效。
#
# 用法：
#   Godot --path . --resolution 720x1280 --script tools/ui_shot_create.gd \
#     -- --user=uidemo --pass=uidemo123 --name=青云子 --out=/tmp/create.png --out2=/tmp/after.png

var _user := "uidemo"
var _pass := "uidemo123"
var _name := "青云子"
var _out := "/tmp/create.png"
var _out2 := "/tmp/after.png"


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--user="):
			_user = a.substr(7)
		elif a.begins_with("--pass="):
			_pass = a.substr(7)
		elif a.begins_with("--name="):
			_name = a.substr(7)
		elif a.begins_with("--out="):
			_out = a.substr(6)
		elif a.begins_with("--out2="):
			_out2 = a.substr(7)
	# --script 模式不会自动加载主场景，必须手动实例化（同 ui_shot.gd）
	var scene: PackedScene = load("res://main.tscn")
	if scene == null:
		printerr("[shot] 载入 main.tscn 失败")
		quit(1)
		return
	var root_node: Node = scene.instantiate()
	get_root().add_child(root_node)
	_start.call_deferred()


func _walk(node: Node, out: Array) -> void:
	out.append(node)
	for c in node.get_children():
		_walk(c, out)


func _find_by_script(root_node: Node, script_name: String) -> Node:
	var nodes: Array = []
	_walk(root_node, nodes)
	for n in nodes:
		var sc = n.get_script()
		if sc != null and str(sc.resource_path).ends_with(script_name):
			return n
	return null


func _start() -> void:
	var root_node := get_root()
	var login := _find_by_script(root_node, "login_ui.gd")
	for i in 600:
		if login != null:
			break
		await process_frame
		login = _find_by_script(root_node, "login_ui.gd")
	if login == null:
		printerr("[shot] 没找到登录界面")
		quit(1)
		return
	for i in 3600:
		await process_frame
		if bool(login.get("_version_check_done")) and bool(login.get("_version_allows_login")):
			break
	var ue = login.get("login_username")
	var pe = login.get("login_password")
	ue.text = _user
	pe.text = _pass
	login.call("_on_login_pressed")
	print("[shot] 已提交登录 ", _user)

	var main_ui: Node = null
	for i in 1800:
		await process_frame
		# 线上首页用 ink_home.gd（extends main_ui.gd 的皮），两个都要认
		main_ui = _find_by_script(root_node, "ink_home.gd")
		if main_ui == null:
			main_ui = _find_by_script(root_node, "main_ui.gd")
		if main_ui != null:
			break
	if main_ui == null:
		printerr("[shot] 没进主界面")
		quit(1)
		return
	print("[shot] 主界面就绪")

	# 等创建角色面板（离线结算/延迟建窗，轮询 30 秒）
	# 注意：「欢迎回来」等启动弹窗也走 startup_dialog，不能只看它非空，
	# 得用创建面板专有的名字输入框（CharacterNameInput）来判定。
	var dialog: Window = null
	for i in 1800:
		await process_frame
		var d = main_ui.get("startup_dialog")
		if d != null and is_instance_valid(d) and d.find_child("CharacterNameInput", true, false) != null:
			dialog = d
			break
	if dialog == null:
		printerr("[shot] 没有弹出创建角色面板（可能这个账号已经建过角色）")
		quit(2)
		return
	await create_timer(0.8).timeout
	var keys_log: Array = []
	_walk(dialog, keys_log)
	print("[shot] 面板节点数=", keys_log.size())
	await _save_window(dialog, _out)

	# 填名字，触发实时核验
	var input: LineEdit = dialog.find_child("CharacterNameInput", true, false) as LineEdit
	if input == null:
		printerr("[shot] 找不到名字输入框")
		quit(3)
		return
	input.text = _name
	input.text_changed.emit(_name)
	main_ui.call("_on_char_create_name_changed", _name)
	await create_timer(2.0).timeout
	var hint: Label = dialog.find_child("NameHint", true, false) as Label
	print("[shot] 核验提示：", hint.text if hint != null else "(无)")
	await _save_window(dialog, _out)
	print("[shot] 已保存面板：", _out)

	# 选第三个形象（角色2），再点创建
	main_ui.call("_update_char_create_preview", 3)
	await create_timer(0.6).timeout
	main_ui.call("_on_char_create_confirm_pressed")
	await create_timer(4.0).timeout
	var nick = main_ui.get("network_nickname")
	var cid = 0
	var gm = main_ui.get("game_manager")
	if gm != null and gm.get("player") != null:
		cid = int(gm.get("player").get("player_character_id"))
	print("[shot] 创建后 nickname=", nick, " characterId=", cid)
	await _save_root(_out2)
	print("[shot] 已保存主界面：", _out2)
	quit(0)


func _save_window(w: Window, path: String) -> void:
	if not is_instance_valid(w):
		return
	var tex := w.get_texture()
	if tex == null:
		printerr("[shot] window texture 为空")
		return
	var img := tex.get_image()
	if img == null:
		printerr("[shot] window image 为空")
		return
	var e := img.save_png(path)
	print("[shot] save_png(window) err=", e, " size=", img.get_width(), "x", img.get_height())


func _save_root(path: String) -> void:
	var img := get_root().get_texture().get_image()
	var e := img.save_png(path)
	print("[shot] save_png(root) err=", e, " size=", img.get_width(), "x", img.get_height())
