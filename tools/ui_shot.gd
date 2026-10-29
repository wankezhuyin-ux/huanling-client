extends SceneTree
# 截图用的小工具（不参与游戏运行，也不随热更发给玩家）
#
# 目的：本机没有系统级点击权限，没法手动点「登录」，也就没法看到战斗界面，
# UI 布局核对就变成"只能读代码猜"。这个脚本用代码走一遍真实登录流程，
# 把弹窗按掉，然后把画面存成 PNG，方便逐像素和参考稿截图对齐。
#
# 用法：
#   Godot --path . --resolution 496x1280 --script tools/ui_shot.gd -- --out=/tmp/ui_shot.png
# 参数：
#   --out=PATH     输出图片路径（默认 /tmp/ui_shot.png）
#   --user=NAME    账号（默认 uicheck）
#   --pass=PASS    密码（默认 uicheck123）
#   --wait=SEC     进入战斗界面后再等多久才截图（默认 4 秒，留时间让战斗跑起来）

const DEFAULT_USER := "uicheck"

# --popup=item|pet：截图前先点开一个弹窗，用来核对弹窗外壳的表皮。
# 弹窗是 Window，主题不跟着场景树走，只能单独截出来看。
var _popup_mode := ""
## 图鉴页的五行筛选，用来验证筛选逻辑（不是每次都要手点）
var _atlas_element := ""
## 大厅牌子按钮名（宠物园的 hub_btn_collection 等），用来截二级功能页
var _hub_press := ""
# --subtab=N：切视图后再按第 N 个二级页签（宠物袋/装备/天赋…），用来逐页核对表皮。
var _subtab := -1
# --hall=NAME：主城二级页面（settings/shop/ranking/qiankun/martial/pet/tower/…）。
# 这些页面是 city_ui 里 new 出来的整屏 Control，不是常驻视图，只能调入口函数开。
var _hall := ""
# --nologin：只截登录界面，不提交登录（用来核对手游第一屏的表皮）。
var _no_login := false
# --size=WxH：显式设置窗口尺寸。设计稿是按 1024×2276（9:20）画的，
# 默认窗口 720×1280（9:16）竖高不够，没法逐像素对照，所以留个口子。
var _win_size := Vector2i.ZERO
# --bagsel=N：选中背包第 N 件物品（0 起），用来核对底部常驻详情条的内容排版。
var _bag_select := -1
# --splash：截启动加载页（水墨化后的 key art + 金线进度条），不跑登录流程。
var _splash := false
# --cancel：开完弹窗再把它关掉，用来核对"取消后全屏遮罩有没有收掉"（曾卡死过）。
var _cancel_popup := false
## --pettier：把前几只灵兽的成长值改成跨档位的一组数，用来核对
## 灰/绿/蓝/紫/金五档头像框描边是不是真的分开（测试号本身没有高成长宠物）。
var _pet_tier_probe := false
## --chatsend=文本：打开聊天面板，往输入框塞一段字，再用合成鼠标事件点「发送」，
## 把点击命中的控件链、输入框是否被清空、消息列表条数变化都打出来。
## 用来定位「点了发送没反应」到底是没点到、还是发出去没人接。
var _chat_send_text := ""
## --navprobe：打开整页浮层（配合 --popup=）后，打印底栏 dock 的矩形与 z_index，
## 并在「主城」按钮中心合成一次点击，看事件有没有被浮层吃掉。
## 用来定位「整页一开，底部五个按钮全部点不动」。
var _nav_probe := false
var _chat_dismiss_probe := false
var _feed_probe := false
const DEFAULT_PASS := "uicheck123"


func _initialize() -> void:
	var out_path := "/tmp/ui_shot.png"
	var user := DEFAULT_USER
	var pw := DEFAULT_PASS
	var extra_wait := 4.0
	var view_mode := "battle"
	var do_press := true
	var sim_offline := false
	var dump_ui := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_path = a.substr(6)
		elif a.begins_with("--user="):
			user = a.substr(7)
		elif a.begins_with("--pass="):
			pw = a.substr(7)
		elif a.begins_with("--wait="):
			extra_wait = float(a.substr(7))
		elif a.begins_with("--view="):
			view_mode = a.substr(7)
		elif a == "--nopress":
			do_press = false
		elif a == "--simoffline":
			sim_offline = true
		elif a == "--dumpui":
			dump_ui = true
		elif a.begins_with("--popup="):
			_popup_mode = a.substr(8)
		elif a.begins_with("--subtab="):
			_subtab = int(a.substr(9))
		elif a.begins_with("--hall="):
			_hall = a.substr(7)
		elif a == "--nologin":
			_no_login = true
		elif a.begins_with("--bagsel="):
			_bag_select = int(a.substr(9))
		elif a.begins_with("--atlasel="):
			_atlas_element = a.substr(10)
		elif a.begins_with("--hubpress="):
			_hub_press = a.substr(11)
		elif a == "--splash":
			_splash = true
		elif a == "--cancel":
			_cancel_popup = true
		elif a == "--pettier":
			_pet_tier_probe = true
		elif a.begins_with("--chatsend="):
			_chat_send_text = a.substr(11)
		elif a == "--navprobe":
			_nav_probe = true
		elif a == "--chatdismiss":
			_chat_dismiss_probe = true
		elif a == "--feedprobe":
			_feed_probe = true
		elif a.begins_with("--size="):
			var raw := a.substr(7)
			var parts := raw.split("x")
			if parts.size() == 2:
				_win_size = Vector2i(int(parts[0]), int(parts[1]))
	if _win_size != Vector2i.ZERO:
		DisplayServer.window_set_size(_win_size)
		await process_frame
		await process_frame
		print("[ui_shot] 窗口尺寸设为 ", DisplayServer.window_get_size(), " 视口 ", get_root().get_visible_rect().size)
	var scene: PackedScene = load("res://main.tscn")
	if scene == null:
		printerr("[ui_shot] 载入 main.tscn 失败")
		quit(1)
		return
	var root_node: Node = scene.instantiate()
	get_root().add_child(root_node)
	_start.call_deferred(root_node, user, pw, out_path, extra_wait, view_mode, do_press, sim_offline, dump_ui)


func _walk(node: Node, out: Array) -> void:
	out.append(node)
	for c in node.get_children():
		_walk(c, out)


func _find_by_script(root_node: Node, script_name: String) -> Node:
	var all: Array = []
	_walk(root_node, all)
	for n in all:
		var s = n.get_script()
		if s != null and str(s.resource_path).ends_with(script_name):
			return n
	return null


func _find_main_ui(_root_node: Node) -> Node:
	# main.gd 登录成功后是 change_scene 换场景的，我 _initialize 里加进去的那个节点
	# 会被整棵释放，所以必须从视口根往下找，不能只在自己的节点树里找。
	# 线上首页用的是 ui/ink_home.gd（extends main_ui.gd 的皮），两个都要认。
	var n = _find_by_script(get_root(), "ink_home.gd")
	if n == null:
		n = _find_by_script(get_root(), "main_ui.gd")
	return n


func _press_first_button(dialog: Node, keywords: Array) -> String:
	var all: Array = []
	_walk(dialog, all)
	for n in all:
		if n is Button and (n as Button).visible and not (n as Button).disabled:
			var txt := str((n as Button).text)
			for k in keywords:
				if txt.find(str(k)) >= 0:
					(n as Button).pressed.emit()
					return txt
	return ""


func _visible_dialogs(_root_node: Node) -> Array:
	# 启动弹窗有两种实现：一种是真 Window/AcceptDialog，另一种是直接 add 到树里的 Control 面板
	# （「欢迎回来」就是后者），所以不能只找 Window —— 只找 Window 会一个都点不到。
	var all: Array = []
	_walk(get_root(), all)
	var out: Array = []
	for n in all:
		if n is Window and n != get_root() and (n as Window).visible:
			out.append(n)
	return out


func _press_anywhere(keywords: Array) -> String:
	var all: Array = []
	_walk(get_root(), all)
	for n in all:
		if n is Button and (n as Button).visible and not (n as Button).disabled:
			var txt := str((n as Button).text)
			for k in keywords:
				if txt.replace(" ", "").find(str(k)) >= 0:
					(n as Button).pressed.emit()
					return txt
	return ""


func _dump_ui() -> void:
	# 把当前可见的文字/按钮连位置一起打出来：截图只能看个大概，
	# 对位置、是否被裁切这类问题，坐标比肉眼靠谱。
	var all: Array = []
	_walk(get_root(), all)
	for n in all:
		if not (n is Control) or not (n as Control).is_visible_in_tree():
			continue
		var txt := ""
		if n is Label:
			txt = (n as Label).text
		elif n is Button:
			txt = (n as Button).text
		elif n is RichTextLabel:
			txt = (n as RichTextLabel).get_parsed_text()
		var r: Rect2 = (n as Control).get_global_rect()
		if txt.strip_edges() == "":
			if r.position.y > 90 or r.position.x > 320:
				continue
			txt = "<无文字>"
		print("UI|%s|%s|%d,%d,%dx%d|%s" % [
			n.get_path(), n.get_class(), int(r.position.x), int(r.position.y),
			int(r.size.x), int(r.size.y), txt.replace("\n", "\\n").substr(0, 90)])


func _start(root_node: Node, user: String, pw: String, out_path: String, extra_wait: float, view_mode: String, do_press: bool = true, sim_offline: bool = false, dump_ui: bool = false) -> void:
	var login := _find_by_script(root_node, "login_ui.gd")
	if login == null:
		# main.gd 的「创建登录界面」是延迟到下一帧甚至几帧之后才 add_child 的，
		# 所以这里必须轮询，不能立刻判定失败（第一版就是这么挂的）。
		for i in 300:
			await process_frame
			login = _find_by_script(root_node, "login_ui.gd")
			if login != null:
				break
	if login == null:
		printerr("[ui_shot] 没找到登录界面")
		quit(1)
		return
	# 等版本检查结束（登录按钮会被它挡住）。
	# 服务器在腾讯云，取 manifest 有时要好几秒，所以给到 60 秒，并且两个标志都要满足。
	for i in 3600:
		await process_frame
		if bool(login.get("_version_check_done")) and bool(login.get("_version_allows_login")):
			break
	print("[ui_shot] 版本门禁: done=", login.get("_version_check_done"),
		" allows_login=", login.get("_version_allows_login"),
		" locked=", login.get("_force_update_locked"))
	if _splash:
		# 启动加载罩是 main.gd 里临时建的 CanvasLayer，正常几秒就消失，
		# 这里手动再建一次，专门核对 key art 的水墨化和进度条配色。
		if root_node.has_method("_show_loading_overlay"):
			root_node.call("_show_loading_overlay")
		await create_timer(1.6).timeout
		await _save(out_path)
		print("[ui_shot] 已保存（启动加载页）：", out_path)
		quit(0)
		return

	if _no_login:
		await create_timer(max(1.5, extra_wait)).timeout
		await _save(out_path)
		print("[ui_shot] 已保存（登录界面）：", out_path)
		quit(0)
		return

	# 注意：不能写 login.set("login_username.text", ...)，set() 只认本层属性名，
	# 认不了 "子节点.属性" 这种路径（第一版就是这么失败的，界面报「用户名和密码不能为空」）。
	var ue = login.get("login_username")
	var pe = login.get("login_password")
	if ue == null or pe == null:
		printerr("[ui_shot] 拿不到用户名/密码输入框")
		quit(1)
		return
	ue.text = user
	pe.text = pw
	# 直接调登录按钮的回调，等价于玩家点「登录」
	login.call("_on_login_pressed")
	print("[ui_shot] 已提交登录：", user, " error_text=", login.get("login_error.text") if login.get("login_error") != null else "")

	# 等主界面出现
	var main_ui: Node = null
	for i in 1200:
		await process_frame
		main_ui = _find_main_ui(root_node)
		if main_ui != null:
			break
	if main_ui == null:
		printerr("[ui_shot] 登录后没出现主界面，转储节点树：")
		var dump: Array = []
		_walk(get_root(), dump)
		for n in dump:
			var sc = n.get_script()
			var sp := "" if sc == null else str(sc.resource_path)
			if sp != "" or n.get_child_count() == 0:
				printerr("   ", n.get_path(), "  class=", n.get_class(), "  script=", sp)
		await _save(out_path)
		quit(1)
		return
	print("[ui_shot] 主界面已就绪，开始按掉启动弹窗")

	# 按掉「离线奖励」「欢迎回来」「创建角色」这类启动弹窗：
	# 反复扫可见窗口，按里面的主按钮（领取奖励 / 进入 / 确定 / 开始）。
	# 弹窗是登录流程跑完才建的（离线结算要等 HTTP 回来），所以这里先等一会儿再点，
	# 并且允许连续几轮找不到就收工，别一上来没看到弹窗就退出循环。
	var pressed_total := 0
	var misses := 0
	for round_i in (0 if not do_press else 40):
		await create_timer(0.4).timeout
		var hit := _press_anywhere(["领取奖励", "进入游戏", "开始游戏", "创建角色", "确定", "确认"])
		if hit == "":
			misses += 1
			if misses >= 25:
				break
			continue
		misses = 0
		print("[ui_shot] 关闭弹窗按钮：", hit)
		pressed_total += 1

	# 兜底：如果还卡在弹窗上，直接强关，保证能看到 HUD 布局
	for d in _visible_dialogs(root_node):
		(d as Window).queue_free()

	if sim_offline:
		# 直接调离线奖励面板的渲染入口，用参考稿截图那组数字（8 小时 / 733→1052 / 13128480 金币）。
		# 服务端账号的 lastSeen 会被内存态覆盖，改文件造不出 60 秒以上的离线，
		# 这里只验「面板排版 + 面板背后有没有漏 HUD」。
		await create_timer(max(1.0, extra_wait)).timeout
		main_ui.call("_on_post_login_offline_rewards_ready", 8.0, 590760000, 13128480, {},
			0, false, {"playerLevelBefore": 733, "playerLevelAfter": 1052})
		await create_timer(1.5).timeout
		await _save(out_path)
		print("[ui_shot] 已保存（模拟离线奖励面板）：", out_path)
		quit(0)
		return

	if not do_press:
		# 不点弹窗：等它自己弹出来，然后直接截图看「面板背后的 HUD 有没有露出来」
		await create_timer(max(1.0, extra_wait)).timeout
		print("[ui_shot][dbg] pending=", main_ui.get("_startup_offline_pending"),
			" offline_dialog_shown=", main_ui.get("_startup_offline_dialog_shown"),
			" game_started=", main_ui.get("_game_started"),
			" startup_dialog=", main_ui.get("startup_dialog"))
		print("[ui_shot][dbg] 可见 Window 数=", _visible_dialogs(main_ui).size())
		await _save(out_path)
		print("[ui_shot] 已保存（不按弹窗）：", out_path)
		quit(0)
		return

	# --view=XXX 直接切到对应视图：city / pet / bag / character / battle / home
	# --pettier 要在切视图之前改数据，列表是按当前成长值现算颜色的
	if _pet_tier_probe:
		_apply_pet_tier_probe(main_ui)
	if view_mode != "home":
		if main_ui.has_method("_show_view"):
			main_ui.call("_show_view", view_mode)
		elif main_ui.has_method("_ink_enter"):
			main_ui.call("_ink_enter", "battle")

	# 二级页签：视图刚切完时按钮已建好，这里直接 emit pressed，等同一帧布局完成
	if _subtab >= 0:
		await process_frame
		_press_subtab(_subtab)

	# 主城二级页面：先确保在 city 视图，再调入口函数
	if _hall != "":
		await process_frame
		_open_hall(root_node, _hall)
		await create_timer(1.2).timeout
		if _hub_press != "":
			var hub_btn := _find_named(root_node, _hub_press)
			if hub_btn is Button:
				(hub_btn as Button).emit_signal("pressed")
				print("[ui_shot] 已按大厅牌子：", _hub_press)
			else:
				printerr("[ui_shot] 没找到牌子按钮：", _hub_press)
			await create_timer(1.0).timeout

	if _bag_select >= 0:
		await process_frame
		_select_bag_item(main_ui, _bag_select)

	# 聊天发送探针：要在视图切完之后做，否则面板会被重建
	if _chat_send_text != "":
		await _probe_chat_send(main_ui)

	# 聊天「点外部关闭」探针
	if _chat_dismiss_probe:
		await _probe_chat_dismiss(main_ui)

	# 公屏内容探针：走真实入口（点底栏「主城」）进主城，再打开聊天面板，
	# 把消息区每一行的文字打出来 —— 用来核对「旧工程旧消息是否还在」。
	if _feed_probe:
		await _probe_city_feed(main_ui)

	# 弹窗截图：要在视图切完之后开，否则会被视图重建带走
	if _popup_mode != "":
		_open_probe_popup(main_ui)

	if _nav_probe:
		await _probe_nav(main_ui)

	if _cancel_popup:
		await create_timer(0.6).timeout
		var closed := 0
		for w in _visible_dialogs(get_root()):
			(w as Window).queue_free()
			closed += 1
		print("[ui_shot] 已关闭弹窗数=", closed)
		await create_timer(1.0).timeout

	# 等战斗跑起来再截图
	await create_timer(max(0.5, extra_wait)).timeout
	if dump_ui:
		_dump_ui()
	await _save(out_path)
	print("[ui_shot] 截图已保存：", out_path, " 关过弹窗数=", pressed_total)
	quit(0)


func _save(out_path: String) -> void:
	await process_frame
	var tex := get_root().get_texture()
	if tex == null:
		printerr("[ui_shot] 拿不到视口纹理")
		return
	var img: Image = tex.get_image()
	if img == null:
		printerr("[ui_shot] get_image 返回 null")
		return
	var err := img.save_png(out_path)
	print("[ui_shot] save_png err=", err, " size=", img.get_width(), "x", img.get_height())


## 把前 5 只灵兽的成长值改成跨档位的一组数（灰/绿/蓝/紫/金），
## 用来一眼核对头像八角框描边、成长数字、左侧竖条三处颜色是否同档一致。
func _apply_pet_tier_probe(main_ui: Node) -> void:
	var gm = main_ui.get("game_manager")
	if gm == null:
		printerr("[ui_shot] 拿不到 game_manager，跳过成长档位探针")
		return
	var pm = gm.get("pet_manager")
	if pm == null or pm.pets.size() == 0:
		printerr("[ui_shot] 没有灵兽，跳过成长档位探针")
		return
	var probe := [4.2, 5.8, 7.6, 9.2, 10.4]
	for i in mini(pm.pets.size(), probe.size()):
		pm.pets[i].total_growth = float(probe[i])
		print("[ui_shot] 探针：灵兽#", i, " 成长=", pm.pets[i].total_growth)


## 选中背包第 N 件物品，走和玩家点击同一入口（只更新详情条，不开弹窗）
func _select_bag_item(main_ui: Node, index: int) -> void:
	var gm = main_ui.get("game_manager")
	if gm == null:
		printerr("[ui_shot] 拿不到 game_manager，跳过背包选中")
		return
	var inv = gm.get("inventory_manager")
	if inv == null or inv.items.size() <= index:
		printerr("[ui_shot] 背包物品不足，index=", index)
		return
	var item = inv.items[index]
	main_ui.call("_update_bag_detail_bar_item", item)
	print("[ui_shot] 已选中背包物品 #", index, "：", item.name)


## 打开一个用于核对表皮的弹窗。item = 背包第一件道具的操作弹窗，
## pet = 第一只灵兽的操作弹窗。
func _open_probe_popup(main_ui: Node) -> void:
	var gm = main_ui.get("game_manager")
	if gm == null:
		printerr("[ui_shot] 拿不到 game_manager，跳过弹窗")
		return
	if _popup_mode == "item":
		var inv = gm.get("inventory_manager")
		if inv == null or inv.items.size() == 0:
			printerr("[ui_shot] 背包为空，跳过弹窗")
			return
		main_ui.call("_show_item_action_popup", inv.items[0])
		print("[ui_shot] 已打开道具弹窗：", inv.items[0].name)
	elif _popup_mode == "map":
		main_ui.call("_show_map_selection_dialog")
		print("[ui_shot] 已打开选择地图")
	elif _popup_mode == "plan":
		main_ui.call("_show_auto_allocation_dialog")
		print("[ui_shot] 已打开加点方案")
	elif _popup_mode == "welcome":
		# _maybe_show_startup_welcome_after_offline 在已进游戏后会走"恢复 HUD"分支，
		# 截不到面板；直接叫面板本身的构造入口。
		main_ui.call("_show_login_dialog")
		print("[ui_shot] 已打开欢迎回来")
	elif _popup_mode == "signin7":
		# 七日签到整页：走真实入口（含 _refresh_signin7_entry 的红点逻辑）
		var city := _find_by_script(get_root(), "city_ui.gd")
		if city == null:
			printerr("[ui_shot] 没找到 city_ui，跳过签到弹窗")
		else:
			city.call("_on_signin7_pressed")
			print("[ui_shot] 已打开七日签到")
	elif _popup_mode == "treasure":
		# 藏宝洞整页：走主城功能格子的真实入口，验证轮次/秘箱/上轮得主渲染
		var city_t := _find_by_script(get_root(), "city_ui.gd")
		if city_t == null:
			printerr("[ui_shot] 没找到 city_ui，跳过藏宝洞")
		else:
			city_t.call("_on_treasure_cave_btn_pressed")
			print("[ui_shot] 已打开藏宝洞")
	elif _popup_mode == "treasuremirror":
		# 藏宝洞「查看镜像」弹窗：验证 hasMirror / 人物 / 出战宠 / 更新时间
		var city_m := _find_by_script(get_root(), "city_ui.gd")
		if city_m == null:
			printerr("[ui_shot] 没找到 city_ui，跳过镜像弹窗")
		else:
			city_m.call("_on_treasure_cave_btn_pressed")
			await create_timer(1.2).timeout
			var page := _find_by_script(get_root(), "treasure_cave_ui.gd")
			if page == null:
				printerr("[ui_shot] 没找到 treasure_cave_ui")
			else:
				page.call("_open_treasure_mirror")
				print("[ui_shot] 已打开藏宝洞镜像弹窗")
	elif _popup_mode == "treasurelog" or _popup_mode == "treasurereplay":
		# 藏宝洞战斗日志：走真实入口打开整页，再点第 1 个秘箱的「查看战斗日志」；
		# treasurereplay 会继续按下第一场的「查看本场回放」，用来核对回放面板排版。
		var city_l := _find_by_script(get_root(), "city_ui.gd")
		if city_l == null:
			printerr("[ui_shot] 没找到 city_ui，跳过战斗日志")
		else:
			city_l.call("_on_treasure_cave_btn_pressed")
			await create_timer(1.8).timeout
			var page := _find_by_script(get_root(), "treasure_cave_ui.gd")
			if page == null:
				printerr("[ui_shot] 没找到 treasure_cave_ui")
			else:
				var cid := 0
				var states = page.get("_chest_ui_states")
				if states is Array and states.size() > 0:
					cid = int((states[0] as Dictionary).get("chest_id", 0))
				page.call("_show_battle_log", cid, 1)
				print("[ui_shot] 已请求战斗日志 chest=", cid)
				if _popup_mode == "treasurereplay":
					await create_timer(2.2).timeout
					var replay_hit := _press_anywhere(["查看本场回放"])
					print("[ui_shot] 打开回放：", replay_hit)
	elif _popup_mode == "atlas":
		# 灵兽图鉴是整页 Control（不是 Window），单独给个入口方便逐像素对照
		main_ui.call("_show_pet_atlas_page")
		if _atlas_element != "":
			main_ui.call("_set_atlas_element_filter", _atlas_element)
		print("[ui_shot] 已打开灵兽图鉴 el=", _atlas_element)
	elif _popup_mode == "atlasfeed":
		# 投喂设置弹层：自动捕捉开关 + 最低成长率（与设置页同一套）
		main_ui.call("_show_pet_atlas_page")
		main_ui.call("_show_pet_atlas_feed_settings")
		print("[ui_shot] 已打开投喂设置")
	elif _popup_mode == "charswitch":
		# 角色切换弹窗：直接选中 6 号，验证"点格子 → 待机/攻击预览跟着换"
		main_ui.call("_show_player_character_switch_popup")
		main_ui.call("_update_player_character_popup_preview", 6)
		print("[ui_shot] 已打开角色切换（预览=角色6）")
	elif _popup_mode == "atlasdetail":
		# 图鉴卡片详情弹层：取第一只已收录（没有就第一只）灵兽，验证弹层排版
		main_ui.call("_show_pet_atlas_page")
		var pcm = gm.get("pet_collection_manager")
		var pick_id: = ""
		if pcm != null:
			for pid in pcm.get_all_pet_ids():
				if int(pcm.get_collection_info(str(pid)).get("count", 0)) > 0:
					pick_id = str(pid)
					break
			if pick_id == "":
				var all_ids: Array = pcm.get_all_pet_ids()
				if all_ids.size() > 0:
					pick_id = str(all_ids[0])
		if pick_id != "":
			main_ui.call("_show_atlas_pet_detail", pick_id)
			print("[ui_shot] 已打开图鉴详情：", pick_id)
	elif _popup_mode == "petdetail":
		# 灵兽详情（不是操作弹窗）。「加成明细」默认折叠，这里顺手点开，
		# 用来核对装备/图鉴/勋章那几行加成到底有没有渲染出来。
		var pm_d = gm.get("pet_manager")
		var ap_d = pm_d.get_active_pet() if pm_d else null
		if ap_d == null:
			printerr("[ui_shot] 没有出战灵兽，跳过弹窗")
			return
		main_ui.call("_show_pet_detail_popup", ap_d)
		_expand_bonus_fold_later()
		print("[ui_shot] 已打开灵兽详情：", ap_d.pet_name)
	elif _popup_mode == "pet":
		var pm = gm.get("pet_manager")
		if pm == null or pm.pets.size() == 0:
			printerr("[ui_shot] 没有灵兽，跳过弹窗")
			return
		main_ui.call("_show_pet_action_popup_by_id", str(pm.pets[0].id))
		print("[ui_shot] 已打开灵兽弹窗：", pm.pets[0].name)
	else:
		printerr("[ui_shot] 未知 popup 类型：", _popup_mode)


## 按第 N 个二级页签。视图名和页签容器名是固定搭配（PetView/SubButtons 等），
## 三个内页都试一遍，谁有按钮就按谁。
func _press_subtab(index: int) -> void:
	for view in ["PetView", "BagView", "CharacterView"]:
		var view_node = _find_main_ui(null).get_node_or_null("MainContent/%s" % view)
		# 只按"当前可见"那个视图的页签：三个视图的 SubButtons 都常驻在树里，
		# 挨个试的话会先命中隐藏视图，截出来还是原页面。
		if view_node == null or not (view_node as Control).visible:
			continue
		var box = view_node.get_node_or_null("SubButtons")
		if box == null or box.get_child_count() <= index:
			continue
		var btn = box.get_child(index)
		if btn is Button and not (btn as Button).disabled:
			(btn as Button).emit_signal("pressed")
			print("[ui_shot] 已按二级页签 #", index, "：", (btn as Button).text)
			return
	printerr("[ui_shot] 没找到可用的二级页签 #", index)


## 打开主城的某个二级页面。表里是 city_ui.gd 里真实存在的入口函数，
## 走同一个入口才等价于玩家点按钮（含缓存、BGM、埋点那套逻辑）。
const HALL_ENTRIES := {
	"settings": "_on_settings_btn_pressed",
	"shop": "_on_shop_btn_pressed",
	"ranking": "_on_ranking_btn_pressed",
	"qiankun": "_on_crafting_btn_pressed",
	"martial": "_on_martial_btn_pressed",
	"pet": "_on_pet_btn_pressed",
	"petpark": "_on_pet_btn_pressed",
	"tower": "_on_tower_btn_pressed",
	"dungeon": "on_suit_dungeon_btn_pressed",
	"lucky": "_on_lucky_draw_btn_pressed",
	"mail": "_on_mail_btn_pressed",
	"forge": "_on_forge_btn_pressed",
	"treasure": "_on_treasure_cave_btn_pressed",
	"warehouse": "_on_warehouse_btn_pressed",
	"gang": "show_gang_hall",
	"arena": "show_arena_hub_arena",
	"boss": "show_arena_hub_world_boss",
	"xianmo": "show_xianmo_panel",
	"quest": "_on_quest_btn_pressed",
}

func _find_named(root_node: Node, name_key: String) -> Node:
	if root_node == null:
		return null
	var stack: Array = [root_node]
	while not stack.is_empty():
		var n = stack.pop_back()
		if n.name == name_key:
			return n
		stack.append_array(n.get_children())
	return null


func _open_hall(root_node: Node, key: String) -> void:
	var city := _find_by_script(root_node, "city_ui.gd")
	if city == null:
		printerr("[ui_shot] 没找到 city_ui，跳过二级页面")
		return
	var entry: String = HALL_ENTRIES.get(key, "")
	if entry == "":
		printerr("[ui_shot] 未知 hall：", key, "（可用：", HALL_ENTRIES.keys(), "）")
		return
	if not city.has_method(entry):
		printerr("[ui_shot] city_ui 没有方法：", entry)
		return
	city.call(entry)
	print("[ui_shot] 已打开二级页面：", key, " -> ", entry)


## 「加成明细」那个折叠按钮是用 TouchScrollUtils.bind_tap 绑的，
## 走的是 gui_input 里的按下/抬起，不是 pressed 信号 —— emit pressed 没用，
## 必须补一对鼠标事件。
func _tap_control(btn: Control) -> void:
	var pos: Vector2 = btn.get_global_rect().get_center()
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = pos
	down.global_position = pos
	btn.gui_input.emit(down)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = pos
	up.global_position = pos
	btn.gui_input.emit(up)


func _expand_bonus_fold_later() -> void:
	await create_timer(0.8).timeout
	var all: Array = []
	_walk(get_root(), all)
	for n in all:
		if n is Button and str((n as Button).text).find("加成明细") >= 0 and (n as Button).is_visible_in_tree():
			_tap_control(n as Button)
			print("[ui_shot] 已点开加成明细：", str((n as Button).text))
			await create_timer(0.6).timeout
			return
	printerr("[ui_shot] 没找到加成明细按钮")


## 聊天面板「点发送没反应」探针：打开面板 → 塞字 → 合成鼠标点击 → 打印结果。
## 输出四段：输入框/发送键的全局矩形、点击点上所有能拦事件且可见的 Control、
## 点击后输入框内容、消息列表条数。
func _probe_chat_send(main_ui: Node) -> void:
	var city := _find_by_script(get_root(), "city_ui.gd")
	if city == null:
		if main_ui.has_method("_show_view"):
			main_ui.call("_show_view", "city")
		elif main_ui.has_method("_ink_enter"):
			main_ui.call("_ink_enter", "city")
		await create_timer(1.5).timeout
		city = _find_by_script(get_root(), "city_ui.gd")
	if city == null:
		printerr("[chatprobe] 没找到 city_ui")
		return
	city.call("_ink_set_chat_open", true, true)
	await create_timer(0.8).timeout
	var inp := _find_named(get_root(), "ChatInput") as LineEdit
	var send := _find_named(get_root(), "SendBtn") as Button
	var content := _find_named(get_root(), "ChatContent")
	print("[chatprobe] input=", inp, " send=", send, " content=", content)
	if send == null:
		printerr("[chatprobe] 找不到 SendBtn")
		return
	var panel := _find_named(get_root(), "ChatPanel") as Control
	if panel != null:
		print("[chatprobe] panel rect=", panel.get_global_rect(), " z=", panel.z_index,
			" visible=", panel.visible, " idx=", panel.get_index())
	print("[chatprobe] send rect=", send.get_global_rect(), " send.disabled=", send.disabled,
		" send.visible=", send.is_visible_in_tree(), " mouse_filter=", send.mouse_filter)
	if inp != null:
		print("[chatprobe] input rect=", inp.get_global_rect(), " font=",
			inp.get_theme_font_size("font_size"), " editable=", inp.editable)
		inp.text = _chat_send_text
	var p: Vector2 = send.get_global_rect().get_center()
	# 把点击点上所有「可见 + 不穿透」的 Control 按树序列出来：越靠后画得越上层
	var all: Array = []
	_walk(get_root(), all)
	var hits: Array = []
	for n in all:
		if n is Control and (n as Control).is_visible_in_tree():
			var c := n as Control
			if c.mouse_filter == Control.MOUSE_FILTER_IGNORE:
				continue
			if not c.get_global_rect().has_point(p):
				continue
			hits.append("%s[%s] z=%d idx=%d" % [c.name, c.get_class(), c.z_index, c.get_index()])
	print("[chatprobe] 命中点 ", p, " 上的可拦控件（从下到上 ", hits.size(), " 个）：")
	for h in hits:
		print("    ", h)
	var before := 0
	if content != null:
		before = content.get_child_count()
	var vp: Viewport = get_root()
	var mv := InputEventMouseMotion.new()
	mv.position = p
	mv.global_position = p
	vp.push_input(mv)
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = p
	down.global_position = p
	vp.push_input(down)
	await create_timer(0.12).timeout
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = p
	up.global_position = p
	vp.push_input(up)
	await create_timer(0.9).timeout
	var after := 0
	if content != null:
		after = content.get_child_count()
	print("[chatprobe] 点击后 input.text=\"", inp.text if inp != null else "?",
		"\" 消息条数 ", before, " -> ", after)
	# 再直接 emit pressed 一次：区分「事件没送到」和「回调本身有问题」
	if inp != null:
		inp.text = _chat_send_text
	send.emit_signal("pressed")
	await create_timer(0.9).timeout
	after = content.get_child_count() if content != null else 0
	print("[chatprobe] emit pressed 后 input.text=\"", inp.text if inp != null else "?",
		"\" 消息条数 ", before, " -> ", after)


## 聊天「点外部关闭」探针：
##   ① 开面板 → 遮罩应该在、面板可见；
##   ② 点面板外（底栏「背包」正中）→ 面板应关闭，且视图不能被切走（点击被遮罩吃掉）；
##   ③ 再开面板 → 点面板内部（消息区中心）→ 面板应保持打开。
func _probe_chat_dismiss(main_ui: Node) -> void:
	await create_timer(0.8).timeout
	var city := _find_by_script(get_root(), "city_ui.gd")
	if city == null:
		# 默认视图可能是战斗页，city_ui 要切到主城才会建
		if main_ui.has_method("_show_view"):
			main_ui.call("_show_view", "city")
		elif main_ui.has_method("_ink_enter"):
			main_ui.call("_ink_enter", "city")
		await create_timer(1.5).timeout
		city = _find_by_script(get_root(), "city_ui.gd")
	if city == null:
		printerr("[dismiss] 没找到 city_ui")
		return
	var panel := _find_named(get_root(), "ChatPanel") as Control
	var mask := _find_named(get_root(), "InkChatDismissLayer") as Node
	var ok_all := true
	# ① 打开
	city.call("_ink_set_chat_open", true, true)
	await create_timer(0.6).timeout
	print("[dismiss] ①开面板: panel.visible=", panel.visible if panel != null else "?",
		" mask.visible=", (mask.visible if mask != null else "?"),
		" layer=", mask.get("layer") if mask != null else "?")
	if panel == null or not panel.visible or mask == null or not mask.visible:
		ok_all = false
	var view_before := String(str(main_ui.get("current_view")))
	# ② 点面板外：底栏「背包」中心
	var bag := _find_named(get_root(), "BagBtn") as Button
	if bag == null:
		printerr("[dismiss] 找不到 BagBtn")
		return
	var p_out: Vector2 = bag.get_global_rect().get_center()
	await _synth_click(p_out)
	await create_timer(0.8).timeout
	var view_after := String(str(main_ui.get("current_view")))
	var closed := panel != null and not panel.visible
	print("[dismiss] ②点外面(", p_out, "): panel.visible=", panel.visible if panel != null else "?",
		" view ", view_before, " -> ", view_after,
		" _chat_open=", city.get("_chat_open"))
	if not closed or view_after != view_before:
		ok_all = false
	# ③ 再开，点面板里面
	city.call("_ink_set_chat_open", true, true)
	await create_timer(0.6).timeout
	var msgs := _find_named(get_root(), "ChatMessagesPanel") as Control
	var p_in: Vector2 = msgs.get_global_rect().get_center() if msgs != null \
			else panel.get_global_rect().get_center()
	await _synth_click(p_in)
	await create_timer(0.6).timeout
	var still_open := panel != null and panel.visible
	print("[dismiss] ③点面板内(", p_in, "): panel.visible=", panel.visible if panel != null else "?",
		" _chat_open=", city.get("_chat_open"))
	if not still_open:
		ok_all = false
	# ④ 面板开着时切到战斗页：遮罩必须自动收掉，否则会盖住战斗页吃掉所有点击
	if main_ui.has_method("_show_view"):
		main_ui.call("_show_view", "battle")
		await create_timer(1.0).timeout
		var hidden_in_battle: bool = (mask == null) or not (mask as CanvasLayer).visible
		print("[dismiss] ④切战斗页: mask.visible=", (mask.visible if mask != null else "?"))
		if not hidden_in_battle:
			ok_all = false
		main_ui.call("_show_view", "city")
		await create_timer(1.2).timeout
	city.call("_ink_set_chat_open", false, true)
	print("[dismiss] RESULT=", "OK" if ok_all else "FAIL")


## 公屏内容探针：点底栏「主城」走真实入口，等 _refresh_city_feed 跑完，
## 再打开聊天面板，逐行打印消息区文字。
func _probe_city_feed(main_ui: Node) -> void:
	await create_timer(0.6).timeout
	var city_btn := _find_named(get_root(), "CityBtn") as Button
	if city_btn != null and String(str(main_ui.get("current_view"))) != "city":
		city_btn.emit_signal("pressed")
		print("[feedprobe] 点底栏「主城」")
	await create_timer(3.0).timeout
	var city := _find_by_script(get_root(), "city_ui.gd")
	if city == null:
		printerr("[feedprobe] 没找到 city_ui")
		return
	city.call("_ink_set_chat_open", true, true)
	await create_timer(1.2).timeout
	var content := _find_named(get_root(), "ChatContent")
	if content == null:
		printerr("[feedprobe] 没找到 ChatContent")
		return
	print("[feedprobe] 消息区行数=", content.get_child_count())
	var legacy := 0
	for ch in content.get_children():
		var txt := ""
		if ch is RichTextLabel:
			txt = (ch as RichTextLabel).get_parsed_text()
		elif ch is Label:
			txt = (ch as Label).text
		if ch.has_method("get_parsed_text"):
			txt = ch.call("get_parsed_text")
		txt = txt.replace("\n", " / ")
		if txt.find("搬砖的") >= 0 or txt.find("立羽") >= 0 or txt.find("化龍") >= 0 or txt.find("思念") >= 0:
			legacy += 1
		print("[feedprobe]   |", txt.substr(0, 90))
	print("[feedprobe] 旧工程旧消息命中=", legacy, " RESULT=", "OK" if legacy == 0 else "FAIL")
	var gm = main_ui.get("game_manager")
	if gm != null and gm.network != null:
		var snap: Array = await gm.network.fetch_xianmo_broadcast_history_snapshot(0, 15)
		print("[feedprobe] 直接拉 /xianmo/broadcasts 返回 ", snap.size(), " 行")
		var cache: Array = main_ui.get("_cached_world_messages")
		print("[feedprobe] 合并前缓存 ", cache.size(), " 行：")
		for r in cache:
			print("[feedprobe]   c|", str((r as Dictionary).get("event_type", "")), " ",
				str((r as Dictionary).get("message", "")).replace("\n", " / ").substr(0, 50))
		main_ui.call("_merge_recent_world_feed_to_cache", [], snap, 30)
		cache = main_ui.get("_cached_world_messages")
		print("[feedprobe] 合并后缓存 ", cache.size(), " 行：")
		for r in cache:
			print("[feedprobe]   c|", str((r as Dictionary).get("event_type", "")), " ",
				str((r as Dictionary).get("message", "")).replace("\n", " / ").substr(0, 50))


func _synth_click(p: Vector2) -> void:
	var vp: Viewport = get_root()
	var mv := InputEventMouseMotion.new()
	mv.position = p
	mv.global_position = p
	vp.push_input(mv)
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = p
	down.global_position = p
	vp.push_input(down)
	await create_timer(0.12).timeout
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = p
	up.global_position = p
	vp.push_input(up)


## 底栏探针：整页浮层（图鉴等）一开，底部五个按钮是不是全被吃掉。
## 打印浮层/底栏的矩形与 z_index，再在「主城」按钮中心合成一次点击，看视图是否切走。
func _probe_nav(main_ui: Node) -> void:
	await create_timer(0.8).timeout
	var nav := _find_named(get_root(), "BottomNav") as Control
	var page := _find_named(get_root(), "PetAtlasPage") as Control
	if nav == null:
		printerr("[navprobe] 找不到 BottomNav")
		return
	print("[navprobe] 视口=", get_root().get_visible_rect().size)
	print("[navprobe] BottomNav rect=", nav.get_global_rect(), " z=", nav.z_index,
		" visible=", nav.is_visible_in_tree(), " filter=", nav.mouse_filter)
	if page != null:
		print("[navprobe] PetAtlasPage rect=", page.get_global_rect(), " z=", page.z_index,
			" visible=", page.is_visible_in_tree(), " filter=", page.mouse_filter)
	# 底栏每一枚徽章的矩形
	var all: Array = []
	_walk(nav, all)
	for n in all:
		if n is Button and (n as Button).is_visible_in_tree():
			var b := n as Button
			print("[navprobe]   按钮 ", b.name, " rect=", b.get_global_rect())
	var cur_view := String(str(main_ui.get("current_view")))
	# 已经在主城时点「主城」不会换视图，换成点「背包」才判得出来
	var btn_name := "BagBtn" if cur_view == "city" else "CityBtn"
	var target := _find_named(get_root(), btn_name) as Button
	if target == null:
		printerr("[navprobe] 找不到 ", btn_name)
		return
	var p: Vector2 = target.get_global_rect().get_center()
	# 该点上的可拦控件，从下层到上层。Godot 的实际绘制/命中顺序是
	# 「沿父链累加的 z_index，同 z 按树序」，所以不能只看节点自己的 z_index
	# （city_ui 里那些 z=120/200 的浮层是相对父节点的，累加后可能压过底栏）。
	var hits: Array = []
	var nodes: Array = []
	_walk(get_root(), nodes)
	var idx := 0
	for n in nodes:
		var i_now := idx
		idx += 1
		if not (n is Control):
			continue
		var c := n as Control
		if not c.is_visible_in_tree() or c.mouse_filter == Control.MOUSE_FILTER_IGNORE:
			continue
		if not c.get_global_rect().has_point(p):
			continue
		hits.append({"z": _eff_z(c), "i": i_now,
			"txt": "%s[%s] z=%d(eff %d) idx=%d filter=%d" % [c.name, c.get_class(), c.z_index, _eff_z(c), i_now, c.mouse_filter]})
	hits.sort_custom(func(a, b): return a["z"] < b["z"] or (a["z"] == b["z"] and a["i"] < b["i"]))
	print("[navprobe] 点 ", p, " 上可拦控件 ", hits.size(), " 个（下层→上层，最后一个才是真正收事件的）：")
	for h in hits:
		print("[navprobe]    ", h["txt"])
	var top_txt := "(无)" if hits.is_empty() else String(hits[hits.size() - 1]["txt"])
	print("[navprobe] 最上层收事件的控件：", top_txt)
	var before := cur_view
	var vp := get_root() as Viewport
	var mv := InputEventMouseMotion.new()
	mv.position = p
	mv.global_position = p
	vp.push_input(mv)
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = p
	down.global_position = p
	vp.push_input(down)
	await create_timer(0.1).timeout
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = p
	up.global_position = p
	vp.push_input(up)
	await create_timer(1.0).timeout
	var after := String(str(main_ui.get("current_view")))
	var reached := top_txt.begins_with(btn_name)
	var switched := after != before
	print("[navprobe] 点击 ", btn_name, " 后 current_view: ", before, " -> ", after)
	print("[navprobe] RESULT=", "OK" if (reached and switched) else "FAIL",
		"  命中=", btn_name if reached else "被别的控件吃掉", "  视图切换=", switched)


## 沿父链累加 z_index（z_as_relative 为假时以自身为基准重新开始），
## 得到这个 Control 在画布上的实际层级 —— 判断「谁盖住谁」必须用这个值。
func _eff_z(c: Control) -> int:
	var z := 0
	var n: Node = c
	while n != null:
		if n is CanvasItem:
			var ci := n as CanvasItem
			z += ci.z_index
			if not ci.z_as_relative:
				break
		n = n.get_parent()
	return z
