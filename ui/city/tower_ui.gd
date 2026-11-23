extends RefCounted

const GameData = preload("res://scripts/game_data.gd")
const VipBenefits = preload("res://scripts/vip_benefits.gd")
const UIStyle = preload("res://scripts/ui_style.gd")
const Monster = preload("res://scripts/monster.gd")

const MAX_TOWER_FLOOR = 2000

const TOWER_BATTLE_MAX_ROUNDS: = 30
const FLOORS_PER_TAB = 100
const CHALLENGE_COST = 1000000
const MAX_VISIBLE_TABS = 5

static var _runtime_cfg: Dictionary = {}

static func apply_runtime_config(cfg: Dictionary) -> void :
	_runtime_cfg = cfg if cfg is Dictionary else {}

static func _monster_cfg() -> Dictionary:
	var m = _runtime_cfg.get("monsters", {})
	return m if m is Dictionary else {}


static func _resolve_floor_segment(floor: int) -> Dictionary:
	var m: = _monster_cfg()
	var raw = m.get("floorSegmentScales", [])
	if not (raw is Array):
		return {}
	var f: = maxi(1, floor)
	var best: Dictionary = {}
	var best_from: = -1
	for row in raw:
		if not (row is Dictionary):
			continue
		var from_f: = int(row.get("fromFloor", 0))
		if from_f >= 1 and f >= from_f and from_f > best_from:
			best_from = from_f
			best = row
	return best

static func _segment_stat_coeffs(segment: Dictionary) -> Dictionary:
	if segment.is_empty():
		return {"attack": 1.0, "defense": 1.0, "agility": 1.0, "hp": 1.0}
	return {
		"attack": maxf(0.0, float(segment.get("attack", 1.0))), 
		"defense": maxf(0.0, float(segment.get("defense", 1.0))), 
		"agility": maxf(0.0, float(segment.get("agility", 1.0))), 
		"hp": maxf(0.0, float(segment.get("hp", 1.0))), 
	}

static func _open_max_floor() -> int:
	var v: = int(_runtime_cfg.get("openMaxFloor", 1499))
	return v if v > 0 else 1499

static func _open_closed_message() -> String:
	return str(_runtime_cfg.get("openMaxFloorClosedMessage", "暂未开放"))


static func _required_reincarnation_for_floor(floor: int) -> int:
	var every: = int(_runtime_cfg.get("floorGiftEvery", 100))
	if every < 1:
		every = 100
	if floor < every or floor % every != 0:
		return 0
	var gates = _runtime_cfg.get("reincarnationGates", [])
	if not (gates is Array):
		return 0
	for row in gates:
		if not (row is Dictionary):
			continue
		if int(row.get("floor", 0)) == floor:
			return maxi(0, int(row.get("required", 0)))
	return 0

static func _reincarnation_block_message(floor: int, player_rei: int, required: int) -> String:
	return "挑战第%d层需要投胎数≥%d（当前%d）" % [floor, required, player_rei]

static func _tower_battle_max_rounds() -> int:
	var v: = int(_runtime_cfg.get("battleMaxRounds", TOWER_BATTLE_MAX_ROUNDS))
	return v if v > 0 else TOWER_BATTLE_MAX_ROUNDS

static func _max_tower_floor(game_manager = null) -> int:
	if game_manager != null and game_manager.has_method("get_max_tower_floor"):
		var v: = int(game_manager.get_max_tower_floor())
		return v if v > 0 else MAX_TOWER_FLOOR
	return MAX_TOWER_FLOOR

static func _find_existing_child_popup(parent_control: Control, popup_key: String) -> Control:
	if not is_instance_valid(parent_control):
		return null
	for child in parent_control.get_children():
		if child is Control and str(child.get_meta("popup_key", "")) == popup_key:
			return child
	return null

static func _focus_existing_child_popup(parent_control: Control, popup_key: String) -> bool:
	var existing = _find_existing_child_popup(parent_control, popup_key)
	if existing and is_instance_valid(existing):
		existing.show()
		existing.grab_focus()
		return true
	return false

static func _mark_popup_key(popup: Node, popup_key: String) -> void :
	if popup:
		popup.set_meta("popup_key", popup_key)


static func _enable_touch_drag_passthrough(root: Control) -> void :
	if root == null:
		return
	var root_keep_input: = (root is BaseButton) or (root is LineEdit) or (root is TextEdit) or (root is OptionButton) or (root is ScrollContainer)
	if not root_keep_input:
		root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in root.get_children():
		if not (child is Control):
			continue
		var c: = child as Control
		var keep_input: = (c is BaseButton) or (c is LineEdit) or (c is TextEdit) or (c is OptionButton) or (c is ScrollContainer)
		if not keep_input:
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_enable_touch_drag_passthrough(c)

static func _find_existing_window_popup(popup_key: String) -> Window:
	var scene_root = Engine.get_main_loop().current_scene
	if not scene_root:
		return null
	for child in scene_root.get_children():
		if child is Window and str(child.get_meta("popup_key", "")) == popup_key:
			return child
	return null

static func _focus_existing_window_popup(popup_key: String) -> bool:
	var existing = _find_existing_window_popup(popup_key)
	if existing and is_instance_valid(existing):
		existing.show()
		existing.grab_focus()
		return true
	return false

static func create_fullscreen(game_manager, target_floor: int = -1) -> Control:
	# 版本标记：线上排查时要能一眼确认 APK 里跑的是哪一版天关页
	print("[TowerUI] rev=v20261104_create_fullscreen player=%s" % str(game_manager != null and game_manager.player != null))
	if game_manager == null or game_manager.player == null:
		push_warning("[TowerUI] create_fullscreen: 玩家数据未就绪")
		var fallback: = Panel.new()
		fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
		fallback.add_theme_stylebox_override("panel", UIStyle.create_panel_style())
		var tip: = Label.new()
		tip.text = "玩家数据加载中，请稍后重试"
		tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tip.set_anchors_preset(Control.PRESET_FULL_RECT)
		fallback.add_child(tip)
		return fallback
	if game_manager != null and game_manager.has_method("get_tower_runtime_config"):
		apply_runtime_config(game_manager.get_tower_runtime_config())
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", UIStyle.create_panel_style())

	var vbox = UIStyle.create_base_vbox()
	panel.add_child(vbox)

	var title = UIStyle.create_title_label("⚔️ 无限天关")
	vbox.add_child(title)


	var info_panel = Panel.new()
	info_panel.custom_minimum_size = Vector2(0, 100)
	info_panel.add_theme_stylebox_override("panel", UIStyle.create_item_style())
	vbox.add_child(info_panel)

	var info_hbox = HBoxContainer.new()
	info_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	info_hbox.offset_left = 15
	info_hbox.offset_top = 10
	info_hbox.offset_right = -15
	info_hbox.offset_bottom = -10
	info_panel.add_child(info_hbox)


	var player_info = VBoxContainer.new()
	player_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_info.add_theme_constant_override("separation", 4)
	info_hbox.add_child(player_info)

	var player_name_label = Label.new()
	player_name_label.text = "玩家: %s" % game_manager.player.player_name
	player_name_label.add_theme_font_size_override("font_size", 14)
	player_name_label.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
	player_info.add_child(player_name_label)

	var player_level_label = Label.new()
	player_level_label.text = "等级: %d | 境界: %s" % [game_manager.player.level, game_manager.player.realm]
	player_level_label.add_theme_font_size_override("font_size", 12)
	player_level_label.add_theme_color_override("font_color", Color(0.734, 0.714, 0.657))
	player_info.add_child(player_level_label)

	var player_gold_label = Label.new()
	player_gold_label.text = "金币: %s" % _format_number(game_manager.player.gold)
	player_gold_label.add_theme_font_size_override("font_size", 12)
	player_gold_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	player_info.add_child(player_gold_label)


	var tower_info = VBoxContainer.new()
	tower_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tower_info.add_theme_constant_override("separation", 4)
	info_hbox.add_child(tower_info)

	var highest_label = Label.new()
	highest_label.text = "历史最高: 第 %d 层" % game_manager.player.tower_highest
	highest_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	highest_label.add_theme_font_size_override("font_size", 14)
	highest_label.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
	tower_info.add_child(highest_label)

	var current_floor_label = Label.new()
	current_floor_label.text = "当前进度: 第 %d 层" % game_manager.player.tower_floor
	current_floor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	current_floor_label.add_theme_font_size_override("font_size", 12)
	current_floor_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	tower_info.add_child(current_floor_label)

	var cost_label = Label.new()
	cost_label.text = "新关卡消耗: 100万金币"
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cost_label.add_theme_font_size_override("font_size", 12)
	cost_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.6))
	tower_info.add_child(cost_label)


	var tab_container = HBoxContainer.new()
	tab_container.add_theme_constant_override("separation", 5)
	vbox.add_child(tab_container)


	var content_container = VBoxContainer.new()
	content_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_container.add_theme_constant_override("separation", 10)
	vbox.add_child(content_container)


	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	content_container.add_child(scroll)

	var floors_container = VBoxContainer.new()
	floors_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	floors_container.add_theme_constant_override("separation", 6)
	scroll.add_child(floors_container)


	var btn_hbox = HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(btn_hbox)


	var sweep_all_btn = Button.new()
	var max_sweeps = VipBenefits.tower_sweep_limit(VipBenefits.tier_from_player(game_manager.player))
	var remaining = max_sweeps - game_manager.player.tower_sweep_count
	sweep_all_btn.text = "一键扫荡 (%d/%d)" % [remaining, max_sweeps]
	sweep_all_btn.set_meta("base_text", "一键扫荡")
	sweep_all_btn.custom_minimum_size = Vector2(140, 50)
	sweep_all_btn.add_theme_font_size_override("font_size", 18)
	UIStyle.apply_button_style(sweep_all_btn)
	sweep_all_btn.pressed.connect( func():
		_sweep_all_cleared_floors(panel, game_manager, sweep_all_btn)
	)
	btn_hbox.add_child(sweep_all_btn)

	var rank_btn = Button.new()
	rank_btn.text = "🏆 排行榜"
	rank_btn.custom_minimum_size = Vector2(120, 50)
	rank_btn.add_theme_font_size_override("font_size", 20)
	UIStyle.apply_button_style(rank_btn)
	rank_btn.pressed.connect( func():
		_show_ranking_fullscreen(panel, game_manager)
	)
	btn_hbox.add_child(rank_btn)


	panel.set_meta("game_manager", game_manager)
	panel.set_meta("floors_container", floors_container)
	panel.set_meta("tab_container", tab_container)
	panel.set_meta("scroll", scroll)
	panel.set_meta("target_floor", target_floor)
	# 「这一页最外层要销毁哪个节点」。天关页现在被 TowerHubUI 包了一层
	# （无限天关 / 兄弟天关两个 tab），包的那层会把 page_root 改成它自己。
	# 不这么做的话，点挑战只销毁里面这层内容，外面剩两个空 tab —— 线上那张
	# 「点挑战 → 界面只剩两个 tab、下面全空」的截图就是这么来的。
	panel.set_meta("page_root", panel)


	var refresh_view: = func() -> void :
		if not is_instance_valid(panel):
			return
		_refresh_tower_floor_view(panel, game_manager)
	if panel.is_inside_tree():
		refresh_view.call()
	else:
		panel.tree_entered.connect(refresh_view, CONNECT_ONE_SHOT)


	_sync_tower_data(panel, game_manager)

	return panel


static func _sync_tower_data(panel: Control, game_manager):
	var network = game_manager.network
	if not network or not network.is_logged_in():
		return


	network.tower_info_loaded.connect( func(server_highest: int, sweep_count: int, server_floor: int):
		# 只取较大值：服务端若因旧存档/网络抖动返回了落后的层号，
		# 不能把玩家本地已经闯到的层数打回第 1 关（原版口径是进度一直保留）。
		game_manager.player.tower_highest = maxi(int(game_manager.player.tower_highest), server_highest)
		if server_floor > 0:
			game_manager.player.tower_floor = maxi(int(game_manager.player.tower_floor), server_floor)
		elif game_manager.player.tower_floor <= 0:
			game_manager.player.tower_floor = max(1, game_manager.player.tower_highest + 1)
		game_manager.player.tower_sweep_count = sweep_count
		if panel and is_instance_valid(panel):
			_refresh_tower_floor_view(panel, game_manager)
	, CONNECT_ONE_SHOT)


	network.get_tower_info()

static func _refresh_tower_floor_view(panel: Control, game_manager, tab_index: int = -1) -> void :
	if not is_instance_valid(panel):
		return
	print("[TowerUI] refresh 开始 panel_size=%s vis=%s cfg_keys=%d" % [
		str(panel.size), str(panel.visible), _runtime_cfg.size()])
	var target_tab: = tab_index
	if target_tab < 0:
		target_tab = _tab_index_for_floor(_resolve_target_floor(panel, game_manager), game_manager)
	panel.set_meta("current_tab", target_tab)
	_create_tabs(panel, game_manager)
	_show_floors_by_tab(panel, target_tab)

static func _resolve_target_floor(panel: Control, game_manager) -> int:
	var target_floor = int(panel.get_meta("target_floor", -1))
	if target_floor > 0:
		return clampi(target_floor, 1, _max_tower_floor(game_manager))
	var highest: = int(game_manager.player.tower_highest)
	var current_floor: = int(game_manager.player.tower_floor)
	if current_floor <= 0:
		current_floor = highest + 1
	else:
		current_floor = maxi(current_floor, highest + 1)
	return clampi(current_floor, 1, _max_tower_floor(game_manager))

static func _tab_index_for_floor(floor: int, game_manager = null) -> int:
	var safe_floor = clampi(floor, 1, _max_tower_floor(game_manager))
	return int((safe_floor - 1) / FLOORS_PER_TAB)

static func _create_tabs(panel: Control, game_manager):
	var tab_container = panel.get_meta("tab_container") as HBoxContainer


	for child in tab_container.get_children():
		child.queue_free()

	var max_floor: = _max_tower_floor(game_manager)
	var max_tab = int(max_floor / FLOORS_PER_TAB) - 1
	var available_tab = int(game_manager.player.tower_highest / FLOORS_PER_TAB)
	max_tab = clampi(available_tab, 0, max_tab)

	var selected_tab = int(panel.get_meta("current_tab", 0))
	selected_tab = clampi(selected_tab, 0, max_tab)

	var start_tab = maxi(0, max_tab - (MAX_VISIBLE_TABS - 1))
	for i in range(max_tab + 1):
		if i < start_tab:
			continue
		var start_floor = i * FLOORS_PER_TAB + 1
		var end_floor = min((i + 1) * FLOORS_PER_TAB, max_floor)

		var tab_btn = Button.new()
		tab_btn.text = "%d-%d层" % [start_floor, end_floor]
		tab_btn.custom_minimum_size = Vector2(100, 45)
		tab_btn.add_theme_font_size_override("font_size", 20)
		tab_btn.set_meta("tower_tab_index", i)
		UIStyle.apply_tab_style(tab_btn, i == selected_tab)

		tab_btn.pressed.connect( func():
			var selected: = int(tab_btn.get_meta("tower_tab_index"))
			for btn in tab_container.get_children():
				UIStyle.apply_tab_style(btn as Button, int(btn.get_meta("tower_tab_index", -1)) == selected)
			panel.set_meta("current_tab", selected)
			_show_floors_by_tab(panel, selected)
		)

		tab_container.add_child(tab_btn)

static func _is_floor_view_gen_current(panel: Control, my_gen: int) -> bool:
	return is_instance_valid(panel) and int(panel.get_meta("floor_view_gen", -1)) == my_gen

static func _scroll_to_tower_floor(panel: Control, scroll: ScrollContainer, floors_container: VBoxContainer, target_floor: int, start_floor: int, my_gen: int) -> void :
	if not _is_floor_view_gen_current(panel, my_gen):
		return
	var target_index: = target_floor - start_floor
	if target_index < 0 or target_index >= floors_container.get_child_count():
		return
	var target_child: = floors_container.get_child(target_index)
	if not is_instance_valid(scroll) or not is_instance_valid(target_child):
		return
	var tree: = panel.get_tree()
	if not tree:
		return
	for _i in range(3):
		await tree.process_frame
		if not _is_floor_view_gen_current(panel, my_gen):
			return
	floors_container.update_minimum_size()
	await tree.process_frame
	if not _is_floor_view_gen_current(panel, my_gen):
		return
	var vbar: = scroll.get_v_scroll_bar()
	if vbar:
		var last_max: = -1.0
		var stable_count: = 0
		for _i in range(10):
			await tree.process_frame
			if not _is_floor_view_gen_current(panel, my_gen):
				return
			if is_equal_approx(vbar.max_value, last_max):
				stable_count += 1
				if stable_count >= 2:
					break
			else:
				stable_count = 0
			last_max = vbar.max_value
	if not _is_floor_view_gen_current(panel, my_gen):
		return
	scroll.ensure_control_visible(target_child)
	var target_y: = int(target_child.position.y)
	if target_y > 0 and scroll.scroll_vertical < target_y - 10:
		scroll.scroll_vertical = target_y
	await tree.process_frame
	if not _is_floor_view_gen_current(panel, my_gen):
		return
	scroll.ensure_control_visible(target_child)
	tree.create_timer(0.0).timeout.connect( func() -> void :
		if not _is_floor_view_gen_current(panel, my_gen):
			return
		if not is_instance_valid(scroll) or not is_instance_valid(target_child):
			return
		scroll.ensure_control_visible(target_child)
		var deferred_y: = int(target_child.position.y)
		if deferred_y > 0 and scroll.scroll_vertical < deferred_y - 10:
			scroll.scroll_vertical = deferred_y
	, CONNECT_ONE_SHOT)

static func _show_floors_by_tab(panel: Control, tab_index: int):
	var my_gen: = int(panel.get_meta("floor_view_gen", 0)) + 1
	panel.set_meta("floor_view_gen", my_gen)
	var floors_container = panel.get_meta("floors_container") as VBoxContainer
	var game_manager = panel.get_meta("game_manager")


	for child in floors_container.get_children():
		child.queue_free()
	if not _is_floor_view_gen_current(panel, my_gen):
		return

	var start_floor: int = tab_index * FLOORS_PER_TAB + 1
	var end_floor: int = mini((tab_index + 1) * FLOORS_PER_TAB, _max_tower_floor(game_manager))
	var current_floor = game_manager.player.tower_floor
	var highest_floor = game_manager.player.tower_highest
	var scroll_target_floor: = _resolve_target_floor(panel, game_manager)

	const FLOOR_ROW_BATCH_SIZE: = 10
	var floor: int = start_floor
	while floor <= end_floor:
		if not _is_floor_view_gen_current(panel, my_gen):
			return
		var batch_end: int = mini(floor + FLOOR_ROW_BATCH_SIZE - 1, end_floor)
		for batch_floor in range(floor, batch_end + 1):
			_create_floor_row_fullscreen(floors_container, batch_floor, game_manager, current_floor, highest_floor, panel)
		floor = batch_end + 1
		if floor <= end_floor and panel.get_tree():
			await panel.get_tree().process_frame
			if not _is_floor_view_gen_current(panel, my_gen):
				return

	if not panel.get_tree():
		return
	print("[TowerUI] 层列表生成完成 tab=%d 行数=%d 容器高=%d" % [
		tab_index, floors_container.get_child_count(), int(floors_container.size.y)])
	# 兜底：一行都没生成时给玩家一句话，别留一片纯黑（线上就出现过这种观感）
	if floors_container.get_child_count() == 0:
		var empty_tip: = Label.new()
		empty_tip.text = "本页暂无可挑战的层，请返回重进"
		empty_tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_tip.add_theme_font_size_override("font_size", 16)
		empty_tip.add_theme_color_override("font_color", Color(0.734, 0.714, 0.657))
		empty_tip.custom_minimum_size = Vector2(0, 80)
		floors_container.add_child(empty_tip)
	var scroll = panel.get_meta("scroll") as ScrollContainer
	await _scroll_to_tower_floor(panel, scroll, floors_container, scroll_target_floor, start_floor, my_gen)

static func _create_floor_row_fullscreen(container: VBoxContainer, floor: int, game_manager, 
		current_floor: int, highest_floor: int, panel: Control):

	var floor_panel = Panel.new()
	floor_panel.custom_minimum_size = Vector2(0, 70)
	floor_panel.mouse_filter = Control.MOUSE_FILTER_PASS

	var is_cleared = floor < current_floor
	var is_current = floor == current_floor
	var is_locked = floor > current_floor

	var style = UIStyle.create_item_style()
	# 已通关/当前层/未开放：原来分别用绿底、铜底、灰蓝底，
	# 三套色相压在墨底上像三种材质。统一墨底，用金线亮度 + 前缀符号分层。
	if is_cleared:
		style.bg_color = Color(0.038, 0.046, 0.044, 0.80)
		style.border_color = Color(0.788, 0.635, 0.294, 0.26)
	elif is_current:
		style.bg_color = Color(0.092, 0.076, 0.044, 0.92)
		style.border_color = Color(0.900, 0.760, 0.420, 0.95)
	else:
		style.bg_color = Color(0.048, 0.057, 0.059, 0.7)
		style.border_color = Color(0.655, 0.531, 0.245, 0.6)

	floor_panel.add_theme_stylebox_override("panel", style)
	container.add_child(floor_panel)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 15
	hbox.offset_top = 8
	hbox.offset_right = -15
	hbox.offset_bottom = -8
	floor_panel.add_child(hbox)


	var floor_info = VBoxContainer.new()
	floor_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	floor_info.add_theme_constant_override("separation", 2)
	hbox.add_child(floor_info)


	var floor_data = get_floor_data(floor)


	var line1 = HBoxContainer.new()
	line1.add_theme_constant_override("separation", 10)
	floor_info.add_child(line1)

	var floor_title = Label.new()
	floor_title.add_theme_font_size_override("font_size", 16)

	if is_cleared:
		floor_title.text = "✓ 第 %d 层" % floor
		floor_title.add_theme_color_override("font_color", Color(0.4, 0.8, 0.5))
	elif is_current:
		floor_title.text = "⚔ 第 %d 层 (当前)" % floor
		floor_title.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	else:
		floor_title.text = "🔒 第 %d 层" % floor
		floor_title.add_theme_color_override("font_color", Color(0.631, 0.611, 0.564))

	line1.add_child(floor_title)


	var monster_info = Label.new()
	monster_info.text = "%s Lv.%d [%s]" % [floor_data.monster_name, floor_data.level, floor_data.monster_element]
	monster_info.add_theme_font_size_override("font_size", 20)
	monster_info.add_theme_color_override("font_color", Color(0.9, 0.6, 0.4))
	line1.add_child(monster_info)


	if floor % 10 == 0:
		var boss_label = Label.new()
		boss_label.text = "[BOSS]"
		boss_label.add_theme_font_size_override("font_size", 12)
		boss_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		line1.add_child(boss_label)


	if floor % 100 == 0:
		var milestone_label = Label.new()
		milestone_label.text = "[★里程碑★]"
		milestone_label.add_theme_font_size_override("font_size", 12)
		milestone_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
		line1.add_child(milestone_label)


	var rewards_label = Label.new()
	rewards_label.text = "金币:%s" % _format_number(floor_data.gold_reward)
	rewards_label.add_theme_font_size_override("font_size", 12)
	rewards_label.add_theme_color_override("font_color", Color(0.734, 0.714, 0.657))
	floor_info.add_child(rewards_label)


	var btn_vbox = VBoxContainer.new()
	btn_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(btn_vbox)

	if is_current:
		var challenge_btn = Button.new()
		challenge_btn.text = "⚔️ 挑战"
		challenge_btn.custom_minimum_size = Vector2(110, 48)
		challenge_btn.add_theme_font_size_override("font_size", 18)
		UIStyle.apply_golden_button_style(challenge_btn)
		UIStyle.setup_button_animation(challenge_btn)
		challenge_btn.set_meta("base_text", "⚔️ 挑战")
		challenge_btn.pressed.connect( func():
			_challenge_floor_fullscreen(floor, game_manager, panel, challenge_btn)
		)
		btn_vbox.add_child(challenge_btn)
	elif is_cleared:
		var cleared_label = Label.new()
		cleared_label.text = "已通关"
		cleared_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cleared_label.add_theme_font_size_override("font_size", 12)
		cleared_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.5))
		btn_vbox.add_child(cleared_label)

static func get_floor_data(floor: int) -> Dictionary:
	var m: = _monster_cfg()
	var level_base: = int(m.get("levelBase", 100))
	var level_per: = int(m.get("levelPerFloor", 10))
	var level = level_base + floor * level_per
	var segment: = _resolve_floor_segment(floor)
	var high_start: = int(m.get("highTierStartFloor", 1300))
	var monster_count: int
	if not segment.is_empty():
		if floor % 100 == 0:
			monster_count = int(segment.get("every100Count", 1))
		elif floor % 10 == 0:
			monster_count = int(segment.get("every10Count", 1))
		else:
			monster_count = int(segment.get("normalCount", 1))
	elif floor >= high_start:
		if floor % 10 == 0:
			monster_count = int(m.get("highTierEvery10Count", 2))
		else:
			monster_count = int(m.get("highTierNormalCount", 5))
	elif floor % 100 == 0:
		monster_count = int(m.get("every100MonsterCount", 1))
	elif floor % 10 == 0:
		monster_count = int(m.get("every10MonsterCount", 1))
	else:
		monster_count = int(m.get("normalMonsterCount", 3))
	monster_count = maxi(1, monster_count)
	var cycle_every: = int(m.get("cycleEveryFloors", 1000))
	if cycle_every < 1:
		cycle_every = 1000
	var cycle_bonus = int((maxi(1, floor) - 1) / cycle_every)
	var cycle_stat_bonus: float = float(cycle_bonus) * float(m.get("cycleBonusPerCycle", 0.2))

	var exp_reward = 0
	var gold_reward = 100 * floor

	var monster_name = "天关守卫"
	var monster_type = "balanced"
	var stat_multiplier = 1.0 + cycle_stat_bonus
	if floor % 100 == 0:
		monster_name = "天关霸主"
		monster_type = "balanced"
		stat_multiplier = float(m.get("every100StatBase", 1.5)) + cycle_stat_bonus
	elif floor % 10 == 0:
		monster_name = "天关统领"
		monster_type = "attack_defense"
		stat_multiplier = 1.2 + cycle_stat_bonus + float(m.get("every10StatBonus", 0.5))
	else:
		var types_raw = m.get("normalFloorTypes", ["full_attack", "defense_agility", "attack_agility", "attack_defense", "balanced"])
		var types: Array = types_raw if types_raw is Array else ["full_attack", "defense_agility", "attack_agility", "attack_defense", "balanced"]
		if types.size() > 0:
			monster_type = str(types[(floor - 1) % types.size()])

	var elements_raw = m.get("elements", ["金", "木", "水", "火", "土"])
	var elements: Array = elements_raw if elements_raw is Array else ["金", "木", "水", "火", "土"]
	var monster_element = str(elements[(floor - 1) % maxi(1, elements.size())])
	var coeffs: = _segment_stat_coeffs(segment)

	return {
		"level": level, 
		"monster_count": monster_count, 
		"exp_reward": exp_reward, 
		"gold_reward": gold_reward, 
		"monster_name": monster_name, 
		"monster_element": monster_element, 
		"monster_type": monster_type, 
		"stat_multiplier": stat_multiplier, 
		"stat_coeffs": coeffs, 
		"hp_per_level": int(m.get("hpPerLevel", 50)), 
	}

static func _get_tower_type_ratios(monster_type: String) -> Dictionary:
	var cfg_ratios = _monster_cfg().get("typeRatios", {})
	if cfg_ratios is Dictionary and cfg_ratios.has(monster_type):
		var row = cfg_ratios[monster_type]
		if row is Dictionary:
			return {
				"attack": int(row.get("attack", 5)), 
				"defense": int(row.get("defense", 5)), 
				"agility": int(row.get("agility", 5)), 
			}
	match monster_type:
		"full_attack":
			return {"attack": 10, "defense": 3, "agility": 2}
		"attack_defense":
			return {"attack": 7, "defense": 6, "agility": 2}
		"attack_agility":
			return {"attack": 8, "defense": 2, "agility": 5}
		"defense_agility":
			return {"attack": 3, "defense": 7, "agility": 5}
		"balanced":
			return {"attack": 5, "defense": 5, "agility": 5}
		_:
			return {"attack": 5, "defense": 5, "agility": 5}

static func _get_tower_type_display_name(monster_type: String) -> String:
	match monster_type:
		"full_attack":
			return "全攻型"
		"attack_defense":
			return "攻防型"
		"attack_agility":
			return "攻敏型"
		"defense_agility":
			return "防敏型"
		"balanced":
			return "均衡型"
		_:
			return "均衡型"


static func _aggregate_gift_items_for_display(items: Array) -> Array:
	var name_to_count: = {}
	for it in items:
		if it is Dictionary:
			var d: Dictionary = it
			var item_name: = str(d.get("name", "")).strip_edges()
			if item_name.is_empty():
				continue
			var c: = int(d.get("count", 1))
			name_to_count[item_name] = int(name_to_count.get(item_name, 0)) + c
	var names: Array = name_to_count.keys()
	names.sort()
	var out: Array = []
	for nm in names:
		out.append({"name": str(nm), "count": int(name_to_count[nm])})
	return out

static func create_tower_monsters(floor: int) -> Array:
	return _create_tower_monsters(floor)

static func _create_tower_monsters(floor: int) -> Array:
	var floor_data = get_floor_data(floor)
	var monsters = []
	var ratios = _get_tower_type_ratios(str(floor_data.get("monster_type", "balanced")))
	var base_stat = int(floor_data.get("level", 1))
	var multiplier = float(floor_data.get("stat_multiplier", 1.0))
	var coeffs_raw = floor_data.get("stat_coeffs", {})
	var coeffs: Dictionary = coeffs_raw if coeffs_raw is Dictionary else {"attack": 1.0, "defense": 1.0, "agility": 1.0, "hp": 1.0}


	var texture_id = "tower_guard"
	if floor_data.monster_name == "天关霸主":
		texture_id = "tower_overlord"
	elif floor_data.monster_name == "天关统领":
		texture_id = "tower_commander"

	for i in range(floor_data.monster_count):
		var hp_mul: = int(floor_data.get("hp_per_level", 50))
		var monster_data = {
			"name": floor_data.monster_name, 
			"level": floor_data.level, 
			"element": floor_data.monster_element, 
			"attack": int(base_stat * int(ratios.get("attack", 5)) * multiplier * float(coeffs.get("attack", 1.0))), 
			"defense": int(base_stat * int(ratios.get("defense", 5)) * multiplier * float(coeffs.get("defense", 1.0))), 
			"agility": int(base_stat * int(ratios.get("agility", 5)) * multiplier * float(coeffs.get("agility", 1.0))), 
			"hp": int(base_stat * hp_mul * multiplier * float(coeffs.get("hp", 1.0))), 
			"exp_reward": floor_data.exp_reward / floor_data.monster_count, 
			"gold_reward": floor_data.gold_reward / floor_data.monster_count, 
			"is_evolution_pet": floor_data.monster_name != "天关守卫"
		}
		var monster = Monster.create_from_template(monster_data)

		monster.monster_id = texture_id
		monsters.append(monster)

	return monsters


static func _calculate_element_damage(base_damage: int, attacker_element: String, defender_element: String, attacker_uses_evolution_pet_element_rate: bool = true) -> Dictionary:
	return GameData.calculate_damage_with_element(base_damage, attacker_element, defender_element, attacker_uses_evolution_pet_element_rate)

const BUTTON_COOLDOWN_SEC: = 3

static func _start_button_cooldown(button: Button, base_text: String, seconds: int = BUTTON_COOLDOWN_SEC) -> void :
	if button == null or not is_instance_valid(button):
		return
	button.disabled = true
	for remaining in range(seconds, 0, -1):
		if not is_instance_valid(button):
			return
		button.text = "%s(%ds)" % [base_text, remaining]
		await button.get_tree().create_timer(1.0).timeout
	if not is_instance_valid(button):
		return
	button.text = base_text
	button.disabled = false

static func _get_instanced_block_message(game_manager) -> String:
	if game_manager == null:
		return ""
	if game_manager.has_method("get_instanced_challenge_block_message"):
		return str(game_manager.get_instanced_challenge_block_message(""))
	if game_manager.has_method("is_in_instanced_challenge") and game_manager.is_in_instanced_challenge():
		return "其他挑战正在进行中，请先完成或停止当前挑战后再试"
	return ""

static func _tower_commit_entry_fee(game_manager, panel_ref: Control, is_cleared: bool) -> bool:
	if is_cleared:
		return true
	if game_manager.has_method("is_tower_replay_on") and game_manager.is_tower_replay_on():
		if not game_manager.network or not game_manager.network.is_logged_in():
			if panel_ref and is_instance_valid(panel_ref):
				_show_message_fullscreen(panel_ref, "当前网络不可用，挑战已阻止。\n为防止断网刷层，挑战扣费需联网并完成云端确认。")
			return false
		if game_manager.player.gold < CHALLENGE_COST:
			if panel_ref and is_instance_valid(panel_ref):
				_show_message_fullscreen(panel_ref, "金币不足！\n需要100万金币才能挑战")
			return false
		return true
	if game_manager.player.gold < CHALLENGE_COST:
		if panel_ref and is_instance_valid(panel_ref):
			_show_message_fullscreen(panel_ref, "金币不足！\n需要100万金币才能挑战")
		return false
	if not game_manager.network or not game_manager.network.is_logged_in():
		if panel_ref and is_instance_valid(panel_ref):
			_show_message_fullscreen(panel_ref, "当前网络不可用，挑战已阻止。\n为防止断网SL，挑战扣费需联网并完成云端确认。")
		return false
	var snapshot = game_manager.create_secure_op_snapshot()
	game_manager.player.gold -= CHALLENGE_COST
	var commit_ok = await game_manager.commit_secure_op()
	if not commit_ok:
		game_manager.restore_secure_op_snapshot(snapshot)
		var message_target: Control = panel_ref if panel_ref and is_instance_valid(panel_ref) else _find_main_ui(game_manager)
		if message_target and is_instance_valid(message_target):
			_show_message_fullscreen(message_target, "云端确认失败，本次挑战扣费已回滚。")
		return false
	return true

static func _show_tower_notice(game_manager, panel: Control, message: String) -> void :
	var target: Control = panel if is_instance_valid(panel) else _find_main_ui(game_manager)
	if target and is_instance_valid(target):
		_show_message_fullscreen(target, message)
	else:
		push_warning("[Tower] %s" % message)

static func _launch_tower_battle_after_fee(floor: int, game_manager, monsters: Array, is_cleared: bool, message_panel: Control = null) -> bool:
	var success = game_manager.start_tower_battle(floor, monsters)
	# 线上「点挑战没战斗画面」的定位日志：把开战时刻的四个状态一起打出来，
	# 下次玩家复现时 logcat 里一眼能看出是被哪一道闸拦下的。
	print("[TowerUI] 开战 floor=%d -> %s (in_battle=%s tower=%s settling=%s replay=%s)" % [
		floor, str(success), str(game_manager.in_battle), str(game_manager.is_tower_battle),
		str(game_manager.is_tower_settling),
		str(game_manager.has_method("is_tower_replay_on") and game_manager.is_tower_replay_on())])
	if not success:
		if not is_cleared and not (game_manager.has_method("is_tower_replay_on") and game_manager.is_tower_replay_on()):
			game_manager.player.gold += CHALLENGE_COST
		# 提示必须挂到 MainUI：调用方传进来的 message_panel 可能马上就要被
		# queue_free（挑战成功/失败都会销毁天关页），挂在它上面等于没提示。
		var target: Control = _find_main_ui(game_manager)
		if target and is_instance_valid(target):
			# 野外挂机不再需要玩家手动停：start_tower_battle 里会自动暂停野外战斗
			# （原版口径）。走到这里的只剩「套装/五行/图鉴/兄弟天关」在打。
			_show_message_fullscreen(target, "无法开始战斗：当前有其他玩法战斗正在进行。\n请先结束那场战斗后再回来挑战（本次入场金币已退还）。")
		else:
			push_warning("[TowerUI] 开战失败且找不到 MainUI，无法提示玩家")
		return false
	return true

static func _challenge_floor_fullscreen(floor: int, game_manager, panel: Control, trigger_btn: Button = null):
	print("[TowerUI] 点击挑战 floor=%d" % floor)
	if trigger_btn and is_instance_valid(trigger_btn):
		_start_button_cooldown(trigger_btn, str(trigger_btn.get_meta("base_text", trigger_btn.text)))
	var is_cleared = floor <= game_manager.player.tower_highest
	var panel_ref: Control = panel

	if floor > _open_max_floor():
		if panel_ref and is_instance_valid(panel_ref):
			_show_message_fullscreen(panel_ref, _open_closed_message())
		return


	if not is_cleared:
		var required_rei: = _required_reincarnation_for_floor(floor)
		if required_rei > 0:
			var player_rei: = int(game_manager.player.reincarnation) if game_manager.player else 0
			if player_rei < required_rei:
				if panel_ref and is_instance_valid(panel_ref):
					_show_message_fullscreen(panel_ref, _reincarnation_block_message(floor, player_rei, required_rei))
				return

	var block_msg: = _get_instanced_block_message(game_manager)
	if not block_msg.is_empty():
		if panel_ref and is_instance_valid(panel_ref):
			_show_message_fullscreen(panel_ref, block_msg)
		return

	if game_manager.has_method("prepare_for_instanced_challenge_async"):
		await game_manager.prepare_for_instanced_challenge_async()
	elif game_manager.has_method("prepare_for_instanced_challenge"):
		game_manager.prepare_for_instanced_challenge()

	if not await _tower_commit_entry_fee(game_manager, panel_ref, is_cleared):
		return

	var replay_on: bool = game_manager.has_method("is_tower_replay_on") and bool(game_manager.is_tower_replay_on())
	var monsters: Array = []
	if not replay_on:
		monsters = _create_tower_monsters(floor)
		if monsters.is_empty():
			_show_message_fullscreen(panel, "创建怪物失败！")
			if not is_cleared:
				game_manager.player.gold += CHALLENGE_COST
			return

	# 先开战，开战成功之后才销毁天关页。
	# 原来是无条件 panel.queue_free()，一旦 start_tower_battle 返回 false，
	# 页面已经没了、失败提示又挂在刚被销毁的 panel 上 → 玩家看到的就是
	# 「点了挑战 → 界面空掉 → 没有战斗、也没有任何提示」。
	var started: bool = _launch_tower_battle_after_fee(floor, game_manager, monsters, is_cleared, panel_ref)
	if started:
		var page_root: Control = _page_root_of(panel_ref)
		if page_root and is_instance_valid(page_root):
			page_root.queue_free()


## 天关页可能被 TowerHubUI 包进「无限天关 / 兄弟天关」的外层 panel 里，
## 销毁时必须销毁最外层，否则会剩下两个空 tab（线上截图表现）。
static func _page_root_of(panel: Control) -> Control:
	if panel and is_instance_valid(panel):
		var root_ref: Variant = panel.get_meta("page_root", null)
		if root_ref is Control and is_instance_valid(root_ref):
			return root_ref
	return panel


static func _find_main_ui(game_manager) -> Control:
	var root = game_manager.get_tree().root


	var main_ui = root.get_node_or_null("MainUI")
	if main_ui:
		return main_ui


	var main = root.get_node_or_null("Main")
	if main:

		main_ui = main.get_node_or_null("MainUI")
		if main_ui:
			return main_ui

		var canvas_layer = main.get_node_or_null("MainCanvasLayer")
		if canvas_layer:
			main_ui = canvas_layer.get_node_or_null("MainUI")
			if main_ui:
				return main_ui


	for child in root.get_children():
		if child.name == "MainUI":
			return child
		if child.has_node("MainUI"):
			return child.get_node("MainUI")

		if child.name == "MainCanvasLayer":
			main_ui = child.get_node_or_null("MainUI")
			if main_ui:
				return main_ui

	return null


static func _show_tower_waiting_dialog(floor: int, panel: Control, game_manager, monsters: Array, is_cleared: bool):

	var waiting_panel = Panel.new()
	waiting_panel.name = "TowerWaitingPanel"
	waiting_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	waiting_panel.z_index = 1000

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0, 0, 0, 0.8)
	waiting_panel.add_theme_stylebox_override("panel", bg_style)

	panel.add_child(waiting_panel)


	var content_container = Control.new()
	content_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	waiting_panel.add_child(content_container)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	content_container.add_child(vbox)


	var anim_label = Label.new()
	anim_label.name = "TowerWaitingAnimLabel"
	anim_label.text = "⚔️"
	anim_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	anim_label.add_theme_font_size_override("font_size", 48)
	vbox.add_child(anim_label)


	var msg_label = Label.new()
	msg_label.text = "当前野外战斗进行中...\n等待战斗结束后自动进入天关第%d层" % floor
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.add_theme_font_size_override("font_size", 16)
	msg_label.add_theme_color_override("font_color", Color(1, 1, 1))
	vbox.add_child(msg_label)


	var countdown_label = Label.new()
	countdown_label.name = "TowerCountdownLabel"
	countdown_label.text = "等待中..."
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.add_theme_font_size_override("font_size", 14)
	countdown_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(countdown_label)


	var cancel_btn = Button.new()
	cancel_btn.text = "取消挑战"
	cancel_btn.custom_minimum_size = Vector2(120, 40)
	cancel_btn.pressed.connect( func():
		_cleanup_tower_waiting_dialog(panel)
	)
	vbox.add_child(cancel_btn)


	await panel.get_tree().process_frame
	await panel.get_tree().process_frame
	var viewport_size = panel.get_viewport_rect().size
	vbox.position = Vector2((viewport_size.x - vbox.size.x) / 2, (viewport_size.y - vbox.size.y) / 2)


	var tween = panel.create_tween()
	if tween:
		tween.set_loops()
		tween.tween_property(anim_label, "rotation", 2 * PI, 1.0)


	_start_tower_countdown_animation(panel, countdown_label)


	var on_battle_ended: Callable
	var requeue_wait: Callable = func() -> void :
		if game_manager and game_manager.battle_system and not game_manager.battle_system.battle_ended.is_connected(on_battle_ended):
			game_manager.battle_system.battle_ended.connect(on_battle_ended, CONNECT_ONE_SHOT)
	on_battle_ended = func(victory: bool):
		if game_manager == null:
			return
		var tree = game_manager.get_tree()
		if tree == null:
			return
		await tree.create_timer(0.5).timeout
		if game_manager == null:
			return
		if is_instance_valid(panel) and panel.get_node_or_null("TowerWaitingPanel") == null:
			return

		if game_manager.in_battle or game_manager.is_tower_battle or game_manager.is_tower_settling:
			requeue_wait.call()
			return
		if not _get_instanced_block_message(game_manager).is_empty():
			_cleanup_tower_waiting_dialog(panel)
			return


		_cleanup_tower_waiting_dialog(panel)

		if not await _tower_commit_entry_fee(game_manager, panel if is_instance_valid(panel) else null, is_cleared):
			return
		_launch_tower_battle_after_fee(floor, game_manager, monsters, is_cleared, panel)


	requeue_wait.call()


static func _start_tower_countdown_animation(panel: Control, countdown_label: Label):
	if countdown_label == null or not is_instance_valid(countdown_label):
		return

	var wait_time = 0
	while true:
		if not is_instance_valid(panel):
			break
		var tree = panel.get_tree()
		if tree == null:
			break
		await tree.create_timer(1.0).timeout
		if not is_instance_valid(panel):
			break

		if panel.get_node_or_null("TowerWaitingPanel") == null:
			break

		wait_time += 1
		if countdown_label and is_instance_valid(countdown_label):
			countdown_label.text = "已等待 %d 秒..." % wait_time


static func _cleanup_tower_waiting_dialog(panel: Control):
	if panel and is_instance_valid(panel):
		var waiting_panel = panel.get_node_or_null("TowerWaitingPanel")
		if waiting_panel:
			waiting_panel.queue_free()


static func _show_preparation_animation(floor: int, panel: Control, game_manager, monsters: Array):
	var floor_data = get_floor_data(floor)


	var prep_panel = Panel.new()
	prep_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	prep_panel.add_theme_stylebox_override("panel", UIStyle.create_panel_style())
	panel.add_child(prep_panel)

	var vbox = UIStyle.create_base_vbox()
	prep_panel.add_child(vbox)


	var title = UIStyle.create_title_label("⚔️ 进入天关第%d层" % floor)
	vbox.add_child(title)


	var log_panel = Panel.new()
	log_panel.custom_minimum_size = Vector2(0, 200)
	log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_panel.add_theme_stylebox_override("panel", UIStyle.create_item_style())
	vbox.add_child(log_panel)

	var log_label = Label.new()
	log_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	log_label.offset_left = 20
	log_label.offset_top = 20
	log_label.offset_right = -20
	log_label.offset_bottom = -20
	log_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	log_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	log_label.add_theme_font_size_override("font_size", 16)
	log_panel.add_child(log_label)

	var tree = panel.get_tree()


	var prep_steps = [
		"正在进入天关...", 
		"遭遇 %s Lv.%d..." % [floor_data.monster_name, floor_data.level], 
		"敌人数量: %d..." % floor_data.monster_count, 
		"五行属性: %s..." % floor_data.monster_element, 
		"准备战斗阵型...", 
		"战斗开始！"
	]


	for step in prep_steps:
		log_label.text = step
		await tree.create_timer(0.5).timeout

	await tree.create_timer(0.3).timeout


	panel.queue_free()


	game_manager.start_tower_battle(floor, monsters)

static func _show_battle_window(floor: int, game_manager, parent_panel: Control):
	var battle_window = Panel.new()
	battle_window.set_anchors_preset(Control.PRESET_FULL_RECT)
	battle_window.add_theme_stylebox_override("panel", UIStyle.create_panel_style())
	parent_panel.add_child(battle_window)

	var vbox = UIStyle.create_base_vbox()
	battle_window.add_child(vbox)

	var title = UIStyle.create_title_label("⚔️ 天关第%d层" % floor)
	vbox.add_child(title)


	var audio_player = AudioStreamPlayer.new()
	battle_window.add_child(audio_player)
	var bgm = load("res://Music/zdyy.mp3")
	if bgm:
		audio_player.stream = bgm
		audio_player.volume_db = -10
		if game_manager and game_manager.bgm_enabled:
			audio_player.play()


	var units_hbox = HBoxContainer.new()
	units_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	units_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(units_hbox)

	var floor_data = get_floor_data(floor)


	var player_panel = _create_unit_panel("我方", game_manager, floor_data, true)
	units_hbox.add_child(player_panel)


	var vs_label = Label.new()
	vs_label.text = "VS"
	vs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vs_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vs_label.add_theme_font_size_override("font_size", 24)
	vs_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	vs_label.custom_minimum_size = Vector2(60, 0)
	units_hbox.add_child(vs_label)


	var monster_panel = _create_unit_panel("敌方", game_manager, floor_data, false)
	units_hbox.add_child(monster_panel)


	var log_panel = Panel.new()
	log_panel.custom_minimum_size = Vector2(0, 180)
	log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_panel.add_theme_stylebox_override("panel", UIStyle.create_item_style())
	vbox.add_child(log_panel)

	var log_vbox = VBoxContainer.new()
	log_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	log_vbox.offset_left = 15
	log_vbox.offset_top = 15
	log_vbox.offset_right = -15
	log_vbox.offset_bottom = -15
	log_panel.add_child(log_vbox)

	var battle_log = RichTextLabel.new()
	battle_log.bbcode_enabled = true
	battle_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	battle_log.add_theme_font_size_override("normal_font_size", 13)
	battle_log.scroll_following = true
	log_vbox.add_child(battle_log)


	var status_label = Label.new()
	status_label.text = "战斗中..."
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
	vbox.add_child(status_label)


	var btn_hbox = HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 15)
	btn_hbox.visible = false
	vbox.add_child(btn_hbox)


	var battle_result = await _simulate_battle_with_animation(game_manager, floor_data, battle_log, status_label, btn_hbox, battle_window)


	if is_instance_valid(audio_player) and audio_player.playing:
		audio_player.stop()


	print("[TOWER] Battle result: ", battle_result, " floor: ", floor, " tower_floor: ", game_manager.player.tower_floor, " tower_highest: ", game_manager.player.tower_highest)
	if battle_result.win:
		print("[TOWER] Battle won!")
		game_manager.player.gold += floor_data.gold_reward


		if floor >= game_manager.player.tower_floor:
			print("[TOWER] Updating tower_floor from ", game_manager.player.tower_floor, " to ", floor + 1)
			game_manager.player.tower_floor = floor + 1


		if floor > game_manager.player.tower_highest:
			print("[TOWER] Updating tower_highest from ", game_manager.player.tower_highest, " to ", floor)
			game_manager.player.tower_highest = floor


		if game_manager.network and game_manager.network.is_logged_in():
			print("[TOWER] Syncing floor ", floor, " to server...")
			game_manager.network.update_tower_highest(game_manager.player.tower_highest, game_manager.player.tower_floor)
		else:
			print("[TOWER] Not logged in, skipping server sync")


		if floor % 100 == 0:
			_add_milestone_reward(game_manager, floor)
		elif floor % 10 == 0:
			_add_boss_reward(game_manager, floor)


		if floor % 10 == 0:
			var announce_msg = "恭喜【%s】闯过天关第%d层！" % [game_manager.player.player_name, floor]
			game_manager.broadcast_event("tower", game_manager.player.player_name, {"floor": floor}, announce_msg)


		var continue_btn = Button.new()
		continue_btn.text = "继续挑战"
		continue_btn.custom_minimum_size = Vector2(120, 40)
		UIStyle.apply_button_style(continue_btn)
		continue_btn.pressed.connect( func():
			battle_window.queue_free()
			var current_tab = int(parent_panel.get_meta("current_tab", 0))
			_refresh_tower_floor_view(parent_panel, game_manager, current_tab)

			if game_manager.player.gold >= CHALLENGE_COST:
				_challenge_floor_fullscreen(floor + 1, game_manager, parent_panel)
			else:
				_show_message_fullscreen(parent_panel, "金币不足，无法继续挑战！")
		)
		btn_hbox.add_child(continue_btn)
	else:

		var retry_btn = Button.new()
		retry_btn.text = "重新挑战"
		retry_btn.custom_minimum_size = Vector2(120, 40)
		UIStyle.apply_button_style(retry_btn)
		retry_btn.pressed.connect( func():
			battle_window.queue_free()
			_challenge_floor_fullscreen(floor, game_manager, parent_panel)
		)
		btn_hbox.add_child(retry_btn)


	var close_btn = Button.new()
	close_btn.text = "返回"
	close_btn.custom_minimum_size = Vector2(120, 40)
	UIStyle.apply_button_style(close_btn)
	close_btn.pressed.connect( func():
		battle_window.queue_free()
		var current_tab = int(parent_panel.get_meta("current_tab", 0))
		_refresh_tower_floor_view(parent_panel, game_manager, current_tab)
	)
	btn_hbox.add_child(close_btn)

static func _create_unit_panel(side: String, game_manager, floor_data: Dictionary, is_player: bool) -> Control:
	if is_player:

		var player_hbox = HBoxContainer.new()
		player_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		player_hbox.add_theme_constant_override("separation", 8)


		var player_panel = Panel.new()
		player_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		player_panel.custom_minimum_size = Vector2(100, 120)
		player_panel.add_theme_stylebox_override("panel", UIStyle.create_item_style())
		player_hbox.add_child(player_panel)

		var player_vbox = VBoxContainer.new()
		player_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		player_vbox.offset_left = 8
		player_vbox.offset_top = 8
		player_vbox.offset_right = -8
		player_vbox.offset_bottom = -8
		player_vbox.add_theme_constant_override("separation", 3)
		player_panel.add_child(player_vbox)

		var player_title = Label.new()
		player_title.text = "【玩家】"
		player_title.add_theme_font_size_override("font_size", 11)
		player_title.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
		player_vbox.add_child(player_title)

		var player_name = Label.new()
		player_name.text = game_manager.player.player_name
		player_name.add_theme_font_size_override("font_size", 11)
		player_vbox.add_child(player_name)

		var player_element = FabaoStatBonus.wild_player_element("普通")
		var player_level = Label.new()
		player_level.text = "Lv.%d %s" % [game_manager.player.level, player_element]
		player_level.add_theme_font_size_override("font_size", 10)
		player_vbox.add_child(player_level)

		var player_hp = Label.new()
		player_hp.text = "生命: %d" % game_manager.player.get_max_hp()
		player_hp.add_theme_font_size_override("font_size", 10)
		player_vbox.add_child(player_hp)

		var player_atk = Label.new()
		player_atk.text = "攻击: %d" % game_manager.player.get_attack()
		player_atk.add_theme_font_size_override("font_size", 10)
		player_vbox.add_child(player_atk)

		var player_def = Label.new()
		player_def.text = "防御: %d" % game_manager.player.get_defense()
		player_def.add_theme_font_size_override("font_size", 10)
		player_vbox.add_child(player_def)


		var active_pet = game_manager.pet_manager.get_active_pet()
		var pet_panel = Panel.new()
		pet_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pet_panel.custom_minimum_size = Vector2(100, 120)
		pet_panel.add_theme_stylebox_override("panel", UIStyle.create_item_style())
		player_hbox.add_child(pet_panel)

		var pet_vbox = VBoxContainer.new()
		pet_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		pet_vbox.offset_left = 8
		pet_vbox.offset_top = 8
		pet_vbox.offset_right = -8
		pet_vbox.offset_bottom = -8
		pet_vbox.add_theme_constant_override("separation", 3)
		pet_panel.add_child(pet_vbox)

		if active_pet:
			var pet_title = Label.new()
			pet_title.text = "【宠物】"
			pet_title.add_theme_font_size_override("font_size", 11)
			pet_title.add_theme_color_override("font_color", Color(1, 0.84, 0))
			pet_vbox.add_child(pet_title)

			var pet_name = Label.new()
			pet_name.text = active_pet.pet_name
			pet_name.add_theme_font_size_override("font_size", 11)
			pet_vbox.add_child(pet_name)

			var pet_element = active_pet.element if active_pet.element else "无"
			var pet_level = Label.new()
			pet_level.text = "Lv.%d %s" % [active_pet.level, pet_element]
			pet_level.add_theme_font_size_override("font_size", 10)
			pet_vbox.add_child(pet_level)

			var pet_hp = Label.new()
			pet_hp.text = "生命: %d" % active_pet.get_final_max_hp_with_equipment()
			pet_hp.add_theme_font_size_override("font_size", 10)
			pet_vbox.add_child(pet_hp)

			var pet_atk = Label.new()
			pet_atk.text = "攻击: %d" % int(active_pet.get_final_attack_with_equipment())
			pet_atk.add_theme_font_size_override("font_size", 10)
			pet_vbox.add_child(pet_atk)

			var pet_def = Label.new()
			pet_def.text = "防御: %d" % int(active_pet.get_final_defense_with_equipment())
			pet_def.add_theme_font_size_override("font_size", 10)
			pet_vbox.add_child(pet_def)
		else:
			var no_pet_title = Label.new()
			no_pet_title.text = "【宠物】"
			no_pet_title.add_theme_font_size_override("font_size", 11)
			no_pet_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			pet_vbox.add_child(no_pet_title)

			var no_pet = Label.new()
			no_pet.text = "(未出战)"
			no_pet.add_theme_font_size_override("font_size", 11)
			no_pet.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			pet_vbox.add_child(no_pet)

		return player_hbox
	else:

		var panel = Panel.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.custom_minimum_size = Vector2(150, 120)
		panel.add_theme_stylebox_override("panel", UIStyle.create_item_style())

		var vbox = VBoxContainer.new()
		vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		vbox.offset_left = 10
		vbox.offset_top = 10
		vbox.offset_right = -10
		vbox.offset_bottom = -10
		vbox.add_theme_constant_override("separation", 3)
		panel.add_child(vbox)

		var monster_title = Label.new()
		monster_title.text = "【敌方】"
		monster_title.add_theme_font_size_override("font_size", 11)
		monster_title.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
		vbox.add_child(monster_title)

		var monster_name = Label.new()
		monster_name.text = floor_data.monster_name
		monster_name.add_theme_font_size_override("font_size", 20)
		vbox.add_child(monster_name)

		var monster_level = Label.new()
		monster_level.text = "Lv.%d x%d [%s]" % [floor_data.level, floor_data.monster_count, floor_data.monster_element]
		monster_level.add_theme_font_size_override("font_size", 20)
		vbox.add_child(monster_level)

		var monster_hp = Label.new()
		var ratios = _get_tower_type_ratios(str(floor_data.get("monster_type", "balanced")))
		var stat_multiplier = float(floor_data.get("stat_multiplier", 1.0))
		var coeffs_raw = floor_data.get("stat_coeffs", {})
		var coeffs: Dictionary = coeffs_raw if coeffs_raw is Dictionary else {}
		var hp_per: = int(floor_data.get("hp_per_level", 50))
		var total_hp = int(floor_data.level * hp_per * floor_data.monster_count * stat_multiplier * float(coeffs.get("hp", 1.0)))
		monster_hp.text = "生命: %d" % total_hp
		monster_hp.add_theme_font_size_override("font_size", 20)
		vbox.add_child(monster_hp)

		var monster_atk = Label.new()
		var total_atk = int(floor_data.level * int(ratios.get("attack", 5)) * stat_multiplier * float(coeffs.get("attack", 1.0)))
		monster_atk.text = "攻击: %d" % total_atk
		monster_atk.add_theme_font_size_override("font_size", 20)
		vbox.add_child(monster_atk)

		var monster_def = Label.new()
		var total_def = int(floor_data.level * int(ratios.get("defense", 5)) * stat_multiplier * float(coeffs.get("defense", 1.0)))
		monster_def.text = "防御: %d" % total_def
		monster_def.add_theme_font_size_override("font_size", 20)
		vbox.add_child(monster_def)

		return panel

static func _simulate_battle_with_animation(game_manager, floor_data: Dictionary, battle_log: RichTextLabel, 
		status_label: Label, btn_hbox: HBoxContainer, battle_window: Control) -> Dictionary:

	var tree = battle_window.get_tree()


	var add_log = func(text: String):
		if not is_instance_valid(battle_log):
			return
		battle_log.text += text + "\n"
		battle_log.scroll_to_line(battle_log.get_line_count() - 1)

	add_log.call("[color=yellow]=== 战斗开始 ===[/color]")
	await tree.create_timer(0.3).timeout


	var player = game_manager.player
	var active_pet = game_manager.pet_manager.get_active_pet()

	var player_attack = player.get_attack()
	var player_defense = player.get_defense()
	var player_agility = player.get_agility()
	var player_hp = player.get_max_hp()
	var player_max_hp = player_hp

	var pet_attack = 0
	var pet_defense = 0
	var pet_agility = 0
	var pet_hp = 0
	var pet_max_hp = 0
	var pet_name = ""

	if active_pet:
		pet_attack = active_pet.get_final_attack_with_equipment()
		pet_defense = active_pet.get_final_defense_with_equipment()
		pet_agility = active_pet.get_final_agility_with_equipment()
		pet_hp = active_pet.get_final_max_hp_with_equipment()
		pet_max_hp = pet_hp
		pet_name = active_pet.pet_name
		add_log.call("[color=green]宠物【%s】加入战斗！[/color]" % pet_name)
		await tree.create_timer(0.3).timeout

	var monster_level = floor_data.level
	var ratios = _get_tower_type_ratios(str(floor_data.get("monster_type", "balanced")))
	var monster_type = str(floor_data.get("monster_type", "balanced"))
	var monster_type_name = _get_tower_type_display_name(monster_type)
	var stat_multiplier = float(floor_data.get("stat_multiplier", 1.0))
	var coeffs_raw = floor_data.get("stat_coeffs", {})
	var coeffs: Dictionary = coeffs_raw if coeffs_raw is Dictionary else {}
	var hp_per: = int(floor_data.get("hp_per_level", 50))
	var monster_attack = int(monster_level * int(ratios.get("attack", 5)) * stat_multiplier * float(coeffs.get("attack", 1.0)))
	var monster_defense = int(monster_level * int(ratios.get("defense", 5)) * stat_multiplier * float(coeffs.get("defense", 1.0)))
	var monster_agility = int(monster_level * int(ratios.get("agility", 5)) * stat_multiplier * float(coeffs.get("agility", 1.0)))
	var monster_hp = int(monster_level * hp_per * floor_data.monster_count * stat_multiplier * float(coeffs.get("hp", 1.0)))
	var monster_max_hp = monster_hp
	var ratio_text = "%d:%d:%d" % [
		int(ratios.get("attack", 5)), 
		int(ratios.get("defense", 5)), 
		int(ratios.get("agility", 5))
	]

	add_log.call("[color=red]遭遇 %s Lv.%d x%d [%s]！[/color]" % [floor_data.monster_name, monster_level, floor_data.monster_count, floor_data.monster_element])
	add_log.call("[color=skyblue]天关公式：%s（攻防敏 %s）| 属性倍率 x%.1f | 分段系数 攻%.2f防%.2f敏%.2f血%.2f[/color]" % [
		monster_type_name, ratio_text, stat_multiplier, 
		float(coeffs.get("attack", 1.0)), float(coeffs.get("defense", 1.0)), 
		float(coeffs.get("agility", 1.0)), float(coeffs.get("hp", 1.0))
	])
	add_log.call("[color=gray]怪物总生命: %d | 攻击: %d | 防御: %d | 敏捷: %d[/color]" % [monster_max_hp, monster_attack, monster_defense, monster_agility])
	await tree.create_timer(0.5).timeout


	var tower_mon_uses_evo_rate: bool = str(floor_data.get("monster_name", "")) != "天关守卫"

	var round = 0
	var max_rounds = _tower_battle_max_rounds()
	var win = false


	var player_element = FabaoStatBonus.wild_player_element("普通")
	var pet_element = "普通"
	if active_pet and active_pet.element and active_pet.element != "" and active_pet.element != "普通":
		pet_element = active_pet.element


	var can_combo = false
	if active_pet:
		can_combo = (player_agility > monster_agility) and (pet_agility > monster_agility)
	else:
		can_combo = player_agility > monster_agility

	if can_combo:
		add_log.call("[color=yellow]★ 连击触发！你的敏捷高于怪物，可以连续攻击！★[/color]")
		await tree.create_timer(0.3).timeout

	while round < max_rounds and (player_hp > 0 or pet_hp > 0) and monster_hp > 0:
		round += 1
		add_log.call("\n[color=cyan]--- 第%d回合 ---[/color]" % round)
		await tree.create_timer(0.5).timeout


		var action_list = []


		if player_hp > 0:
			action_list.append({"type": "player", "agility": player_agility, "name": player.player_name})


		if active_pet and pet_hp > 0:
			action_list.append({"type": "pet", "agility": pet_agility, "name": pet_name})


		action_list.append({"type": "monster", "agility": monster_agility, "name": floor_data.monster_name})


		action_list.sort_custom( func(a, b): return a.agility > b.agility)


		for action in action_list:

			if monster_hp <= 0 or (player_hp <= 0 and pet_hp <= 0):
				break

			match action.get("type", ""):
				"player":

					if player_hp <= 0:
						continue

					var player_base_dmg = max(1, player_attack - monster_defense / 2)
					player_base_dmg = int(player_base_dmg * (0.8 + randf() * 0.4))
					var player_dmg_result = _calculate_element_damage(player_base_dmg, player_element, floor_data.monster_element, false)
					var player_damage = player_dmg_result.damage
					monster_hp -= player_damage

					var dmg_text = "[你] 对怪物造成 [color=red]%d[/color] 点伤害" % player_damage
					if player_dmg_result.message != "":
						dmg_text += " [color=yellow]%s[/color]" % player_dmg_result.message
					dmg_text += " (怪物剩余: %d)" % max(0, monster_hp)
					add_log.call(dmg_text)
					await tree.create_timer(0.5).timeout

					if monster_hp <= 0:
						add_log.call("[color=green]★ 怪物被击败了！★[/color]")
						win = true
						break


					if can_combo:
						await tree.create_timer(0.3).timeout
						add_log.call("[color=yellow]【连击】[/color]")

						player_base_dmg = max(1, player_attack - monster_defense / 2)
						player_base_dmg = int(player_base_dmg * (0.8 + randf() * 0.4))
						player_dmg_result = _calculate_element_damage(player_base_dmg, player_element, floor_data.monster_element, false)
						player_damage = player_dmg_result.damage
						monster_hp -= player_damage

						dmg_text = "[你] 对怪物造成 [color=red]%d[/color] 点伤害" % player_damage
						if player_dmg_result.message != "":
							dmg_text += " [color=yellow]%s[/color]" % player_dmg_result.message
						dmg_text += " (怪物剩余: %d)" % max(0, monster_hp)
						add_log.call(dmg_text)
						await tree.create_timer(0.5).timeout

						if monster_hp <= 0:
							add_log.call("[color=green]★ 怪物被击败了！★[/color]")
							win = true
							break

				"pet":

					if pet_hp <= 0:
						continue

					var pet_base_dmg = max(1, pet_attack - monster_defense / 2)
					pet_base_dmg = int(pet_base_dmg * (0.8 + randf() * 0.4))
					var pet_dmg_result = _calculate_element_damage(pet_base_dmg, pet_element, floor_data.monster_element, active_pet.is_evolution_pet if active_pet else true)
					var pet_dmg = pet_dmg_result.damage
					monster_hp -= pet_dmg

					var pet_dmg_text = "[宠物] %s 造成 [color=red]%d[/color] 点伤害" % [pet_name, pet_dmg]
					if pet_dmg_result.message != "":
						pet_dmg_text += " [color=yellow]%s[/color]" % pet_dmg_result.message
					pet_dmg_text += " (怪物剩余: %d)" % max(0, monster_hp)
					add_log.call(pet_dmg_text)
					await tree.create_timer(0.5).timeout

					if monster_hp <= 0:
						add_log.call("[color=green]★ 怪物被击败了！★[/color]")
						win = true
						break


					if can_combo:
						await tree.create_timer(0.3).timeout
						add_log.call("[color=yellow]【连击】[/color]")

						pet_base_dmg = max(1, pet_attack - monster_defense / 2)
						pet_base_dmg = int(pet_base_dmg * (0.8 + randf() * 0.4))
						pet_dmg_result = _calculate_element_damage(pet_base_dmg, pet_element, floor_data.monster_element, active_pet.is_evolution_pet if active_pet else true)
						pet_dmg = pet_dmg_result.damage
						monster_hp -= pet_dmg

						pet_dmg_text = "[宠物] %s 造成 [color=red]%d[/color] 点伤害" % [pet_name, pet_dmg]
						if pet_dmg_result.message != "":
							pet_dmg_text += " [color=yellow]%s[/color]" % pet_dmg_result.message
						pet_dmg_text += " (怪物剩余: %d)" % max(0, monster_hp)
						add_log.call(pet_dmg_text)
						await tree.create_timer(0.5).timeout

						if monster_hp <= 0:
							add_log.call("[color=green]★ 怪物被击败了！★[/color]")
							win = true
							break

				"monster":

					if player_hp > 0:
						var monster_base_dmg_to_player = max(1, monster_attack - player_defense / 2)
						monster_base_dmg_to_player = int(monster_base_dmg_to_player * (0.8 + randf() * 0.4))
						var monster_dmg_to_player_result = _calculate_element_damage(monster_base_dmg_to_player, floor_data.monster_element, player_element, tower_mon_uses_evo_rate)
						var monster_dmg_to_player = monster_dmg_to_player_result.damage
						player_hp -= monster_dmg_to_player

						var monster_dmg_text = "[怪物] 对你造成 [color=red]%d[/color] 点伤害" % monster_dmg_to_player
						if monster_dmg_to_player_result.message != "":
							monster_dmg_text += " [color=yellow]%s[/color]" % monster_dmg_to_player_result.message
						monster_dmg_text += " (你剩余: %d/%d)" % [max(0, player_hp), player_max_hp]
						add_log.call(monster_dmg_text)
						await tree.create_timer(0.5).timeout

						if player_hp <= 0:
							add_log.call("[color=red]★ 你被击败了... ★[/color]")
							win = false
							break


					if active_pet and pet_hp > 0:
						var monster_base_dmg_to_pet = max(1, monster_attack - pet_defense / 2)
						monster_base_dmg_to_pet = int(monster_base_dmg_to_pet * (0.8 + randf() * 0.4))
						var monster_dmg_to_pet_result = _calculate_element_damage(monster_base_dmg_to_pet, floor_data.monster_element, pet_element, tower_mon_uses_evo_rate)
						var monster_dmg_to_pet = monster_dmg_to_pet_result.damage
						pet_hp -= monster_dmg_to_pet

						var monster_pet_dmg_text = "[怪物] 对%s造成 [color=red]%d[/color] 点伤害" % [pet_name, monster_dmg_to_pet]
						if monster_dmg_to_pet_result.message != "":
							monster_pet_dmg_text += " [color=yellow]%s[/color]" % monster_dmg_to_pet_result.message
						monster_pet_dmg_text += " (宠物剩余: %d/%d)" % [max(0, pet_hp), pet_max_hp]
						add_log.call(monster_pet_dmg_text)
						await tree.create_timer(0.5).timeout

						if pet_hp <= 0:
							add_log.call("[color=orange]%s 倒下了...[/color]" % pet_name)
							await tree.create_timer(0.3).timeout


	await tree.create_timer(0.3).timeout
	add_log.call("\n[color=yellow]=== 战斗结束 ===[/color]")


	if not is_instance_valid(status_label) or not is_instance_valid(btn_hbox):
		return {"win": win}

	if win:
		status_label.text = "挑战成功！"
		status_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.5))
	else:
		status_label.text = "挑战失败！"
		status_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))


	btn_hbox.visible = true

	return {"win": win}


static func _sweep_all_cleared_floors(panel: Control, game_manager, trigger_btn: Button = null):
	if trigger_btn and is_instance_valid(trigger_btn):
		_start_button_cooldown(trigger_btn, str(trigger_btn.get_meta("base_text", trigger_btn.text)))
	var max_sweeps = VipBenefits.tower_sweep_limit(VipBenefits.tier_from_player(game_manager.player))
	var remaining = max_sweeps - game_manager.player.tower_sweep_count
	if remaining <= 0:
		_show_message_fullscreen(panel, "今日扫荡次数已用完！\n请明日再来")
		return

	var current_floor = game_manager.player.tower_floor
	var highest_floor = game_manager.player.tower_highest


	var sweepable_floors = []
	var sweep_end = highest_floor if highest_floor > 0 else current_floor - 1
	for floor in range(1, sweep_end + 1):
		sweepable_floors.append(floor)

	if sweepable_floors.is_empty():
		_show_message_fullscreen(panel, "没有可扫荡的关卡！\n请先挑战并通过关卡")
		return

	var total_gold = 0
	var milestone_rewards = []
	var boss_rewards = 0

	for floor in sweepable_floors:
		var floor_data = get_floor_data(floor)
		total_gold += floor_data.gold_reward

		if floor % 100 == 0:
			milestone_rewards.append(floor)
		elif floor % 10 == 0:
			boss_rewards += 1

	var confirm_msg = "一键扫荡 %d 个已通关关卡\n\n获得金币: %s" % [
		sweepable_floors.size(), 
		_format_number(total_gold)
	]

	if milestone_rewards.size() > 0:
		confirm_msg += "\n里程碑礼包: %d个" % milestone_rewards.size()
	if boss_rewards > 0:
		confirm_msg += "\n天关奖励: %d份" % boss_rewards

	_show_confirm_dialog(panel, confirm_msg, func():
		await _start_sweep_with_server_check(panel, game_manager, sweepable_floors, total_gold, milestone_rewards, boss_rewards)
	)

static func _is_server_truthy(v: Variant) -> bool:
	return (typeof(v) == TYPE_BOOL and v) or (typeof(v) == TYPE_INT and int(v) != 0)

static func _parse_tower_sweep_gift_items_from_server(d: Dictionary) -> Array:
	var gv: Variant = null
	if d.has("giftItems"):
		gv = d.get("giftItems")
	elif d.has("gift_items"):
		gv = d.get("gift_items")
	if gv == null:
		return []
	if gv is Array:
		return gv
	return []

static func _start_sweep_with_server_check(panel: Control, game_manager, floors: Array, total_gold: int, milestone_rewards: Array, boss_rewards: int) -> void :
	if game_manager.network and game_manager.network.is_logged_in():
		var op_id: = "tower_sweep_%d_%d" % [Time.get_unix_time_from_system(), randi()]
		var er: Dictionary = await game_manager.wait_economy("economy_tower_sweep", func():
			game_manager.network.economy_tower_sweep_reward(op_id)
		)
		if er.get("ok", false):
			var dvar: Variant = er.get("data", {})
			var sweep_gold: = total_gold
			var server_gift_items: Array = []
			var server_duplicate: = false
			var tower_highest_used: = -1
			if dvar is Dictionary:
				var d: Dictionary = dvar
				if d.has("newGold"):
					game_manager.player.gold = int(d.get("newGold", game_manager.player.gold))
				if d.has("sweepCount"):
					game_manager.player.tower_sweep_count = int(d.get("sweepCount", game_manager.player.tower_sweep_count))
				sweep_gold = int(d.get("goldGranted", total_gold))
				server_gift_items = _parse_tower_sweep_gift_items_from_server(d)
				server_duplicate = _is_server_truthy(d.get("duplicate", false))
				if d.has("towerHighestUsed"):
					tower_highest_used = int(d.get("towerHighestUsed", -1))
				elif d.has("tower_highest_used"):
					tower_highest_used = int(d.get("tower_highest_used", -1))
			game_manager.gold_changed.emit(game_manager.player.gold)
			_perform_sweep_all(
				panel, game_manager, floors, sweep_gold, milestone_rewards, boss_rewards, 
				true, server_gift_items, server_duplicate, tower_highest_used
			)
		else:
			_show_message_fullscreen(panel, "[color=red]扫荡失败[/color]\n\n" + str(er.get("err", "服务器错误")))
	else:
		_show_message_fullscreen(panel, "[color=red]请先登录[/color]\n\n需要登录才能使用一键扫荡功能")

static func _append_tower_sweep_gift_result_msg(
	result_msg: String, 
	server_gift_items: Array, 
	server_duplicate: bool, 
	milestone_rewards: Array, 
	boss_rewards: int, 
	tower_highest_used: int, 
	floors: Array, 
	game_manager
) -> String:
	if server_gift_items.size() > 0:
		result_msg += "\n\n礼包已发至云端邮件（同一封合并）："
		for agg in _aggregate_gift_items_for_display(server_gift_items):
			if agg is Dictionary:
				result_msg += "\n· %s x%d" % [str((agg as Dictionary).get("name", "")), int((agg as Dictionary).get("count", 1))]
		return result_msg
	if server_duplicate:
		result_msg += "\n\n本次扫荡已结算，礼包请查看云端邮件"
		return result_msg
	if milestone_rewards.size() > 0 or boss_rewards > 0:
		if milestone_rewards.size() > 0:
			result_msg += "\n里程碑礼包: %d个（已发送到邮件）" % milestone_rewards.size()
		if boss_rewards > 0:
			result_msg += "\n天关奖励: %d份（已发送到邮件）" % boss_rewards
		return result_msg
	var effective_highest: = tower_highest_used
	if effective_highest < 0 and game_manager != null and game_manager.player != null:
		effective_highest = int(game_manager.player.tower_highest)
	if effective_highest <= 0 and floors.size() > 0:
		effective_highest = int(floors.max())
	if effective_highest >= 10:
		result_msg += "\n\nBOSS/百层礼包已发至云端邮件，请查收"
	else:
		result_msg += "\n\n（最高层不足第 10 层，无额外礼包）"
	return result_msg

static func _perform_sweep_all(
	panel: Control, 
	game_manager, 
	floors: Array, 
	total_gold: int, 
	milestone_rewards: Array, 
	boss_rewards: int, 
	server_sweep_done: bool = false, 
	server_gift_items: Array = [], 
	server_duplicate: bool = false, 
	tower_highest_used: int = -1
):
	if not server_sweep_done:
		game_manager.player.tower_sweep_count += 1

	var sweep_panel = Panel.new()
	sweep_panel.set_anchors_preset(Control.PRESET_CENTER)
	sweep_panel.custom_minimum_size = Vector2(350, 250)
	sweep_panel.add_theme_stylebox_override("panel", UIStyle.create_panel_style())
	panel.add_child(sweep_panel)

	sweep_panel.position = (panel.size - sweep_panel.custom_minimum_size) / 2

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	sweep_panel.add_child(vbox)

	var sweep_label = Label.new()
	sweep_label.text = "正在结算扫荡奖励…"
	sweep_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sweep_label.add_theme_font_size_override("font_size", 16)
	sweep_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(sweep_label)

	var progress_label = Label.new()
	progress_label.text = "（共 %d 层，已合并计算）" % floors.size()
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size", 14)
	progress_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(progress_label)

	var tree = panel.get_tree()

	await tree.create_timer(0.15).timeout

	if not server_sweep_done:
		game_manager.player.gold += total_gold
		game_manager.gold_changed.emit(game_manager.player.gold)


	if game_manager.quest_manager and floors.size() > 0:
		var max_floor = floors.max()
		game_manager.quest_manager.on_tower_completed(max_floor)

	if not server_sweep_done:
		for floor in milestone_rewards:
			_add_milestone_reward(game_manager, floor)

	await tree.create_timer(0.5).timeout
	sweep_panel.queue_free()

	var result_msg = "一键扫荡完成！\n\n获得金币: %s" % _format_number(total_gold)

	if server_sweep_done:
		result_msg = _append_tower_sweep_gift_result_msg(
			result_msg, server_gift_items, server_duplicate, 
			milestone_rewards, boss_rewards, tower_highest_used, floors, game_manager
		)
	else:
		if milestone_rewards.size() > 0:
			result_msg += "\n里程碑礼包: %d个（已发送到邮件）" % milestone_rewards.size()
		if boss_rewards > 0:
			result_msg += "\n天关奖励: %d份（已发送到邮件）" % boss_rewards

	var max_sweeps_done: = VipBenefits.tower_sweep_limit(VipBenefits.tier_from_player(game_manager.player))
	var remaining_sweeps: int = max_sweeps_done - int(game_manager.player.tower_sweep_count)
	if remaining_sweeps <= 0:
		result_msg += "\n\n[color=yellow]今日扫荡次数已用完[/color]"

	_show_message_fullscreen(panel, result_msg)

	_refresh_sweep_button(panel, game_manager)

static func _refresh_sweep_button(panel: Control, game_manager):
	if panel and is_instance_valid(panel):
		var btn_hbox = panel.get_node_or_null("VBoxContainer/HBoxContainer")
		if btn_hbox:
			for child in btn_hbox.get_children():
				if child is Button and child.text.begins_with("一键扫荡"):
					var max_sweeps = VipBenefits.tower_sweep_limit(VipBenefits.tier_from_player(game_manager.player))
					var remaining = max_sweeps - game_manager.player.tower_sweep_count
					var base_text = str(child.get_meta("base_text", "一键扫荡"))
					child.text = "%s (%d/%d)" % [base_text, remaining, max_sweeps]
					break



static func _show_confirm_dialog(parent_control: Control, message: String, on_confirm: Callable):
	var popup_key = "tower_confirm_dialog:%s" % message
	if _focus_existing_window_popup(popup_key):
		return
	var popup = Window.new()
	_mark_popup_key(popup, popup_key)
	popup.title = ""
	var line_count = message.split("\n").size()
	var content_height = max(80, line_count * 28)
	var total_height = 200 + content_height
	popup.size = Vector2i(400, total_height)
	popup.transparent = true
	popup.borderless = true
	popup.unresizable = true
	popup.close_requested.connect( func(): popup.queue_free())

	var main_panel = Panel.new()
	main_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_panel.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	popup.add_child(main_panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 25
	vbox.offset_top = 25
	vbox.offset_right = -25
	vbox.offset_bottom = -25
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	main_panel.add_child(vbox)

	var msg_label = Label.new()
	msg_label.text = message
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.add_theme_font_size_override("font_size", 18)
	msg_label.add_theme_color_override("font_color", Color(0.894, 0.864, 0.803))
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(msg_label)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	var btn_hbox = HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 30)
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_hbox)

	var confirm_btn = Button.new()
	confirm_btn.text = "确认"
	UIStyle.style_popup_button(confirm_btn, true)
	confirm_btn.pressed.connect( func():
		popup.queue_free()
		if on_confirm.is_valid():
			await on_confirm.call()
	)
	btn_hbox.add_child(confirm_btn)

	var cancel_btn = Button.new()
	cancel_btn.text = "取消"
	UIStyle.style_popup_button(cancel_btn, false)
	cancel_btn.pressed.connect( func():
		popup.queue_free()
	)
	btn_hbox.add_child(cancel_btn)

	var scene_root = Engine.get_main_loop().current_scene
	if scene_root:
		scene_root.add_child(popup)
		popup.popup_centered()

static func _add_milestone_reward(game_manager, floor: int):
	var item_name = "%d关礼包" % floor
	print("[TowerUI] _add_milestone_reward 被调用, floor=", floor, ", MailManager.instance=", MailManager.instance)
	if MailManager.instance:
		MailManager.instance.send_item_drop_mail("天关里程碑奖励", [{"name": item_name, "count": 1}], 0)
	else:
		print("[TowerUI] MailManager.instance 为 null，无法发送里程碑奖励邮件")

static func _add_boss_reward(game_manager, floor: int):
	print("[TowerUI] _add_boss_reward 被调用, MailManager.instance=", MailManager.instance)
	if MailManager.instance:
		MailManager.instance.send_item_drop_mail("天关BOSS奖励", [{"name": "天关礼包", "count": 1}], 0)
	else:
		print("[TowerUI] MailManager.instance 为 null，无法发送BOSS奖励邮件")

static func _show_ranking_fullscreen(panel: Control, game_manager):
	var popup_key = "tower_ranking_popup"
	if _focus_existing_child_popup(panel, popup_key):
		return

	var popup = Panel.new()
	_mark_popup_key(popup, popup_key)
	popup.set_anchors_preset(Control.PRESET_CENTER)
	popup.custom_minimum_size = Vector2(500, 600)
	popup.add_theme_stylebox_override("panel", UIStyle.create_panel_style())
	panel.add_child(popup)


	popup.position = (panel.size - popup.custom_minimum_size) / 2

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	popup.add_child(vbox)


	var title = UIStyle.create_title_label("🏆 天关排行榜")
	vbox.add_child(title)


	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.scroll_deadzone = 20
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	vbox.add_child(scroll)

	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	list.add_theme_constant_override("separation", 5)
	scroll.add_child(list)


	_load_tower_ranking(list, game_manager, popup)


	var close_btn = UIStyle.create_close_button()
	close_btn.pressed.connect( func():
		popup.queue_free()
	)
	vbox.add_child(close_btn)

static func _load_tower_ranking(list: VBoxContainer, game_manager, popup: Control):

	var loading_label = Label.new()
	loading_label.text = "加载中..."
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	list.add_child(loading_label)

	var network = game_manager.network
	print("[TOWER_RANKING] Network: ", network, " is_logged_in: ", network.is_logged_in() if network else false)

	if network and network.is_logged_in():

		print("[TOWER_RANKING] Connecting to ranking_loaded signal")
		network.ranking_loaded.connect( func(rankings):
			print("[TOWER_RANKING] Ranking loaded: ", rankings)

			for child in list.get_children():
				child.queue_free()


			if rankings.size() == 0:
				var local_highest = game_manager.player.tower_highest
				if local_highest > 0:

					var rank_panel = Panel.new()
					rank_panel.custom_minimum_size = Vector2(0, 50)
					rank_panel.add_theme_stylebox_override("panel", UIStyle.create_rank_style(0))
					list.add_child(rank_panel)

					var hbox = HBoxContainer.new()
					hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
					hbox.offset_left = 10
					hbox.offset_top = 10
					hbox.offset_right = -10
					hbox.offset_bottom = -10
					rank_panel.add_child(hbox)

					var rank_label = Label.new()
					rank_label.text = "🥇"
					rank_label.custom_minimum_size = Vector2(40, 0)
					rank_label.add_theme_font_size_override("font_size", 18)
					rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					hbox.add_child(rank_label)

					var name_label = Label.new()
					name_label.text = game_manager.player.player_name
					name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					name_label.add_theme_font_size_override("font_size", 18)
					name_label.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
					hbox.add_child(name_label)

					var floor_label = Label.new()
					floor_label.text = "第 %d 层" % local_highest
					floor_label.custom_minimum_size = Vector2(100, 0)
					floor_label.add_theme_font_size_override("font_size", 18)
					floor_label.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
					floor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
					hbox.add_child(floor_label)


					network.update_tower_highest(local_highest, game_manager.player.tower_floor)
				else:
					var empty_label = Label.new()
					empty_label.text = "暂无排行数据"
					empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
					list.add_child(empty_label)
				_enable_touch_drag_passthrough(list)
				return


			for i in range(rankings.size()):
				var r = rankings[i]
				var rank_panel = Panel.new()
				rank_panel.custom_minimum_size = Vector2(0, 50)
				rank_panel.add_theme_stylebox_override("panel", UIStyle.create_rank_style(i))
				list.add_child(rank_panel)

				var hbox = HBoxContainer.new()
				hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
				hbox.offset_left = 10
				hbox.offset_top = 10
				hbox.offset_right = -10
				hbox.offset_bottom = -10
				rank_panel.add_child(hbox)


				var rank_label = Label.new()
				var rank_text = str(i + 1)
				if i == 0:
					rank_text = "🥇"
				elif i == 1:
					rank_text = "🥈"
				elif i == 2:
					rank_text = "🥉"
				rank_label.text = rank_text
				rank_label.custom_minimum_size = Vector2(40, 0)
				rank_label.add_theme_font_size_override("font_size", 18)
				rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				hbox.add_child(rank_label)


				var name_label = Label.new()
				name_label.text = r.get("nickname", r.get("username", "未知"))
				name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				name_label.add_theme_font_size_override("font_size", 18)
				name_label.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
				hbox.add_child(name_label)


				var floor_label = Label.new()
				floor_label.text = "第 %d 层" % int(r.get("tower_highest", 0))
				floor_label.custom_minimum_size = Vector2(100, 0)
				floor_label.add_theme_font_size_override("font_size", 18)
				floor_label.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
				floor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				hbox.add_child(floor_label)
			_enable_touch_drag_passthrough(list)
		, CONNECT_ONE_SHOT)


		print("[TOWER_RANKING] Requesting tower ranking...")
		network.get_tower_ranking()
	else:

		for child in list.get_children():
			child.queue_free()

		var test_data = [
			{"nickname": "大佬", "tower_highest": 450}, 
			{"nickname": "剑仙", "tower_highest": 380}, 
			{"nickname": "魔道", "tower_highest": 320}, 
			{"nickname": "散修", "tower_highest": 250}, 
			{"nickname": "小道", "tower_highest": 180}, 
		]

		for i in range(test_data.size()):
			var r = test_data[i]
			var rank_panel = Panel.new()
			rank_panel.custom_minimum_size = Vector2(0, 50)
			rank_panel.add_theme_stylebox_override("panel", UIStyle.create_rank_style(i))
			list.add_child(rank_panel)

			var hbox = HBoxContainer.new()
			hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
			hbox.offset_left = 10
			hbox.offset_top = 10
			hbox.offset_right = -10
			hbox.offset_bottom = -10
			rank_panel.add_child(hbox)

			var rank_label = Label.new()
			var rank_text = str(i + 1)
			if i == 0:
				rank_text = "🥇"
			elif i == 1:
				rank_text = "🥈"
			elif i == 2:
				rank_text = "🥉"
			rank_label.text = rank_text
			rank_label.custom_minimum_size = Vector2(40, 0)
			rank_label.add_theme_font_size_override("font_size", 18)
			rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			hbox.add_child(rank_label)

			var name_label = Label.new()
			name_label.text = r.get("nickname", "未知")
			name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			name_label.add_theme_font_size_override("font_size", 18)
			name_label.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
			hbox.add_child(name_label)

			var floor_label = Label.new()
			floor_label.text = "第 %d 层" % int(r.get("tower_highest", 0))
			floor_label.custom_minimum_size = Vector2(100, 0)
			floor_label.add_theme_font_size_override("font_size", 18)
			floor_label.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
			floor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			hbox.add_child(floor_label)
		_enable_touch_drag_passthrough(list)

static func _format_number(num: int) -> String:
	if num >= 100000000:
		return "%.2f亿" % (num / 100000000.0)
	elif num >= 10000:
		return "%.1f万" % (num / 10000.0)
	else:
		return str(num)

static func _center_popup_in_parent(popup: Control, parent_control: Control) -> void :
	if not is_instance_valid(popup) or not is_instance_valid(parent_control):
		return
	popup.reset_size()
	var popup_size: Vector2 = popup.size
	if popup_size.x <= 0 or popup_size.y <= 0:
		popup_size = popup.custom_minimum_size
	popup.position = (parent_control.size - popup_size) / 2

static func _schedule_center_popup_in_parent(popup: Control, parent_control: Control) -> void :
	_center_popup_in_parent(popup, parent_control)
	if not is_instance_valid(parent_control):
		return
	var tree = parent_control.get_tree()
	if tree == null:
		return
	tree.create_timer(0.0).timeout.connect( func() -> void :
		_center_popup_in_parent(popup, parent_control)
	, CONNECT_ONE_SHOT)

static func _show_message_fullscreen(parent_control: Control, message: String):
	var popup_key = "tower_message_popup:%s" % message
	if _focus_existing_child_popup(parent_control, popup_key):
		return
	var popup = Panel.new()
	_mark_popup_key(popup, popup_key)
	var line_count: int = message.split("\n").size()
	var content_height: int = maxi(80, line_count * 24)
	var popup_height: int = clampi(140 + content_height, 220, 560)
	popup.custom_minimum_size = Vector2(420, popup_height)
	popup.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	parent_control.add_child(popup)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 25
	vbox.offset_top = 25
	vbox.offset_right = -25
	vbox.offset_bottom = -25
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	popup.add_child(vbox)

	var msg_label = RichTextLabel.new()
	msg_label.bbcode_enabled = true
	msg_label.text = message
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.add_theme_font_size_override("normal_font_size", 18)
	msg_label.add_theme_color_override("default_color", Color(0.894, 0.864, 0.803))
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	msg_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(msg_label)

	var ok_btn = Button.new()
	ok_btn.text = "确定"
	UIStyle.style_popup_button(ok_btn, true)
	ok_btn.pressed.connect( func(): popup.queue_free())
	vbox.add_child(ok_btn)
	_schedule_center_popup_in_parent(popup, parent_control)
