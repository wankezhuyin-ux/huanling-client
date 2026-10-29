extends SceneTree
# 宠装穿戴端到端探针（不进游戏包，只本机跑）
#
# 复现玩家报的问题：「点穿戴提示已穿戴，但宠物装备页的槽位还是空的、
# 查看加成全是 0、出战宠物也没吃到装备属性」。
#
# 走的是**真实 UI 路径**：往背包塞两件宠装 → 先上传一次（让服务端收下这份背包，
# 等价于玩家正常玩时的自动存档）→ 逐件打开物品弹窗点「穿戴」→ 等服务器回包 → 检查
#   1) pet_equipment_manager.get_equipped("pet_boots"/"pet_weapon") 有没有填充
#   2) 加成面板的数值（get_all_bonus）
#   3) 出战宠物的战斗属性有没有真的加上去（get_final_*_with_equipment）
#   4) 背包件数有没有被回包里的空数组冲掉
#
# 用法：
#   Godot --path . --resolution 496x1280 --script tools/pet_equip_probe.gd -- --user=xxx --pass=yyy

const DEFAULT_USER := "peqUItest"
const DEFAULT_PASS := "test1234"

var _user := DEFAULT_USER
var _pw := DEFAULT_PASS
var _shot_dir := ""
var _fails: Array = []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--user="):
			_user = a.substr(7)
		elif a.begins_with("--pass="):
			_pw = a.substr(7)
		elif a.begins_with("--shot="):
			_shot_dir = a.substr(7)
	var scene: PackedScene = load("res://main.tscn")
	if scene == null:
		printerr("[probe] main.tscn 载入失败")
		quit(1)
		return
	var root_node: Node = scene.instantiate()
	get_root().add_child(root_node)
	_run.call_deferred(root_node)


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


func _press_anywhere(keywords: Array, exact: bool = false) -> String:
	var all: Array = []
	_walk(get_root(), all)
	for n in all:
		if n is Button and (n as Button).visible and not (n as Button).disabled:
			var txt := str((n as Button).text).replace(" ", "")
			for k in keywords:
				var hit := (txt == str(k)) if exact else (txt.find(str(k)) >= 0)
				if hit:
					(n as Button).pressed.emit()
					return txt
	return ""


func _check(name: String, cond: bool, extra: String = "") -> void:
	print(("  PASS  " if cond else "  FAIL  ") + name + ("" if cond else "  " + extra))
	if not cond:
		_fails.append(name)


func _equip_via_ui(main_ui: Node, pe_mgr, item: Dictionary, pet_slot: String, op_timeout_s: float = 30.0) -> bool:
	main_ui.call("_show_pet_equipment_action_popup", item, "", false)
	await create_timer(0.8).timeout
	var pressed := _press_anywhere(["穿戴"], true)
	if pressed == "":
		printerr("[probe] 弹窗里没找到「穿戴」按钮")
		return false
	var deadline: int = int(op_timeout_s * 60.0)
	for i in deadline:
		await process_frame
		if pe_mgr.get_equipped(pet_slot) != null:
			await create_timer(0.4).timeout
			return true
		if i % 10 == 0:
			await create_timer(0.05).timeout
	return false


func _run(root_node: Node) -> void:
	var login := _find_by_script(root_node, "login_ui.gd")
	for i in 300:
		if login != null:
			break
		await process_frame
		login = _find_by_script(root_node, "login_ui.gd")
	if login == null:
		printerr("[probe] 没找到登录界面")
		quit(1)
		return
	for i in 3600:
		await process_frame
		if bool(login.get("_version_check_done")) and bool(login.get("_version_allows_login")):
			break
	var ue = login.get("login_username")
	var pe = login.get("login_password")
	if ue == null or pe == null:
		printerr("[probe] 拿不到输入框")
		quit(1)
		return
	ue.text = _user
	pe.text = _pw
	login.call("_on_login_pressed")

	var main_ui: Node = null
	for i in 1200:
		await process_frame
		main_ui = _find_by_script(get_root(), "ink_home.gd")
		if main_ui == null:
			main_ui = _find_by_script(get_root(), "main_ui.gd")
		if main_ui != null:
			break
	if main_ui == null:
		printerr("[probe] 登录后没出现主界面")
		quit(1)
		return

	for i in 120:
		await process_frame
		if GameManager.instance != null and GameManager.instance.network != null \
				and GameManager.instance.network.is_logged_in():
			break
	var gm = GameManager.instance
	if gm == null:
		printerr("[probe] GameManager.instance 为空")
		quit(1)
		return

	for round_i in 30:
		await create_timer(0.4).timeout
		_press_anywhere(["领取奖励", "进入游戏", "开始游戏", "创建角色", "确定", "确认"])
	await create_timer(1.5).timeout

	var pe_mgr = gm.pet_equipment_manager
	var im = gm.inventory_manager
	var pm = gm.pet_manager
	if pe_mgr == null or im == null or pm == null:
		printerr("[probe] 管理器缺失")
		quit(1)
		return
	if pm.get_active_pet() == null:
		printerr("[probe] 没有出战宠物，无法验证加成")
		quit(1)
		return
	print("[probe] 出战宠物: %s Lv.%d id=%s" % [pm.get_active_pet().pet_name, pm.get_active_pet().level,
		str(pm.get_active_pet().id)])

	var stamp: int = int(Time.get_unix_time_from_system())
	var boots: Dictionary = {
		"id": "probe_boots_%d" % stamp, "name": "测试鞋（宠）", "slot": "boots", "rarity": "divine",
		"attack": 0, "defense": 0, "hp": 0, "mp": 0, "agility": 501,
		"is_pet_equipment": true, "pet_enhance_level": 0, "locked": false,
	}
	var weapon: Dictionary = {
		"id": "probe_weapon_%d" % stamp, "name": "测试刀（宠）", "slot": "weapon", "rarity": "divine",
		"attack": 701, "defense": 0, "hp": 0, "mp": 0, "agility": 0,
		"is_pet_equipment": true, "pet_enhance_level": 0, "locked": false,
	}
	im.pet_equipment_items.append(boots)
	im.pet_equipment_items.append(weapon)
	print("[probe] 已往背包塞入 2 件测试宠装，背包共 %d 件" % im.pet_equipment_items.size())

	# 先整包上传一次：等价于玩家正常玩时的自动存档，让服务端收下这份宠装背包。
	gm.upload_cloud_save(false, "probe_seed")
	await create_timer(3.0).timeout
	print("[probe] 背包已上传（seed）")

	var bag_before: int = im.pet_equipment_items.size()
	var pet0 = pm.get_active_pet()
	var agi_base: float = pet0.get_final_agility()
	var atk_base: float = pet0.get_final_attack()

	print("\n== 1. 穿戴鞋子 ==")
	var ok1: bool = await _equip_via_ui(main_ui, pe_mgr, boots, "pet_boots")
	_check("鞋子弹窗点「穿戴」后槽位已填充", ok1)
	var pet1 = pm.get_active_pet()
	if pet1 != null:
		var bonus1: Dictionary = pe_mgr.get_all_bonus(pet1)
		print("        加成面板: 攻 %s 防 %s 敏 %s 生 %s" % [str(bonus1.get("attack")), str(bonus1.get("defense")),
			str(bonus1.get("agility")), str(bonus1.get("hp"))])
		_check("加成面板敏捷 +501", int(bonus1.get("agility", 0)) == 501, str(bonus1.get("agility")))
		_check("出战宠物敏捷多吃了 501",
			absf((pet1.get_final_agility_with_equipment() - pet1.get_final_agility()) - 501.0) < 0.6,
			"差 %.2f" % (pet1.get_final_agility_with_equipment() - pet1.get_final_agility()))
		# 基础值只打印不判定：探针跑的时候宠物还在自动战斗，随时会升级。
		print("        基础敏捷 %.2f → %.2f（升级会变，仅供参考）" % [agi_base, pet1.get_final_agility()])
	var bag_mid: int = im.pet_equipment_items.size()
	print("        背包：%d → %d 件" % [bag_before, bag_mid])
	_check("背包只少了身上那 1 件", bag_mid == bag_before - 1, "%d → %d" % [bag_before, bag_mid])

	print("\n== 2. 穿戴武器 ==")
	var ok2: bool = await _equip_via_ui(main_ui, pe_mgr, weapon, "pet_weapon")
	_check("武器弹窗点「穿戴」后槽位已填充", ok2)
	var pet2 = pm.get_active_pet()
	if pet2 != null:
		var bonus2: Dictionary = pe_mgr.get_all_bonus(pet2)
		print("        加成面板: 攻 %s 防 %s 敏 %s 生 %s" % [str(bonus2.get("attack")), str(bonus2.get("defense")),
			str(bonus2.get("agility")), str(bonus2.get("hp"))])
		_check("加成面板攻击 +701", int(bonus2.get("attack", 0)) == 701, str(bonus2.get("attack")))
		_check("加成面板敏捷仍 +501", int(bonus2.get("agility", 0)) == 501, str(bonus2.get("agility")))
		_check("出战宠物攻击多吃了 701",
			absf((pet2.get_final_attack_with_equipment() - pet2.get_final_attack()) - 701.0) < 0.6,
			"差 %.2f" % (pet2.get_final_attack_with_equipment() - pet2.get_final_attack()))
		print("        基础攻击 %.2f → %.2f（升级会变，仅供参考）" % [atk_base, pet2.get_final_attack()])
	var bag_end: int = im.pet_equipment_items.size()
	print("        背包：%d → %d 件" % [bag_mid, bag_end])
	_check("背包又只少了 1 件", bag_end == bag_mid - 1, "%d → %d" % [bag_mid, bag_end])

	# 校验宠物详情「加成明细」里真的渲染出了装备那几行（折叠面板要点开）
	var pet_detail = pm.get_active_pet()
	main_ui.call("_show_pet_detail_popup", pet_detail)
	await create_timer(1.0).timeout
	var hit := _press_anywhere(["加成明细"])
	print("[probe] 展开「加成明细」按钮：", hit)
	await create_timer(0.8).timeout
	var nodes: Array = []
	_walk(get_root(), nodes)
	var labels: Array = []
	for n2 in nodes:
		if n2 is Label:
			labels.append(str((n2 as Label).text))
	var equip_rows: Array = labels.filter(func(s): return str(s).find("装备") >= 0)
	print("[probe] 详情面板里的装备加成行：", str(equip_rows))
	_check("宠物详情渲染出装备加成行", equip_rows.size() >= 2, str(equip_rows))

	if _shot_dir != "":
		var pet_now = pm.get_active_pet()
		main_ui.call("_show_pet_detail_popup", pet_now)
		await create_timer(1.0).timeout
		_press_anywhere(["加成明细"])
		await create_timer(0.8).timeout
		await _save_shot(_shot_dir + "/peq_detail.png")
		_press_anywhere(["关闭"], true)
		await create_timer(0.6).timeout
		main_ui.call("_show_pet_equipment_bonus_popup")
		await create_timer(1.0).timeout
		await _save_shot(_shot_dir + "/peq_bonus.png")

	print("\n" + ("ALL PASS" if _fails.is_empty() else "FAILED: " + str(_fails)))
	quit(0 if _fails.is_empty() else 2)


func _save_shot(path: String) -> void:
	await process_frame
	await process_frame
	var img: Image = get_root().get_texture().get_image()
	if img != null:
		img.save_png(path)
		print("[probe] 截图：", path)
