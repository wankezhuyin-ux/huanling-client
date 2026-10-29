extends RefCounted
class_name RealmUI

const GameData = preload("res://scripts/game_data.gd")
const UIConstants = preload("res://scripts/ui_constants.gd")
const ConfirmDialog = preload("res://ui/components/confirm_dialog.gd")

static func show(parent: Node, player, game_manager) -> Window:
	var window = Window.new()
	window.title = "角色信息"
	window.size = Vector2(600, 750)
	window.borderless = true
	window.transparent = true
	window.unresizable = true
	window.close_requested.connect( func(): window.queue_free())

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 15
	vbox.offset_top = 15
	vbox.offset_right = -15
	vbox.offset_bottom = -15
	vbox.add_theme_constant_override("separation", 10)

	var title_label = Label.new()
	title_label.text = "👤 角色信息"
	title_label.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title_label)

	var separator1 = HSeparator.new()
	vbox.add_child(separator1)

	var basic_section = _create_basic_section(player)
	vbox.add_child(basic_section)

	var separator2 = HSeparator.new()
	vbox.add_child(separator2)

	var points_section = _create_points_section(player, window, parent, game_manager)
	vbox.add_child(points_section)

	var separator3 = HSeparator.new()
	vbox.add_child(separator3)

	var realm_section = _create_realm_section(player, window, parent, game_manager)
	vbox.add_child(realm_section)

	var separator4 = HSeparator.new()
	vbox.add_child(separator4)

	var stats_section = _create_stats_section(player)
	vbox.add_child(stats_section)

	var btn_hbox = HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 15)
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var close_btn = Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(150, 45)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect( func(): window.queue_free())
	btn_hbox.add_child(close_btn)

	vbox.add_child(btn_hbox)

	panel.add_child(vbox)
	window.add_child(panel)
	parent.add_child(window)
	window.popup_centered()

	return window

static func _create_basic_section(player) -> Control:
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", 8)

	var basic_title = Label.new()
	basic_title.text = "📋 基本信息"
	basic_title.add_theme_font_size_override("font_size", 20)
	section.add_child(basic_title)

	var info_grid = GridContainer.new()
	info_grid.columns = 2
	info_grid.add_theme_constant_override("h_separation", 20)
	info_grid.add_theme_constant_override("v_separation", 6)

	var info_items = [
		["角色名称", player.player_name, Color(1, 1, 1)], 
		["等级", "Lv.%d" % player.level, Color(0.5, 1, 0.5)], 
		["境界", player.realm, _get_realm_color(player.realm)], 
		["转生次数", "%d次" % player.reincarnation, Color(0.072, 0.080, 0.079)], 
		["修行值", "%d" % player.cultivation, Color(1, 0.84, 0)], 
		["金币", "%d" % player.gold, Color(1, 0.84, 0)]
	]

	for item in info_items:
		var label_name = Label.new()
		label_name.text = item[0] + ":"
		label_name.add_theme_font_size_override("font_size", 16)
		label_name.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		info_grid.add_child(label_name)

		var label_value = Label.new()
		label_value.text = item[1]
		label_value.add_theme_font_size_override("font_size", 16)
		label_value.add_theme_color_override("font_color", item[2])
		info_grid.add_child(label_value)

	section.add_child(info_grid)

	var hp_mp_hbox = HBoxContainer.new()
	hp_mp_hbox.add_theme_constant_override("separation", 20)

	var hp_vbox = VBoxContainer.new()
	hp_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var hp_label = Label.new()
	hp_label.text = "生命: %d/%d" % [player.hp, player.max_hp]
	hp_label.add_theme_font_size_override("font_size", 18)
	hp_vbox.add_child(hp_label)

	var hp_bar = ProgressBar.new()
	hp_bar.value = player.get_hp_percent() * 100
	hp_bar.custom_minimum_size = Vector2(0, 18)
	hp_vbox.add_child(hp_bar)

	hp_mp_hbox.add_child(hp_vbox)

	var mp_vbox = VBoxContainer.new()
	mp_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var mp_label = Label.new()
	mp_label.text = "内力: %d/%d" % [player.mp, player.max_mp]
	mp_label.add_theme_font_size_override("font_size", 18)
	mp_vbox.add_child(mp_label)

	var mp_bar = ProgressBar.new()
	mp_bar.value = (float(player.mp) / player.max_mp) * 100
	mp_bar.custom_minimum_size = Vector2(0, 18)
	mp_vbox.add_child(mp_bar)

	hp_mp_hbox.add_child(mp_vbox)

	section.add_child(hp_mp_hbox)

	return section

static func _create_points_section(player, window: Window, parent: Node, game_manager) -> Control:
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", 8)

	var points_title = Label.new()
	points_title.text = "✨ 属性点分配 (可用: %d点)" % player.points
	points_title.add_theme_font_size_override("font_size", 20)
	points_title.add_theme_color_override("font_color", Color(1, 0.84, 0) if player.points > 0 else Color(0.5, 0.5, 0.5))
	section.add_child(points_title)

	var points_grid = GridContainer.new()
	points_grid.columns = 3
	points_grid.add_theme_constant_override("h_separation", 10)
	points_grid.add_theme_constant_override("v_separation", 8)

	var attributes = [
		{"name": "体力", "key": "vitality", "value": player.vitality, "color": Color(1, 0.5, 0.5)}, 
		{"name": "内力", "key": "magic", "value": player.magic, "color": Color(0.072, 0.080, 0.079)}, 
		{"name": "攻击", "key": "attack", "value": player.attack_base, "color": Color(1, 0.8, 0.3)}, 
		{"name": "防御", "key": "defense", "value": player.defense_base, "color": Color(0.5, 0.8, 0.5)}, 
		{"name": "敏捷", "key": "agility", "value": player.agility_base, "color": Color(0.5, 1, 1)}, 
		{"name": "生命", "key": "hp", "value": player.max_hp, "color": Color(1, 0.3, 0.3), "suffix": "+10/点"}
	]

	for attr in attributes:
		var name_label = Label.new()
		name_label.text = attr.name
		name_label.custom_minimum_size = Vector2(50, 0)
		name_label.add_theme_font_size_override("font_size", 16)
		name_label.add_theme_color_override("font_color", attr.color)
		points_grid.add_child(name_label)

		var value_label = Label.new()
		if attr.key == "hp":
			value_label.text = "%d %s" % [attr.value, attr.get("suffix", "")]
		else:
			value_label.text = "%d" % attr.value
		value_label.custom_minimum_size = Vector2(80, 0)
		value_label.add_theme_font_size_override("font_size", 16)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		points_grid.add_child(value_label)

		var add_btn = Button.new()
		add_btn.text = "+"
		add_btn.custom_minimum_size = Vector2(40, 32)
		add_btn.add_theme_font_size_override("font_size", 18)
		add_btn.disabled = true
		add_btn.tooltip_text = "属性点由服务端分配，请在人物属性界面操作"
		points_grid.add_child(add_btn)

	section.add_child(points_grid)

	if player.permanent_points > 0:
		var permanent_label = Label.new()
		permanent_label.text = "永久属性点: %d (来自转生)" % player.permanent_points
		permanent_label.add_theme_font_size_override("font_size", 18)
		permanent_label.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
		section.add_child(permanent_label)

	return section

static func _create_realm_section(player, window: Window, parent: Node, game_manager) -> Control:
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", 8)

	var realm_title = Label.new()
	realm_title.text = "🌟 境界突破"
	realm_title.add_theme_font_size_override("font_size", 20)
	section.add_child(realm_title)

	var current_realm_hbox = HBoxContainer.new()
	current_realm_hbox.add_theme_constant_override("separation", 15)

	var current_label = Label.new()
	current_label.text = "当前境界:"
	current_label.add_theme_font_size_override("font_size", 16)
	current_realm_hbox.add_child(current_label)

	var realm_value_label = Label.new()
	realm_value_label.text = player.realm
	realm_value_label.add_theme_font_size_override("font_size", 18)
	realm_value_label.add_theme_color_override("font_color", _get_realm_color(player.realm))
	current_realm_hbox.add_child(realm_value_label)

	section.add_child(current_realm_hbox)

	var element_collection = {}
	if game_manager and game_manager.pet_collection_manager:
		element_collection = game_manager.pet_collection_manager.get_all_element_collection_counts()

	var ascend_check = player.can_ascend(element_collection)
	var can_ascend = ascend_check.can_ascend
	var can_reincarnate = player.can_reincarnate()

	var ascend_vbox = VBoxContainer.new()
	ascend_vbox.add_theme_constant_override("separation", 5)

	var ascend_label = Label.new()
	var next_realm = GameData.get_next_realm(player.realm)
	if next_realm.is_empty():
		ascend_label.text = "已达最高境界！"
		ascend_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	else:
		var required_level = GameData.ASCENSION_CONDITIONS.get(player.realm, {}).get("required_level", 800)
		ascend_label.text = "飞升至【%s】需要: Lv.%d" % [next_realm, required_level]
		ascend_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7) if not can_ascend else Color(0.5, 1, 0.5))
	ascend_label.add_theme_font_size_override("font_size", 18)
	ascend_vbox.add_child(ascend_label)

	if next_realm == "大罗金仙":
		var collection_label = Label.new()
		var collection_text = "五行图鉴: "
		var all_met = true
		for element in ["金", "木", "水", "火", "土"]:
			var count = element_collection.get(element, 0)
			if count < 10:
				all_met = false
				collection_text += "%s(%d/10) " % [element, count]
			else:
				collection_text += "%s(✓) " % element
		collection_label.text = collection_text
		collection_label.add_theme_font_size_override("font_size", 14)
		collection_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5) if all_met else Color(1, 0.6, 0.6))
		ascend_vbox.add_child(collection_label)

	var ascend_hbox = HBoxContainer.new()
	ascend_hbox.add_theme_constant_override("separation", 15)
	ascend_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ascend_hbox.add_child(spacer)

	var ascend_btn = Button.new()
	ascend_btn.text = "飞升"
	ascend_btn.custom_minimum_size = Vector2(80, 35)
	ascend_btn.add_theme_font_size_override("font_size", 16)
	ascend_btn.add_theme_color_override("font_color", Color(1, 0.84, 0))
	ascend_btn.disabled = not can_ascend
	ascend_btn.pressed.connect( func():
		var confirm_msg = "确定要飞升至【%s】吗？\n飞升后等级将重置为1级。" % next_realm
		if next_realm == "大罗金仙":
			confirm_msg += "\n\n五行图鉴进度将保留。"
		ConfirmDialog.show(parent, "飞升确认", confirm_msg, 
			func():
				_RealmAscendCommitRunner.new().run(parent, window, player, game_manager)
		)
	)
	ascend_hbox.add_child(ascend_btn)

	ascend_vbox.add_child(ascend_hbox)
	section.add_child(ascend_vbox)

	var reincarnate_hbox = HBoxContainer.new()
	reincarnate_hbox.add_theme_constant_override("separation", 15)

	var reincarnate_label = Label.new()
	reincarnate_label.text = "转生需要: Lv.800 (当前: Lv.%d)" % player.level
	reincarnate_label.add_theme_font_size_override("font_size", 18)
	reincarnate_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7) if not can_reincarnate else Color(0.5, 1, 0.5))
	reincarnate_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reincarnate_hbox.add_child(reincarnate_label)

	var reincarnate_btn = Button.new()
	reincarnate_btn.text = "转生"
	reincarnate_btn.custom_minimum_size = Vector2(80, 35)
	reincarnate_btn.add_theme_font_size_override("font_size", 16)
	reincarnate_btn.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
	reincarnate_btn.disabled = not can_reincarnate
	reincarnate_btn.pressed.connect( func():
		ConfirmDialog.show(parent, "转生确认", 
			"确定要转生吗？\n转生后等级和境界将重置。\n第1～999次每次+25永久点，第1000次起每次+10。\n当前转生次数: %d" % player.reincarnation, 
			func():
				_RealmReincarnateCommitRunner.new().run(parent, window, player, game_manager)
		)
	)
	reincarnate_hbox.add_child(reincarnate_btn)

	section.add_child(reincarnate_hbox)

	return section

static func _create_stats_section(player) -> Control:
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", 8)

	var stats_title = Label.new()
	stats_title.text = "📊 战斗属性"
	stats_title.add_theme_font_size_override("font_size", 20)
	section.add_child(stats_title)

	var stats_grid = GridContainer.new()
	stats_grid.columns = 3
	stats_grid.add_theme_constant_override("h_separation", 15)
	stats_grid.add_theme_constant_override("v_separation", 6)

	var stats_items = [
		["攻击力", "%d" % player.get_attack(), Color(1, 0.8, 0.3)], 
		["防御力", "%d" % player.get_defense(), Color(0.5, 0.8, 0.5)], 
		["敏捷", "%d" % player.get_agility(), Color(0.5, 1, 1)], 
		["五行", player.element, Color(0.7, 0.7, 0.7)]
	]

	for item in stats_items:
		var label_name = Label.new()
		label_name.text = item[0] + ":"
		label_name.add_theme_font_size_override("font_size", 18)
		label_name.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		stats_grid.add_child(label_name)

		var label_value = Label.new()
		label_value.text = item[1]
		label_value.add_theme_font_size_override("font_size", 18)
		label_value.add_theme_color_override("font_color", item[2])
		stats_grid.add_child(label_value)

		var empty = Control.new()
		stats_grid.add_child(empty)

	section.add_child(stats_grid)

	return section

static func _get_realm_color(realm: String) -> Color:
	# 境界色阶：凡→散→地→天→大罗→天神 依次抬亮度与色相，
	# 全部压进墨纸能承受的饱和度（参考稿是纯绿/纯蓝/纯金，在宣纸上像荧光笔）。
	var colors = {
		"凡人": Color(0.700, 0.680, 0.630), 
		"散仙": Color(0.520, 0.720, 0.560), 
		"地仙": Color(0.480, 0.660, 0.800), 
		"天仙": Color(0.740, 0.640, 0.860), 
		"大罗金仙": Color(0.960, 0.780, 0.380), 
		"幻灵天神": Color(0.920, 0.550, 0.480)
	}
	return colors.get(realm, Color(1, 1, 1))



class _RealmAscendCommitRunner extends RefCounted:
	const _KEEP_META: = &"_realm_ascend_commit_runner_keepalive"

	func _unpin(window: Window) -> void :
		if is_instance_valid(window) and window.has_meta(_KEEP_META):
			window.remove_meta(_KEEP_META)

	func run(parent: Node, window: Window, player, game_manager):
		if is_instance_valid(window):
			window.set_meta(_KEEP_META, self)
		var can_commit: = false
		var sync_msg: = "当前网络同步异常，暂时无法执行飞升。\n请等待网络恢复后再试，避免进度回滚。"
		var net = game_manager.network if game_manager else null
		if net and net.has_method("can_commit_critical_op"):
			can_commit = bool(net.can_commit_critical_op())
			if net.has_method("get_sync_status_message"):
				sync_msg = str(net.get_sync_status_message()) + "\n请等待网络恢复后再试，避免进度回滚。"
		else:
			sync_msg = "未连接网络服务，暂时无法执行飞升。\n请登录后重试。"
		if not can_commit:
			RealmUI._show_result_dialog(parent, "同步异常", sync_msg, Color(1, 0.5, 0.5))
			RealmUI._refresh_window(window, parent, player, game_manager)
			_unpin(window)
			return
		var ec = {}
		if game_manager and game_manager.pet_collection_manager:
			ec = game_manager.pet_collection_manager.get_all_element_collection_counts()
		var snapshot = game_manager.create_secure_op_snapshot()
		var commit_result: Dictionary = await game_manager.commit_realm_transition(snapshot, "飞升", func() -> Dictionary:
			return player.ascend(ec)
		)
		if not bool(commit_result.get("success", false)):
			RealmUI._show_result_dialog(parent, "同步失败", str(commit_result.get("message", "飞升结果同步失败，已回滚。")), Color(1, 0.5, 0.5))
			RealmUI._refresh_window(window, parent, player, game_manager)
			_unpin(window)
			return
		var result: Dictionary = commit_result.get("transition_result", {}) if commit_result.get("transition_result") is Dictionary else {}
		if not bool(result.get("success", false)):
			RealmUI._show_result_dialog(parent, "飞升失败", str(result.get("message", "飞升失败")), Color(1, 0.5, 0.5))
			RealmUI._refresh_window(window, parent, player, game_manager)
			_unpin(window)
			return
		RealmUI._show_result_dialog(parent, "飞升成功", str(result.get("message", "")), Color(1, 0.84, 0))
		RealmUI._refresh_window(window, parent, player, game_manager)
		_unpin(window)

class _RealmReincarnateCommitRunner extends RefCounted:
	const _KEEP_META: = &"_realm_reincarnate_commit_runner_keepalive"

	func _unpin(window: Window) -> void :
		if is_instance_valid(window) and window.has_meta(_KEEP_META):
			window.remove_meta(_KEEP_META)

	func run(parent: Node, window: Window, player, game_manager):
		if is_instance_valid(window):
			window.set_meta(_KEEP_META, self)
		var can_commit: = false
		var sync_msg: = "当前网络同步异常，暂时无法执行投胎。\n请等待网络恢复后再试，避免进度回滚。"
		var net = game_manager.network if game_manager else null
		if net and net.has_method("can_commit_critical_op"):
			can_commit = bool(net.can_commit_critical_op())
			if net.has_method("get_sync_status_message"):
				sync_msg = str(net.get_sync_status_message()) + "\n请等待网络恢复后再试，避免进度回滚。"
		else:
			sync_msg = "未连接网络服务，暂时无法执行投胎。\n请登录后重试。"
		if not can_commit:
			RealmUI._show_result_dialog(parent, "同步异常", sync_msg, Color(1, 0.5, 0.5))
			RealmUI._refresh_window(window, parent, player, game_manager)
			_unpin(window)
			return
		var snapshot = game_manager.create_secure_op_snapshot()
		var commit_result: Dictionary = await game_manager.commit_realm_transition(snapshot, "投胎", func() -> Dictionary:
			return player.reincarnate()
		)
		if not bool(commit_result.get("success", false)):
			RealmUI._show_result_dialog(parent, "同步失败", str(commit_result.get("message", "转生结果同步失败，已回滚。")), Color(1, 0.5, 0.5))
			RealmUI._refresh_window(window, parent, player, game_manager)
			_unpin(window)
			return
		var result: Dictionary = commit_result.get("transition_result", {}) if commit_result.get("transition_result") is Dictionary else {}
		if not bool(result.get("success", false)):
			RealmUI._show_result_dialog(parent, "转生失败", str(result.get("message", "转生失败")), Color(1, 0.5, 0.5))
			RealmUI._refresh_window(window, parent, player, game_manager)
			_unpin(window)
			return
		RealmUI._show_result_dialog(parent, "转生成功", str(result.get("message", "")), Color(0.072, 0.080, 0.079))
		RealmUI._refresh_window(window, parent, player, game_manager)
		_unpin(window)

static func _show_result_dialog(parent: Node, title: String, message: String, color: Color):
	var window = Window.new()
	window.title = title
	window.size = Vector2(400, 200)
	window.borderless = true
	window.transparent = true
	window.unresizable = true
	window.close_requested.connect( func(): window.queue_free())

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 15)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", color)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	var msg_label = Label.new()
	msg_label.text = message
	msg_label.add_theme_font_size_override("font_size", 16)
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(msg_label)

	var close_btn = Button.new()
	close_btn.text = "确定"
	close_btn.custom_minimum_size = Vector2(100, 40)
	close_btn.pressed.connect( func(): window.queue_free())
	vbox.add_child(close_btn)

	panel.add_child(vbox)
	window.add_child(panel)


	var scene_root = Engine.get_main_loop().current_scene
	if scene_root:
		scene_root.add_child(window)
		window.popup_centered()
	else:
		parent.add_child(window)
		window.popup_centered()

static func _refresh_window(old_window: Window, parent: Node, player, game_manager):
	old_window.queue_free()
	await old_window.tree_exited
	show(parent, player, game_manager)
