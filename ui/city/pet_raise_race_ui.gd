class_name PetRaiseRaceUI
extends RefCounted

const UIStyle = preload("res://scripts/ui_style.gd")
const WindowHost = preload("res://scripts/ui/window_host.gd")
const GameData = preload("res://scripts/game_data.gd")
const ConfirmDialog = preload("res://ui/components/confirm_dialog.gd")

const OUTER_MARGIN: = 14
const PANEL_INNER_MARGIN: = 12
const RANK_PREVIEW_LIMIT: = 10
const RANK_POPUP_LIMIT: = 100
const RANK_NUM_COL_WIDTH: = 36
const PICKER_DIFF_COLOR: = Color(0.35, 0.95, 0.72)
const PET_RAISE_UI_DIR: = "res://assets/ui/pet_raise_race/"
const PET_RAISE_BG_PATH: = PET_RAISE_UI_DIR + "pet_raise_bg_atmosphere.jpg"

static func _load_pet_raise_bg_tex() -> Texture2D:
	if ResourceLoader.exists(PET_RAISE_BG_PATH):
		return load(PET_RAISE_BG_PATH) as Texture2D
	if FileAccess.file_exists(PET_RAISE_BG_PATH):
		var img: = Image.load_from_file(ProjectSettings.globalize_path(PET_RAISE_BG_PATH))
		if img != null and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null

static func create_content(game_manager, _parent: Control) -> Control:
	var root: = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.clip_contents = true

	var bg: = TextureRect.new()
	bg.name = "PetRaiseBg"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.modulate = Color(1, 1, 1, 0.8)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.texture = _load_pet_raise_bg_tex()
	root.add_child(bg)

	var scroll: = ScrollContainer.new()
	scroll.name = "MainScroll"
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.scroll_deadzone = 20
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(scroll)

	var outer_margin: = MarginContainer.new()
	outer_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer_margin.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	outer_margin.add_theme_constant_override("margin_left", OUTER_MARGIN)
	outer_margin.add_theme_constant_override("margin_right", OUTER_MARGIN)
	outer_margin.add_theme_constant_override("margin_top", OUTER_MARGIN)
	outer_margin.add_theme_constant_override("margin_bottom", OUTER_MARGIN)
	scroll.add_child(outer_margin)

	var main_vbox: = VBoxContainer.new()
	main_vbox.name = "MainVBox"
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	main_vbox.add_theme_constant_override("separation", 14)
	outer_margin.add_child(main_vbox)

	var title: = Label.new()
	title.text = "🐾 养宠赛"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	main_vbox.add_child(title)

	var activity_label: = Label.new()
	activity_label.name = "ActivityLabel"
	activity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	activity_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	activity_label.add_theme_font_size_override("font_size", 15)
	main_vbox.add_child(activity_label)

	var stats_row: = HBoxContainer.new()
	stats_row.name = "StatsRow"
	stats_row.add_theme_constant_override("separation", 8)
	main_vbox.add_child(stats_row)
	stats_row.add_child(_create_stat_card("今日目标", "-", "TargetValue"))
	stats_row.add_child(_create_stat_card("我的排名", "-", "MyRankValue"))
	stats_row.add_child(_create_stat_card("我的差值", "-", "MyDiffValue"))

	var status_label: = Label.new()
	status_label.name = "StatusLabel"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.text = "同步中..."
	main_vbox.add_child(status_label)

	var action_row: = HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 12)
	main_vbox.add_child(action_row)
	var submit_btn: = Button.new()
	submit_btn.name = "SubmitBtn"
	submit_btn.text = "提交宠物"
	submit_btn.custom_minimum_size = Vector2(140, 42)
	UIStyle.apply_golden_button_style(submit_btn)
	UIStyle.setup_button_animation(submit_btn)
	action_row.add_child(submit_btn)
	var refresh_btn: = Button.new()
	refresh_btn.name = "RefreshBtn"
	refresh_btn.text = "刷新"
	refresh_btn.custom_minimum_size = Vector2(100, 42)
	UIStyle.apply_button_style(refresh_btn)
	action_row.add_child(refresh_btn)

	var rank_panel: = _create_section_panel()
	rank_panel.name = "RankPanel"
	main_vbox.add_child(rank_panel)
	var rank_inner: = _panel_inner_vbox(rank_panel)
	var rank_title: = Label.new()
	rank_title.text = "今日排行（前10）"
	rank_title.add_theme_font_size_override("font_size", 16)
	rank_title.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
	rank_inner.add_child(rank_title)
	var rank_list: = VBoxContainer.new()
	rank_list.name = "RankList"
	rank_list.add_theme_constant_override("separation", 4)
	rank_inner.add_child(rank_list)
	var rank_more_row: = CenterContainer.new()
	rank_inner.add_child(rank_more_row)
	var rank_more_btn: = Button.new()
	rank_more_btn.name = "RankMoreBtn"
	rank_more_btn.text = "查看更多"
	rank_more_btn.custom_minimum_size = Vector2(100, 34)
	rank_more_btn.add_theme_font_size_override("font_size", 14)
	UIStyle.apply_button_style(rank_more_btn)
	rank_more_row.add_child(rank_more_btn)

	var rules_panel: = _create_section_panel()
	main_vbox.add_child(rules_panel)
	var rules_inner: = _panel_inner_vbox(rules_panel)
	var rules_title: = Label.new()
	rules_title.text = "规则说明"
	rules_title.add_theme_font_size_override("font_size", 16)
	rules_title.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
	rules_inner.add_child(rules_title)
	var rules_label: = Label.new()
	rules_label.name = "RulesLabel"
	rules_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules_label.add_theme_font_size_override("font_size", 14)
	rules_label.add_theme_color_override("font_color", Color(0.842, 0.816, 0.756))
	rules_label.text = _default_rules_text()
	rules_inner.add_child(rules_label)

	root.set_meta("game_manager", game_manager)
	root.set_meta("submit_growth_min", 20.0)
	root.set_meta("submit_growth_max", 44.999)
	root.set_meta("target_growth", 0.0)
	submit_btn.pressed.connect( func(): _on_submit_pressed(game_manager, root))
	refresh_btn.pressed.connect( func(): refresh_panel(game_manager, root))
	rank_more_btn.pressed.connect( func(): _on_rank_more_pressed(game_manager, root))
	_enable_touch_drag_passthrough(main_vbox)
	return root


static func refresh_panel(game_manager, root: Control) -> void :
	if game_manager == null or root == null or not is_instance_valid(root):
		return
	if game_manager.network == null:
		_set_status(root, "网络未连接", true)
		return
	_set_status(root, "同步中...", false)
	var res: Dictionary = await game_manager.network.request_pet_raise_race_status()
	if not _api_ok(res):
		_set_status(root, str(res.get("error", "加载失败")), true)
		return
	_apply_status(root, res)


static func _apply_status(root: Control, data: Dictionary) -> void :
	var cfg: Dictionary = data.get("config", {}) if data.get("config") is Dictionary else {}
	var feature_on: = bool(data.get("featureEnabled", cfg.get("featureEnabled", false)))
	var target: = float(data.get("targetGrowth", data.get("target_growth", 0)))
	var my_rank: = int(data.get("myRank", data.get("my_rank", 0)))
	var has_submitted: = bool(data.get("hasSubmitted", data.get("has_submitted", false)))
	var in_window: = bool(data.get("inSubmitWindow", data.get("in_submit_window", false)))
	var phase: = str(data.get("phase", ""))
	var settled: = bool(data.get("settled", false))
	var my_entry: Dictionary = data.get("myEntry", data.get("my_entry", {})) if data.get("myEntry", data.get("my_entry", null)) is Dictionary else {}

	var target_l: Label = _find_node(root, "TargetValue") as Label
	var rank_l: Label = _find_node(root, "MyRankValue") as Label
	var diff_l: Label = _find_node(root, "MyDiffValue") as Label
	var activity_l: Label = _find_node(root, "ActivityLabel") as Label
	var rules_l: Label = _find_node(root, "RulesLabel") as Label
	var submit_btn: Button = _find_node(root, "SubmitBtn") as Button
	var rank_list: VBoxContainer = _find_node(root, "RankList") as VBoxContainer

	if target_l != null:
		target_l.text = "%.3f" % target if target > 0.0 else "-"
	if rank_l != null:
		if has_submitted and my_rank > 0:
			rank_l.text = "100+" if my_rank > 100 else str(my_rank)
		elif has_submitted:
			rank_l.text = "100+"
		else:
			rank_l.text = "-"
	if diff_l != null:
		if has_submitted and my_entry.has("diff"):
			diff_l.text = "%.3f" % float(my_entry.get("diff", 0))
		else:
			diff_l.text = "-"

	var time_range: = str(cfg.get("submitTimeRange", "8:00–22:15"))
	var settle_h: = int(cfg.get("settleHour", 22))
	var settle_m: = int(cfg.get("settleMinute", 20))
	if activity_l != null:
		if not feature_on:
			activity_l.text = "玩法暂未开放"
		elif settled or phase == "settled":
			activity_l.text = "今日已结算公布 · 提交时间 %s" % time_range
		elif phase == "awaiting_result" or phase == "settling":
			activity_l.text = "提交已截止，等待 %d:%02d 公布结果" % [settle_h, settle_m]
		elif in_window:
			activity_l.text = "提交进行中 · %s（北京时间）" % time_range
		else:
			activity_l.text = "未到提交时间 · 今日窗口 %s" % time_range

	if rules_l != null:
		var desc: = str(cfg.get("descriptionText", "")).strip_edges()
		rules_l.text = desc if not desc.is_empty() else _default_rules_text()

	var growth_min: = float(cfg.get("targetGrowthMin", cfg.get("target_growth_min", 20.0)))
	if growth_min <= 0.0:
		growth_min = 20.0
	var growth_max: = float(cfg.get("targetGrowthMax", cfg.get("target_growth_max", 44.999)))
	if growth_max <= 0.0:
		growth_max = 44.999
	root.set_meta("submit_growth_min", growth_min)
	root.set_meta("submit_growth_max", growth_max)
	root.set_meta("target_growth", target)
	root.set_meta("used_pet_instance_ids", _collect_used_pet_ids_from_status(data, my_entry))

	if submit_btn != null:
		submit_btn.disabled = ( not feature_on) or ( not in_window) or has_submitted or settled
		if not feature_on:
			submit_btn.text = "暂未开放"
		elif has_submitted:
			submit_btn.text = "今日已提交"
		elif settled:
			submit_btn.text = "已结算"
		elif not in_window:
			submit_btn.text = "非提交时段"
		else:
			submit_btn.text = "提交宠物"

	var ranking: Array = data.get("ranking", []) if data.get("ranking") is Array else []
	_refresh_rank_preview(rank_list, ranking)

	var status_msg: = "已同步"
	if has_submitted and my_entry.has("petName"):
		status_msg = "已提交【%s】成长 %.3f，差值 %.3f" % [
			str(my_entry.get("petName", "")), 
			float(my_entry.get("petGrowth", 0)), 
			float(my_entry.get("diff", 0)), 
		]
	elif not feature_on:
		status_msg = "养宠赛暂未开放"
	_set_status(root, status_msg, false)


static func _refresh_rank_preview(rank_list: VBoxContainer, ranking: Array) -> void :
	if rank_list == null:
		return
	for child in rank_list.get_children():
		child.queue_free()
	_add_ranking_table_header(rank_list)
	if ranking.is_empty():
		var empty: = Label.new()
		empty.text = "暂无报名"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rank_list.add_child(empty)
		_enable_touch_drag_passthrough(rank_list)
		return
	var shown: = 0
	for entry in ranking:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		if shown >= RANK_PREVIEW_LIMIT:
			break
		_add_ranking_table_row(rank_list, entry as Dictionary, false, shown % 2 == 0)
		shown += 1
	_enable_touch_drag_passthrough(rank_list)


static func _on_rank_more_pressed(game_manager, root: Control) -> void :
	if game_manager == null or game_manager.network == null or root == null:
		return
	var parent: = root.get_parent()
	while parent != null and not (parent is Control):
		parent = parent.get_parent()
	if parent == null:
		parent = root
	var res: Dictionary = await game_manager.network.request_pet_raise_race_ranking(RANK_POPUP_LIMIT)
	if not _api_ok(res):
		_set_status(root, str(res.get("error", "加载排行失败")), true)
		return
	var ranking: Array = res.get("ranking", []) if res.get("ranking") is Array else []
	_show_ranking_popup(parent as Control, ranking)


static func _show_ranking_popup(parent: Control, ranking: Array) -> void :
	if parent == null or not is_instance_valid(parent):
		return
	var popup: = Window.new()
	popup.title = ""
	popup.size = Vector2i(560, 640)
	popup.transparent = true
	popup.borderless = true
	popup.unresizable = true
	popup.close_requested.connect( func():
		if is_instance_valid(popup):
			popup.queue_free()
	)

	var main_panel: = Panel.new()
	main_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_panel.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	popup.add_child(main_panel)

	var vbox: = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 12)
	main_panel.add_child(vbox)

	var title: = Label.new()
	title.text = "养宠赛排行榜（前%d名）" % RANK_POPUP_LIMIT
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(title)

	var scroll: = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.scroll_deadzone = 20
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	vbox.add_child(scroll)

	var rank_list: = VBoxContainer.new()
	rank_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rank_list.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	rank_list.add_theme_constant_override("separation", 2)
	scroll.add_child(rank_list)
	_add_ranking_table_header(rank_list)
	var shown: = 0
	for entry in ranking:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		if shown >= RANK_POPUP_LIMIT:
			break
		_add_ranking_table_row(rank_list, entry as Dictionary, false, shown % 2 == 0)
		shown += 1
	if shown == 0:
		var empty: = Label.new()
		empty.text = "暂无报名"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rank_list.add_child(empty)
	_enable_touch_drag_passthrough(rank_list)

	var close_row: = CenterContainer.new()
	vbox.add_child(close_row)
	var close_btn: = Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(120, 42)
	UIStyle.apply_button_style(close_btn)
	close_btn.pressed.connect( func():
		if is_instance_valid(popup):
			popup.queue_free()
	)
	close_row.add_child(close_btn)
	WindowHost.attach_window_and_popup_centered(popup, parent)


static func _on_submit_pressed(game_manager, root: Control) -> void :
	if game_manager == null or root == null:
		return
	if bool(root.get_meta("submit_pending", false)):
		return
	var parent: = root.get_parent()
	while parent != null and not (parent is Control):
		parent = parent.get_parent()
	if parent == null:
		parent = root
	_show_pet_picker(game_manager, root, parent as Control)


static func _show_pet_picker(game_manager, root: Control, parent: Control) -> void :
	var pets: Array = _collect_eligible_pets(game_manager, root)
	if pets.is_empty():
		var growth_min: = float(root.get_meta("submit_growth_min", 20.0))
		var growth_max: = float(root.get_meta("submit_growth_max", 44.999))
		ConfirmDialog.show_message(parent, "无法提交", "没有符合条件的宠物。\n需要：3代、未转生、基础满级（可进化1200且须终极形态 / 不可进化1500）、未锁定、成长在 %.3f–%.3f、且未参加过养宠赛。" % [growth_min, growth_max])
		return
	var target_growth: = 0.0
	if root != null and is_instance_valid(root):
		target_growth = float(root.get_meta("target_growth", 0.0))
	_sort_pets_by_growth_diff_asc(pets, target_growth)

	var popup: = Window.new()
	popup.title = ""
	popup.size = Vector2i(420, 520)
	popup.transparent = true
	popup.borderless = true
	popup.unresizable = true
	popup.close_requested.connect( func():
		if is_instance_valid(popup):
			popup.queue_free()
	)

	var main_panel: = Panel.new()
	main_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_panel.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	popup.add_child(main_panel)

	var vbox: = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 16
	vbox.offset_top = 16
	vbox.offset_right = -16
	vbox.offset_bottom = -16
	vbox.add_theme_constant_override("separation", 10)
	main_panel.add_child(vbox)

	var title: = Label.new()
	title.text = "选择参赛宠物"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(title)

	var tip: = Label.new()
	tip.text = "提交的是成长镜像，宠物不会消失；该宠终身不可再交，今日账号仅一次"
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.add_theme_font_size_override("font_size", 13)
	tip.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45))
	vbox.add_child(tip)

	var scroll: = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.scroll_deadzone = 20
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	vbox.add_child(scroll)
	TouchScrollUtils.configure_scroll(scroll)

	var list: = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)

	for pet in pets:
		var btn: = Button.new()
		var pet_name: = str(pet.pet_name)
		var growth: = float(snapped(float(pet.total_growth), 0.001))
		var level: = int(pet.level)
		btn.text = ""
		btn.custom_minimum_size = Vector2(0, 44)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UIStyle.apply_button_style(btn)
		var row: = HBoxContainer.new()
		row.set_anchors_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 10
		row.offset_right = -10
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 8)
		btn.add_child(row)
		var info: = Label.new()
		info.text = "%s  Lv.%d  成长%.3f" % [pet_name, level, growth]
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.clip_text = true
		info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		info.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info.add_theme_font_size_override("font_size", 15)
		row.add_child(info)
		if target_growth > 0.0:
			var diff: = float(snapped(abs(growth - target_growth), 0.001))
			var diff_l: = Label.new()
			diff_l.text = "差值%.3f" % diff
			diff_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			diff_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			diff_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			diff_l.add_theme_font_size_override("font_size", 15)
			diff_l.add_theme_color_override("font_color", PICKER_DIFF_COLOR)
			row.add_child(diff_l)
		var pet_id: = str(pet.id)
		TouchScrollUtils.bind_tap(btn, func():
			if is_instance_valid(popup):
				popup.queue_free()
			_confirm_and_submit(game_manager, root, parent, pet_id, pet_name, growth)
		)
		list.add_child(btn)
	_enable_touch_drag_passthrough(list)

	var close_row: = CenterContainer.new()
	vbox.add_child(close_row)
	var close_btn: = Button.new()
	close_btn.text = "取消"
	close_btn.custom_minimum_size = Vector2(120, 40)
	UIStyle.apply_button_style(close_btn)
	close_btn.pressed.connect( func():
		if is_instance_valid(popup):
			popup.queue_free()
	)
	close_row.add_child(close_btn)
	WindowHost.attach_window_and_popup_centered(popup, parent)


static func _sort_pets_by_growth_diff_asc(pets: Array, target_growth: float) -> void :
	if pets.size() <= 1 or target_growth <= 0.0:
		return
	pets.sort_custom( func(a, b) -> bool:
		if a == null:
			return false
		if b == null:
			return true
		var da: = float(snapped(abs(float(a.total_growth) - target_growth), 0.001))
		var db: = float(snapped(abs(float(b.total_growth) - target_growth), 0.001))
		return da < db
	)


static func _confirm_and_submit(game_manager, root: Control, parent: Control, pet_id: String, pet_name: String, growth: float) -> void :
	ConfirmDialog.show(
		parent, 
		"确认提交", 
		"确定提交【%s】（成长 %.3f）的镜像参加养宠赛吗？\n宠物不会消失，但该宠终身不可再交；今日账号仅可提交一次。" % [pet_name, growth], 
		func():
			_do_submit(game_manager, root, pet_id), 
		"确认提交", 
		"取消"
	)


static func _do_submit(game_manager, root: Control, pet_id: String) -> void :
	if game_manager == null or game_manager.network == null or root == null:
		return
	if bool(root.get_meta("submit_pending", false)):
		return
	root.set_meta("submit_pending", true)
	_set_status(root, "提交中...", false)
	var op_id: = "pet_raise_race_%s_%d" % [pet_id, Time.get_unix_time_from_system()]
	var res: Dictionary = await game_manager.network.request_pet_raise_race_submit(pet_id, op_id)
	root.set_meta("submit_pending", false)
	if not _api_ok(res):
		_set_status(root, str(res.get("error", "提交失败")), true)
		return
	_mark_live_pet_raise_race_used(game_manager, pet_id)
	if res.get("saveData") is Dictionary and game_manager.has_method("apply_cloud_save"):
		game_manager.apply_cloud_save(res.get("saveData"), {"pets_authoritative": true})
	_mark_live_pet_raise_race_used(game_manager, pet_id)
	_apply_status(root, res)
	_set_status(root, str(res.get("message", "提交成功")), false)


static func _collect_eligible_pets(game_manager, root: Control = null) -> Array:
	var out: Array = []
	if game_manager == null or game_manager.pet_manager == null:
		return out
	var growth_min: = 20.0
	var growth_max: = 44.999
	if root != null and is_instance_valid(root):
		growth_min = float(root.get_meta("submit_growth_min", 20.0))
		growth_max = float(root.get_meta("submit_growth_max", 44.999))
	var used_ids: Dictionary = {}
	if root != null and is_instance_valid(root):
		var meta_used = root.get_meta("used_pet_instance_ids", [])
		if meta_used is Array:
			for uid in meta_used:
				var sid: = str(uid).strip_edges()
				if not sid.is_empty():
					used_ids[sid] = true
	var pm = game_manager.pet_manager
	var all_pets: Array = []
	all_pets.append_array(pm.pets)
	all_pets.append_array(pm.pet_bag)
	for pet in all_pets:
		if pet == null:
			continue
		var pid: = str(pet.id).strip_edges()
		if not pid.is_empty() and used_ids.has(pid):
			continue
		if not _is_pet_eligible(pet, growth_min, growth_max):
			continue
		out.append(pet)
	return out


static func _collect_used_pet_ids_from_status(data: Dictionary, my_entry: Dictionary) -> Array:
	var out: Array = []
	var seen: Dictionary = {}
	var raw: Variant = data.get("usedPetInstanceIds", data.get("used_pet_instance_ids", []))
	if raw is Array:
		for item in raw:
			var sid: = str(item).strip_edges()
			if sid.is_empty() or seen.has(sid):
				continue
			seen[sid] = true
			out.append(sid)
	if my_entry is Dictionary:
		var mid: = str(my_entry.get("petInstanceId", my_entry.get("pet_instance_id", ""))).strip_edges()
		if not mid.is_empty() and not seen.has(mid):
			out.append(mid)
	return out


static func _mark_live_pet_raise_race_used(game_manager, pet_id: String) -> void :
	var pid: = str(pet_id).strip_edges()
	if pid.is_empty() or game_manager == null or game_manager.pet_manager == null:
		return
	var pm = game_manager.pet_manager
	for roster in [pm.pets, pm.pet_bag, pm.assist_pets]:
		if not roster is Array:
			continue
		for pet in roster:
			if pet != null and str(pet.id).strip_edges() == pid:
				pet.pet_raise_race_used = true


static func _is_pet_eligible(pet, growth_min: float = 20.0, growth_max: float = 44.999) -> bool:
	if pet == null:
		return false
	if bool(pet.locked):
		return false
	if bool(pet.pet_raise_race_used):
		return false
	if int(pet.generation) != 3:
		return false
	if int(pet.reincarnation_count) != 0:
		return false
	var growth: float = float(snapped(float(pet.total_growth), 0.001))
	if growth < growth_min:
		return false
	if growth > growth_max:
		return false
	var is_evo: = false
	if pet.has_method("resolve_is_on_evolution_chain"):
		is_evo = bool(pet.resolve_is_on_evolution_chain())
	else:
		is_evo = bool(pet.is_evolution_pet)
	if is_evo and str(pet.form).strip_edges() != "终极":
		return false
	var base_max: = GameData.MAX_LEVEL_EVOLUTION if is_evo else GameData.MAX_LEVEL_NORMAL
	return int(pet.level) == base_max


static func _add_ranking_table_header(parent: VBoxContainer) -> void :
	_add_ranking_header_row(parent)


static func _add_ranking_header_row(parent: Node) -> void :
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	_add_rank_col(row, "排名", 14, true, RANK_NUM_COL_WIDTH)
	_add_rank_col(row, "宠物", 14, true, 0, true)
	_add_rank_col(row, "成长", 14, true, 72)
	_add_rank_col(row, "差值", 14, true, 72)
	_add_rank_col(row, "玩家", 14, true, 0, true)


static func _add_ranking_table_row(parent: Node, entry: Dictionary, is_header: bool, odd_row: bool) -> void :
	var row_font_size: = 14
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var row_panel: = PanelContainer.new()
	row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style: = StyleBoxFlat.new()
	style.bg_color = Color(0.072, 0.080, 0.079, 0.55) if odd_row else Color(0.066, 0.074, 0.074, 0.4)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.content_margin_left = 6
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	row_panel.add_theme_stylebox_override("panel", style)
	row_panel.add_child(row)
	parent.add_child(row_panel)

	var rank_no: = int(entry.get("rank", 0))
	var pet_name: = str(entry.get("petName", entry.get("pet_name", "灵宠")))
	var growth: float = float(entry.get("petGrowth", entry.get("pet_growth", 0)))
	var diff: float = float(entry.get("diff", 0))
	var player_name: = str(entry.get("playerName", entry.get("player_name", "未知")))
	_add_rank_col(row, str(rank_no), row_font_size, false, RANK_NUM_COL_WIDTH)
	_add_rank_col(row, pet_name, row_font_size, false, 0, true)
	_add_rank_col(row, "%.3f" % growth, row_font_size, false, 72)
	_add_rank_col(row, "%.3f" % diff, row_font_size, false, 72)
	_add_rank_col(row, player_name, row_font_size, false, 0, true)


static func _add_rank_col(row: HBoxContainer, text: String, font_size: int, is_header: bool, fixed_w: int = 0, expand: bool = false) -> void :
	var lab: = Label.new()
	lab.text = text
	lab.add_theme_font_size_override("font_size", font_size)
	if is_header:
		lab.add_theme_color_override("font_color", Color(0.894, 0.864, 0.803))
	else:
		lab.add_theme_color_override("font_color", Color(0.904, 0.874, 0.812))
	if fixed_w > 0:
		lab.custom_minimum_size.x = fixed_w
	if expand:
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lab.clip_text = true
	row.add_child(lab)


static func _create_stat_card(title: String, value: String, value_name: String) -> PanelContainer:
	var panel: = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style: = StyleBoxFlat.new()
	style.bg_color = Color(0.072, 0.080, 0.079, 0.85)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	var col: = VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	panel.add_child(col)
	var t: = Label.new()
	t.text = title
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 18)
	t.add_theme_color_override("font_color", Color(0.791, 0.769, 0.708))
	col.add_child(t)
	var v: = Label.new()
	v.name = value_name
	v.text = value
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_theme_font_size_override("font_size", 20)
	v.add_theme_color_override("font_color", Color(1, 0.9, 0.45))
	col.add_child(v)
	return panel


static func _create_section_panel() -> PanelContainer:
	var panel: = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style: = UIStyle.create_item_style()
	style.content_margin_left = PANEL_INNER_MARGIN
	style.content_margin_right = PANEL_INNER_MARGIN
	style.content_margin_top = PANEL_INNER_MARGIN
	style.content_margin_bottom = PANEL_INNER_MARGIN
	panel.add_theme_stylebox_override("panel", style)
	return panel


static func _panel_inner_vbox(panel: PanelContainer) -> VBoxContainer:
	var vbox: = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	return vbox


static func _enable_touch_drag_passthrough(root: Control) -> void :
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


static func _find_node(root: Node, node_name: String) -> Node:
	if root == null:
		return null
	if root.name == node_name:
		return root
	return root.find_child(node_name, true, false)


static func _api_ok(res: Dictionary) -> bool:
	return bool(res.get("ok", false)) or bool(res.get("success", false))


static func _set_status(root: Control, text: String, is_error: bool) -> void :
	var status_label: Label = _find_node(root, "StatusLabel") as Label
	if status_label == null:
		return
	status_label.text = text
	if is_error:
		status_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.4))
	else:
		status_label.add_theme_color_override("font_color", Color(0.863, 0.836, 0.774))


static func _default_rules_text() -> String:
	return "每日 8:00–22:15（北京时间）可提交一只 3 代、未转生、基础满级（可进化须终极形态）、成长在 20.000–44.999 的宠物镜像；宠物不消失，但该宠终身不可再交；每人每天一次。\n排名看成长与目标差值，越小越靠前；相同则先提交者优先。\n22:20 公布结果，第 1 名邮件发放随机五行变异宠物蛋。"
