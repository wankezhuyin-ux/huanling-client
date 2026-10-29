extends SceneTree
# 聊天面板截图/自检脚本（开发期用，不随包发）
#
# 流程：登录 → 等主城 → 注入 5 条世界消息 → 截「收起态预览」→ 点喇叭打开 → 截「面板」。
#
# 用法：
#   Godot --path . --resolution 720x1280 --script tools/chat_shot.gd \
#     -- --user=chattest --pass=chat123 --out=/tmp/chat_closed.png --out2=/tmp/chat_open.png

var _user := "chattest"
var _pass := "chat123"
var _out := "/tmp/chat_closed.png"
var _out2 := "/tmp/chat_open.png"


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
	var scene: PackedScene = load("res://main.tscn")
	if scene == null:
		printerr("[chat] 载入 main.tscn 失败")
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


func _start() -> void:
	var root_node := get_root()
	var login := _find_by_script(root_node, "login_ui.gd")
	for i in 600:
		if login != null:
			break
		await process_frame
		login = _find_by_script(root_node, "login_ui.gd")
	if login == null:
		printerr("[chat] 没找到登录界面")
		quit(1)
		return
	for i in 3600:
		await process_frame
		if bool(login.get("_version_check_done")) and bool(login.get("_version_allows_login")):
			break
	(login.get("login_username") as LineEdit).text = _user
	(login.get("login_password") as LineEdit).text = _pass
	login.call("_on_login_pressed")
	print("[chat] 已提交登录 ", _user)

	# 主城是懒加载的（MainContent/CityView/CityUI），先等主界面再切到主城视图
	var main_ui: Node = null
	for i in 1800:
		await process_frame
		main_ui = _find_by_script(root_node, "ink_home.gd")
		if main_ui == null:
			main_ui = _find_by_script(root_node, "main_ui.gd")
		if main_ui != null:
			break
	if main_ui == null:
		printerr("[chat] 没进主界面")
		quit(2)
		return
	# 必须真的点「进入游戏」：只把窗口 hide 掉的话 _start_game() 不会恢复 HUD
	# （top_bar / main_content / bottom_nav 会一直保持隐藏，截图只剩背景图）
	var d = main_ui.get("startup_dialog")
	if d != null and is_instance_valid(d):
		var pressed := _press_button_with(d, ["进入游戏", "进入", "确定"])
		print("[chat] 启动弹窗按钮: ", pressed if not pressed.is_empty() else "(没找到)")
	for i in 600:
		await process_frame
		var bn = main_ui.get("bottom_nav")
		if bn is CanvasItem and (bn as CanvasItem).visible:
			break
	print("[chat] HUD 已恢复")
	main_ui.call("_show_view", "city")
	print("[chat] 已切到主城视图")

	var city: Node = null
	for i in 2400:
		await process_frame
		city = _find_by_script(root_node, "city_ui.gd")
		if city != null:
			break
	if city == null:
		printerr("[chat] 没进主城")
		quit(2)
		return
	print("[chat] 主城就绪")
	# 刚建出来的 CityUI 可能停在「内容页」状态（吊牌/喇叭被 set_ui_visible(false) 收起），
	# 调 _hide_content() 等价于玩家从功能页返回主城首页
	city.call("_hide_content")
	await create_timer(1.5).timeout
	# 内页底板 _backdrop 排在 ink 之上，close() 若还在淡出会整块盖住主城（只剩背景图）
	var bd = city.get("_backdrop")
	if bd is CanvasItem:
		print("[chat] backdrop 之前 visible=", (bd as CanvasItem).visible,
			" alpha=", (bd as CanvasItem).modulate.a)
		(bd as CanvasItem).visible = false
	# 脚本提前调 _show_view 会让 MainContent 停在隐藏态（正常玩家流程不会），这里兜底打开
	var mc = main_ui.get("main_content")
	if mc is CanvasItem and not (mc as CanvasItem).visible:
		(mc as CanvasItem).visible = true
		print("[chat] MainContent 之前是隐藏的，已强制显示")
	# 主城是水墨层整体淡入，太早截图只会拍到背景图
	await create_timer(3.0).timeout
	var bn = main_ui.get("bottom_nav")
	print("[chat] 诊断 main_ui.visible=", (main_ui as CanvasItem).visible if main_ui is CanvasItem else "?",
		" bottom_nav=", (str((bn as CanvasItem).visible) + "/" + str((bn as CanvasItem).modulate.a)) if bn is CanvasItem else "null",
		" city.visible=", (city as CanvasItem).visible if city is CanvasItem else "?")
	var ink = city.get("_ink")
	if ink is CanvasItem:
		print("[chat] 诊断 ink visible=", (ink as CanvasItem).visible, " children=", ink.get_child_count(),
			" s=", ink.get("s"), " alpha=", (ink as CanvasItem).modulate.a,
			" city_alpha=", (city as CanvasItem).modulate.a,
			" pos=", (ink as CanvasItem).global_position, " size=", (ink as CanvasItem).size)
		var shown := 0
		for ch in ink.get_children():
			if ch is Control and ch.has_meta("ink_pos"):
				shown += 1
				if shown <= 3:
					var c := ch as Control
					print("[chat]   子节点 ", c.name, " visible=", c.visible, " alpha=", c.modulate.a,
						" rect=", c.get_global_rect())
		print("[chat] 诊断 带 ink_pos 的子节点数=", shown)
	var p: Node = city
	while p != null and not (p is Window):
		if p is Control:
			print("[chat]   父链 ", p.name, " rect=", (p as Control).get_global_rect(),
				" clip=", (p as Control).clip_contents, " vis=", (p as Control).visible,
				" alpha=", (p as Control).modulate.a)
		p = p.get_parent()
	await _save("/tmp/chat_probe.png")

	await create_timer(1.0).timeout

	# 注入 5 条世界消息（id 互不相同，避免被 _feed_message_key 去重）
	var demo := [
		{"sender": "剑无痕", "message": "生死塔 37 层有人组队吗，还差一个奶"},
		{"sender": "白露", "message": "乾坤炉刚炼出紫装，手气不错"},
		{"sender": "南山客", "message": "宠物园今天刷出一只金色灵狐"},
		{"sender": "青灯", "message": "帮派收人，晚上八点打仙魔"},
		{"sender": "小满", "message": "世界频道试个音，能看到吗"},
	]
	for i in range(demo.size()):
		var m: Dictionary = demo[i].duplicate()
		m["event_type"] = "chat"
		m["channel_type"] = "world"
		m["id"] = 900001 + i
		city.call("_on_chat_msg_received", m)
	await create_timer(0.8).timeout
	print("[chat] 已注入 ", demo.size(), " 条世界消息")

	# 「欢迎回来」这类启动弹窗会在登录后几秒才弹，截图前统一收掉
	_hide_popup_windows()
	await create_timer(0.3).timeout

	var preview = city.get("_chat_preview_box")
	if preview != null and is_instance_valid(preview):
		print("[chat] 预览节点=", preview.get_global_rect(), " 可见=", preview.visible,
			" 行数=", preview.get_child_count())
		for i in range(preview.get_child_count()):
			var row = preview.get_child(i)
			print("[chat]   row%d alpha=%.2f text=%s" % [i, row.modulate.a, str(row.text).left(24)])
	else:
		printerr("[chat] 预览节点不存在")

	await _save(_out)

	city.call("_ink_toggle_chat")
	await create_timer(1.0).timeout
	var panel = city.get("chat_panel")
	if panel != null and is_instance_valid(panel):
		print("[chat] 面板 rect=", panel.get_global_rect(), " 可见=", panel.visible)
	var close_btn = city.get("_chat_close_btn")
	if close_btn != null and is_instance_valid(close_btn):
		print("[chat] 关闭钮 rect=", (close_btn as Control).get_global_rect())
	else:
		printerr("[chat] 关闭钮不存在")
	await _save(_out2)
	print("[chat] 已保存 ", _out, " / ", _out2)
	quit(0)


## 在给定节点里找文字匹配的按钮并按下去，返回被点的按钮文字
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
			print("[chat] 已隐藏窗口: ", n.name)


func _save(path: String) -> void:
	_hide_popup_windows()
	await process_frame
	await process_frame
	var img := get_root().get_texture().get_image()
	if img == null:
		printerr("[chat] 拿不到画面")
		return
	var e := img.save_png(path)
	print("[chat] save_png err=", e, " size=", img.get_width(), "x", img.get_height())
