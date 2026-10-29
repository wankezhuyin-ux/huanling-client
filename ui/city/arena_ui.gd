class_name ArenaUI
extends RefCounted

const UIStyle = preload("res://scripts/ui_style.gd")
const ArenaConfig = preload("res://scripts/arena/arena_config.gd")
const PlayerCharacterConfig = preload("res://scripts/player_character_config.gd")
const WindowHost = preload("res://scripts/ui/window_host.gd")
const BattleLogReport = preload("res://scripts/ui/battle_log_report.gd")
const BattleSnapshotDisplay = preload("res://scripts/ui/battle_snapshot_display.gd")
const PetIdleDisplay = preload("res://scripts/ui/pet_idle_display.gd")
const GameData = preload("res://scripts/game_data.gd")

const OUTER_MARGIN: = 14
const PANEL_INNER_MARGIN: = 12
const TOP3_AVATAR_FIRST: = 88
const TOP3_AVATAR_OTHER: = 64
const TOP3_BADGE_FIRST: = 32
const TOP3_BADGE_OTHER: = 24
const RANK_PREVIEW_LIMIT: = 10
const RANK_POPUP_LIMIT: = 100
const RANK_AVATAR_SIZE: = 32
const MIRROR_PORTRAIT_SIZE: = Vector2(96, 96)
const MIRROR_POPUP_SIZE: = Vector2i(400, 540)
const RANK_NUM_COL_WIDTH: = 32
const ARENA_UI_DIR: = "res://assets/ui/arena/"
const ARENA_BG_PATH: = ARENA_UI_DIR + "arena_bg_atmosphere.jpg"
const WB_UI_DIR: = "res://assets/ui/world_boss/"
const WB_BADGE_GOLD_PATH: = WB_UI_DIR + "wb_badge_gold.png"
const WB_BADGE_SILVER_PATH: = WB_UI_DIR + "wb_badge_silver.png"
const WB_BADGE_BRONZE_PATH: = WB_UI_DIR + "wb_badge_bronze.png"

static func _load_arena_bg_tex() -> Texture2D:
	if ResourceLoader.exists(ARENA_BG_PATH):
		return load(ARENA_BG_PATH) as Texture2D
	if FileAccess.file_exists(ARENA_BG_PATH):
		var img: = Image.load_from_file(ProjectSettings.globalize_path(ARENA_BG_PATH))
		if img != null and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null


static func _load_ui_tex(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	if FileAccess.file_exists(path):
		var img: = Image.load_from_file(ProjectSettings.globalize_path(path))
		if img != null and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null

static func create_content(game_manager, _parent: Control) -> Control:
	var root: = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.clip_contents = true

	var bg: = TextureRect.new()
	bg.name = "ArenaBg"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.modulate = Color(1, 1, 1, 0.55)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.texture = _load_arena_bg_tex()
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
	title.text = "⚔️ 竞技场"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	main_vbox.add_child(title)

	var activity_label: = Label.new()
	activity_label.name = "ActivityLabel"
	activity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	activity_label.add_theme_font_size_override("font_size", 15)
	main_vbox.add_child(activity_label)

	var stats_row: = HBoxContainer.new()
	stats_row.name = "StatsRow"
	stats_row.add_theme_constant_override("separation", 8)
	main_vbox.add_child(stats_row)
	stats_row.add_child(_create_stat_card("当周积分", "0", "WeeklyPointsValue"))
	stats_row.add_child(_create_stat_card("上周结余", "0", "BalancePointsValue"))
	stats_row.add_child(_create_stat_card("我的排名", "-", "RankStatValue"))
	stats_row.add_child(_create_stat_card("剩余次数", "0", "AttemptsStatValue"))

	var status_label: = Label.new()
	status_label.name = "StatusLabel"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.text = "同步中..."
	main_vbox.add_child(status_label)

	var top3_panel: = _create_section_panel()
	top3_panel.name = "Top3Panel"
	main_vbox.add_child(top3_panel)
	var top3_inner: = _panel_inner_vbox(top3_panel)
	var top3_title: = Label.new()
	top3_title.text = "本周前三"
	top3_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top3_title.add_theme_font_size_override("font_size", 16)
	top3_title.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
	top3_inner.add_child(top3_title)
	var top3_row: = HBoxContainer.new()
	top3_row.name = "Top3Row"
	top3_row.alignment = BoxContainer.ALIGNMENT_CENTER
	top3_row.add_theme_constant_override("separation", 16)
	top3_inner.add_child(top3_row)

	var action_row: = HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 12)
	main_vbox.add_child(action_row)
	var mirror_btn: = Button.new()
	mirror_btn.name = "MirrorBtn"
	mirror_btn.text = "更新/查看镜像"
	mirror_btn.custom_minimum_size = Vector2(140, 44)
	UIStyle.apply_button_style(mirror_btn)
	action_row.add_child(mirror_btn)
	var match_btn: = Button.new()
	match_btn.name = "MatchBtn"
	match_btn.text = "开始匹配"
	match_btn.custom_minimum_size = Vector2(160, 48)
	match_btn.add_theme_font_size_override("font_size", 18)
	_style_primary_action_button(match_btn)
	action_row.add_child(match_btn)
	var history_btn: = Button.new()
	history_btn.name = "HistoryBtn"
	history_btn.text = "挑战记录"
	history_btn.custom_minimum_size = Vector2(120, 44)
	history_btn.add_theme_font_size_override("font_size", 16)
	UIStyle.apply_button_style(history_btn)
	action_row.add_child(history_btn)

	var rank_panel: = _create_section_panel()
	rank_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(rank_panel)
	var rank_inner: = _panel_inner_vbox(rank_panel)
	var rank_title: = Label.new()
	rank_title.text = "当周排行榜"
	rank_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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

	var rules_btn_row: = CenterContainer.new()
	rules_btn_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(rules_btn_row)
	var rules_btn: = Button.new()
	rules_btn.name = "RulesBtn"
	rules_btn.text = "规则说明"
	rules_btn.custom_minimum_size = Vector2(160, 44)
	rules_btn.add_theme_font_size_override("font_size", 18)
	UIStyle.apply_button_style(rules_btn)
	rules_btn_row.add_child(rules_btn)

	root.set_meta("game_manager", game_manager)
	root.set_meta("arena_rules_cfg", {})
	mirror_btn.pressed.connect( func(): _on_mirror_pressed(game_manager, root))
	match_btn.pressed.connect( func(): _on_match_pressed(game_manager, root))
	history_btn.pressed.connect( func(): _on_history_pressed(game_manager, root))
	rank_more_btn.pressed.connect( func(): _on_rank_more_pressed(game_manager, root))
	rules_btn.pressed.connect( func(): _open_rules_window(root))
	_apply_status(root, {})
	return root


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


static func refresh_panel(game_manager, root: Control) -> void :
	if game_manager == null or root == null or not is_instance_valid(root):
		return
	if game_manager.has_method("refresh_arena_ui_panel"):
		game_manager.refresh_arena_ui_panel(root)


static func apply_status_to_root(root: Control, data: Dictionary) -> void :
	_apply_status(root, data)


static func _on_mirror_pressed(game_manager, root: Control) -> void :
	if game_manager == null or root == null:
		return
	if game_manager.has_method("open_arena_mirror_popup_from_ui"):
		game_manager.open_arena_mirror_popup_from_ui(root)


static func _on_match_pressed(game_manager, root: Control) -> void :
	if game_manager == null or root == null:
		return
	if bool(root.get_meta("arena_match_pending", false)):
		return
	_run_match_flow(game_manager, root)


static func _on_history_pressed(game_manager, root: Control) -> void :
	if game_manager == null or game_manager.network == null or root == null:
		return
	var parent: = root.get_parent()
	while parent != null and not (parent is Control):
		parent = parent.get_parent()
	if parent == null:
		parent = root
	var res: Dictionary = await game_manager.network.request_arena_challenge_history(20)
	if not _api_ok(res):
		_set_status_error(root, str(res.get("error", "加载挑战记录失败")))
		return
	var records: Array = res.get("records", []) if res.get("records") is Array else []
	BattleLogReport.show_arena_history_list_dialog(parent as Control, records)


static func _style_primary_action_button(btn: Button) -> void :
	UIStyle.apply_golden_button_style(btn)
	UIStyle.setup_button_animation(btn)


static func _run_match_flow(game_manager, root: Control) -> void :
	if game_manager == null or game_manager.network == null:
		return
	if game_manager.has_method("release_stale_arena_match_lock"):
		game_manager.release_stale_arena_match_lock()

	var block_msg: = ""
	if game_manager.has_method("get_instanced_challenge_block_message"):
		block_msg = str(game_manager.get_instanced_challenge_block_message("arena"))
	if block_msg.is_empty() and (bool(game_manager.get("is_shengsi_tower_replay")) or bool(game_manager.get("is_shengsi_replay_result_open"))):
		if game_manager.has_method("get_instanced_challenge_block_message"):
			block_msg = str(game_manager.get_instanced_challenge_block_message(""))
		if block_msg.is_empty():
			block_msg = "其他挑战正在进行中，请先完成或停止当前挑战后再试"
	if not block_msg.is_empty():
		_set_status_error(root, block_msg)
		return

	if bool(game_manager.get("is_arena_battle")):
		_set_status_error(root, "战斗结束后再匹配")
		return
	root.set_meta("arena_match_pending", true)
	_set_match_buttons(root, true, "匹配中...")
	var match_res: Dictionary = await game_manager.network.request_arena_match_start()
	if not _api_ok(match_res):
		root.set_meta("arena_match_pending", false)
		_set_match_buttons(root, false, "")
		_set_status_error(root, str(match_res.get("error", "匹配失败")))
		return
	var battle_token: = str(match_res.get("battleToken", match_res.get("battle_token", "")))
	var countdown: = int(match_res.get("countdownSeconds", match_res.get("countdown_seconds", 3)))
	await _show_match_overlay(root, match_res, maxi(1, countdown))
	var challenge_res: Dictionary = await game_manager.network.request_arena_challenge_start(battle_token)
	root.set_meta("arena_match_pending", false)
	_set_match_buttons(root, false, "")
	if not _api_ok(challenge_res):
		_set_status_error(root, str(challenge_res.get("error", "开战失败")))
		refresh_panel(game_manager, root)
		return
	refresh_panel(game_manager, root)
	var battle_data: = challenge_res.duplicate(true)
	battle_data["battleToken"] = battle_token
	battle_data["match"] = match_res
	if game_manager.has_method("start_arena_battle"):
		game_manager.start_arena_battle(battle_data)


static func _show_match_overlay(root: Control, match_res: Dictionary, countdown_sec: int) -> void :
	if root == null or not is_instance_valid(root):
		return
	var parent: = root.get_parent()
	while parent != null and not (parent is Control):
		parent = parent.get_parent()
	if parent == null:
		parent = root
	var overlay: = Control.new()
	overlay.name = "ArenaMatchOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 200
	var bg: = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.72)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(bg)
	var center: = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel: = PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 260)
	var panel_style: = UIStyle.create_panel_style()
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)
	var vbox: = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)
	var title: = Label.new()
	title.text = "匹配成功"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)
	var sides: = HBoxContainer.new()
	sides.alignment = BoxContainer.ALIGNMENT_CENTER
	sides.add_theme_constant_override("separation", 24)
	vbox.add_child(sides)
	var self_info: Dictionary = match_res.get("self", {}) if match_res.get("self") is Dictionary else {}
	var opp_info: Dictionary = match_res.get("opponent", {}) if match_res.get("opponent") is Dictionary else {}
	sides.add_child(_create_match_side(self_info, "我方"))
	var vs: = Label.new()
	vs.text = "VS"
	vs.add_theme_font_size_override("font_size", 24)
	vs.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	sides.add_child(vs)
	sides.add_child(_create_match_side(opp_info, "对手"))
	var countdown_label: = Label.new()
	countdown_label.name = "CountdownLabel"
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.add_theme_font_size_override("font_size", 28)
	countdown_label.add_theme_color_override("font_color", Color(0.4, 0.95, 0.55))
	vbox.add_child(countdown_label)
	if parent is Control:
		(parent as Control).add_child(overlay)
	for sec in range(countdown_sec, 0, -1):
		countdown_label.text = "%d" % sec
		await overlay.get_tree().create_timer(1.0).timeout
	if is_instance_valid(overlay):
		overlay.queue_free()


static func _create_match_side(info: Dictionary, prefix: String) -> VBoxContainer:
	var col: = VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 6)
	var cid: = int(info.get("characterId", info.get("character_id", 0)))
	col.add_child(_create_character_avatar(cid, Vector2(80, 80)))
	var name: = str(info.get("playerName", info.get("player_name", prefix))).strip_edges()
	if name.is_empty():
		name = prefix
	var name_l: = Label.new()
	name_l.text = name
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.add_theme_font_size_override("font_size", 14)
	col.add_child(name_l)
	var pts: = int(info.get("weeklyArenaPoints", info.get("weekly_arena_points", 0)))
	var pts_l: = Label.new()
	pts_l.text = "当周 %d 分" % pts
	pts_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pts_l.add_theme_font_size_override("font_size", 13)
	pts_l.add_theme_color_override("font_color", Color(0.842, 0.816, 0.756))
	col.add_child(pts_l)
	return col


static func _create_character_avatar(character_id: int, size: Vector2) -> Control:
	var frame: = Panel.new()
	frame.custom_minimum_size = size
	frame.clip_contents = true
	var style: = UIStyle.create_item_style()
	frame.add_theme_stylebox_override("panel", style)
	var tex: = _load_rank_avatar_texture(character_id)
	var avatar: = TextureRect.new()
	avatar.set_anchors_preset(Control.PRESET_FULL_RECT)
	avatar.offset_left = 4
	avatar.offset_top = 4
	avatar.offset_right = -4
	avatar.offset_bottom = -4
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar.texture = tex
	frame.add_child(avatar)
	return frame


static func _on_rank_more_pressed(game_manager, root: Control) -> void :
	if game_manager == null or game_manager.network == null:
		return
	var res: Dictionary = await game_manager.network.request_arena_ranking(RANK_POPUP_LIMIT)
	var ranking: Array = res.get("ranking", []) if res.get("ranking") is Array else []
	var parent: = root.get_parent()
	while parent != null and not (parent is Control):
		parent = parent.get_parent()
	if parent == null:
		parent = root
	_show_ranking_popup(parent as Control, ranking)


static func _show_ranking_popup(parent: Control, ranking: Array) -> void :
	if parent == null or not is_instance_valid(parent):
		return
	var popup: = Window.new()
	popup.title = ""
	popup.size = Vector2i(520, 640)
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
	title.text = "竞技场排行榜（前%d名）" % RANK_POPUP_LIMIT
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
	_populate_ranking_popup(rank_list, ranking, RANK_POPUP_LIMIT)
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


static func _open_rules_window(parent: Control) -> void :
	if parent == null or not is_instance_valid(parent):
		return
	var cfg: Dictionary = {}
	var cached: Variant = parent.get_meta("arena_rules_cfg", {})
	if cached is Dictionary:
		cfg = cached
	var rules_text: = ArenaConfig.build_rules_text(cfg)

	var popup: = Window.new()
	popup.title = ""
	popup.size = Vector2i(520, 640)
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
	title.text = "规则说明"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(title)

	var scroll: = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.scroll_deadzone = 20
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(scroll)

	var body: = Label.new()
	body.text = rules_text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("font_size", 16)
	body.add_theme_color_override("font_color", Color(0.894, 0.864, 0.803))
	scroll.add_child(body)

	var close_row: = CenterContainer.new()
	vbox.add_child(close_row)
	var close_btn: = Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(120, 42)
	close_btn.add_theme_font_size_override("font_size", 18)
	UIStyle.apply_button_style(close_btn)
	close_btn.pressed.connect( func():
		if is_instance_valid(popup):
			popup.queue_free()
	)
	close_row.add_child(close_btn)

	WindowHost.attach_window_and_popup_centered(popup, parent)


static func _apply_status(root: Control, data: Dictionary) -> void :
	var cfg: Dictionary = ArenaConfig.merge_player_config(data)
	if root != null:
		root.set_meta("arena_rules_cfg", cfg)
	var activity_label: Label = _find_node(root, "ActivityLabel") as Label
	var status_label: Label = _find_node(root, "StatusLabel") as Label
	var weekly_l: Label = _find_node(root, "WeeklyPointsValue") as Label
	var balance_l: Label = _find_node(root, "BalancePointsValue") as Label
	var rank_l: Label = _find_node(root, "RankStatValue") as Label
	var attempts_l: Label = _find_node(root, "AttemptsStatValue") as Label
	var mirror_btn: Button = _find_node(root, "MirrorBtn") as Button
	var match_btn: Button = _find_node(root, "MatchBtn") as Button
	var top3_row: HBoxContainer = _find_node(root, "Top3Row") as HBoxContainer
	var rank_list: VBoxContainer = _find_node(root, "RankList") as VBoxContainer

	var api_ok: = _api_ok(data)
	var weekly: = int(data.get("weeklyArenaPoints", data.get("weekly_arena_points", 0)))
	var balance: = ArenaConfig.resolve_balance_points(data)
	var my_rank: = int(data.get("myRank", data.get("my_rank", 0)))
	var remaining: = int(data.get("remainingAttempts", data.get("remaining_attempts", -1)))
	if remaining < 0:
		remaining = int(cfg.get("dailyMaxAttempts", ArenaConfig.FALLBACK_DAILY_MAX_ATTEMPTS))
	var in_window: = bool(data.get("inChallengeWindow", data.get("in_challenge_window", ArenaConfig.is_in_challenge_window(cfg)))) if api_ok else ArenaConfig.is_in_challenge_window(cfg)
	var feature_on: = bool(data.get("featureEnabled", data.get("feature_enabled", cfg.get("featureEnabled", false)))) if api_ok else false
	var has_mirror: = bool(data.get("hasMirror", data.get("has_mirror", false))) if api_ok else false

	if weekly_l != null:
		weekly_l.text = str(weekly)
	if balance_l != null:
		balance_l.text = str(balance)
	if rank_l != null:
		rank_l.text = "100+" if my_rank <= 0 or my_rank > 100 else str(my_rank)
	if attempts_l != null:
		attempts_l.text = str(remaining)

	var start_h: = int(cfg.get("challengeStartHour", ArenaConfig.FALLBACK_CHALLENGE_START_HOUR))
	var start_m: = int(cfg.get("challengeStartMinute", ArenaConfig.FALLBACK_CHALLENGE_START_MINUTE))
	var end_h: = int(cfg.get("challengeEndHour", ArenaConfig.FALLBACK_CHALLENGE_END_HOUR))
	var end_m: = int(cfg.get("challengeEndMinute", ArenaConfig.FALLBACK_CHALLENGE_END_MINUTE))
	if activity_label != null:
		if in_window and feature_on:
			activity_label.text = "今日 %02d:%02d–%02d:%02d 开放中" % [start_h, start_m, end_h, end_m]
			activity_label.add_theme_color_override("font_color", Color(0.35, 0.9, 0.55))
		elif not feature_on:
			activity_label.text = "竞技场暂未开放"
			activity_label.add_theme_color_override("font_color", Color(0.631, 0.611, 0.564))
		else:
			activity_label.text = "当前不在活动时间"
			activity_label.add_theme_color_override("font_color", Color(0.631, 0.611, 0.564))

	if status_label != null:
		status_label.text = ""
		if not api_ok:
			var err: = str(data.get("error", "")).strip_edges()
			if not err.is_empty():
				status_label.text = "同步失败：%s" % err
		elif not has_mirror:
			status_label.text = "请先更新镜像后再匹配"
		elif in_window and feature_on:
			status_label.text = "已同步，可匹配挑战"

	if mirror_btn != null:
		mirror_btn.disabled = not feature_on
		mirror_btn.text = "更新/查看镜像"
	if match_btn != null and not bool(root.get_meta("arena_match_pending", false)):
		match_btn.disabled = not feature_on or not in_window or remaining <= 0 or not has_mirror
		if not feature_on:
			match_btn.text = "暂未开放"
		elif not in_window:
			match_btn.text = "不在活动时间内"
		elif remaining <= 0:
			match_btn.text = "今日次数已用完"
		elif not has_mirror:
			match_btn.text = "请先更新镜像"
		else:
			match_btn.text = "开始匹配"

	var top3: Array = data.get("top3", []) if data.get("top3") is Array else []
	if top3.is_empty() and data.get("ranking") is Array:
		var all_rank: Array = data.get("ranking")
		for i in range(mini(3, all_rank.size())):
			top3.append(all_rank[i])
	_refresh_top3(top3_row, top3)

	var ranking: Array = data.get("ranking", []) if data.get("ranking") is Array else []
	_refresh_rank_preview(rank_list, ranking)
	_reapply_main_scroll_passthrough(root)


static func _reapply_main_scroll_passthrough(root: Control) -> void :
	var main_vbox: = _find_node(root, "MainVBox") as Control
	if main_vbox != null:
		_enable_touch_drag_passthrough(main_vbox)


static func _refresh_top3(row: HBoxContainer, top3: Array) -> void :
	if row == null:
		return
	for child in row.get_children():
		child.queue_free()
	if top3.is_empty():
		var empty: = Label.new()
		empty.text = "暂无上榜玩家"
		empty.add_theme_color_override("font_color", Color(0.669, 0.649, 0.598))
		row.add_child(empty)
		return
	var by_rank: Dictionary = {}
	for entry in top3:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var rank_no: = int(entry.get("rank", 0))
		if rank_no >= 1 and rank_no <= 3 and not by_rank.has(rank_no):
			by_rank[rank_no] = entry
	for slot in [2, 1, 3]:
		if by_rank.has(slot):
			row.add_child(_create_top3_cell(by_rank[slot]))
		else:
			row.add_child(_create_top3_empty_slot())


static func _create_top3_empty_slot() -> Control:
	var spacer: = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.size_flags_vertical = Control.SIZE_SHRINK_END
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spacer


static func _top3_badge_path(rank_no: int) -> String:
	match rank_no:
		1:
			return WB_BADGE_GOLD_PATH
		2:
			return WB_BADGE_SILVER_PATH
		3:
			return WB_BADGE_BRONZE_PATH
		_:
			return ""


static func _make_top3_badge(rank_no: int, is_first: bool) -> TextureRect:
	var path: = _top3_badge_path(rank_no)
	var tex: = _load_ui_tex(path)
	if tex == null:
		return null
	var side: = TOP3_BADGE_FIRST if is_first else TOP3_BADGE_OTHER
	var tr: = TextureRect.new()
	tr.texture = tex
	tr.custom_minimum_size = Vector2(side, side)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return tr


static func _create_top3_cell(entry: Dictionary) -> VBoxContainer:
	var col: = VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_END
	col.add_theme_constant_override("separation", 4)
	var rank_no: = int(entry.get("rank", 0))
	var is_first: = rank_no == 1
	var head: = HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_theme_constant_override("separation", 4)
	var badge: = _make_top3_badge(rank_no, is_first)
	if badge != null:
		head.add_child(badge)
	var rank_l: = Label.new()
	rank_l.text = "第%d名" % rank_no
	rank_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	match rank_no:
		1:
			rank_l.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
		2:
			rank_l.add_theme_color_override("font_color", Color(0.822, 0.797, 0.737))
		3:
			rank_l.add_theme_color_override("font_color", Color(0.82, 0.58, 0.32))
		_:
			rank_l.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	head.add_child(rank_l)
	col.add_child(head)
	var cid: = int(entry.get("characterId", entry.get("character_id", 0)))
	var av_side: = TOP3_AVATAR_FIRST if is_first else TOP3_AVATAR_OTHER
	var avatar: = _create_character_avatar(cid, Vector2(av_side, av_side))
	avatar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_child(avatar)
	var name: = str(entry.get("playerName", entry.get("player_name", "未知")))
	var name_l: = Label.new()
	name_l.text = name
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_l.clip_text = true
	name_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_l.add_theme_font_size_override("font_size", 14)
	col.add_child(name_l)
	var pts: = int(entry.get("weeklyArenaPoints", entry.get("weekly_arena_points", 0)))
	var pts_l: = Label.new()
	pts_l.text = "%d 分" % pts
	pts_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pts_l.add_theme_font_size_override("font_size", 13)
	pts_l.add_theme_color_override("font_color", Color(0.791, 0.769, 0.708))
	col.add_child(pts_l)
	return col


static func _refresh_rank_preview(rank_list: VBoxContainer, ranking: Array) -> void :
	if rank_list == null:
		return
	for child in rank_list.get_children():
		child.queue_free()
	if ranking.is_empty():
		var empty: = Label.new()
		empty.text = "暂无排名"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rank_list.add_child(empty)
		return
	var shown: = 0
	for entry in ranking:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		if shown >= RANK_PREVIEW_LIMIT:
			break
		var rank_no: = int(entry.get("rank", shown + 1))
		var player_name: = str(entry.get("playerName", entry.get("player_name", "未知")))
		var pts: = int(entry.get("weeklyArenaPoints", entry.get("weekly_arena_points", 0)))
		var cid: = int(entry.get("characterId", entry.get("character_id", 0)))
		_add_ranking_table_row(rank_list, str(rank_no), player_name, str(pts), false, shown % 2 == 0, cid)
		shown += 1


static func _populate_ranking_popup(rank_list: VBoxContainer, ranking: Array, limit: int) -> void :
	if rank_list == null:
		return
	var shown: = 0
	for entry in ranking:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		if shown >= limit:
			break
		var rank_no: = int(entry.get("rank", shown + 1))
		var player_name: = str(entry.get("playerName", entry.get("player_name", "未知")))
		var pts: = int(entry.get("weeklyArenaPoints", entry.get("weekly_arena_points", 0)))
		var cid: = int(entry.get("characterId", entry.get("character_id", 0)))
		_add_ranking_table_row(rank_list, str(rank_no), player_name, str(pts), false, shown % 2 == 0, cid)
		shown += 1


static func show_mirror_popup(game_manager, root: Control, data: Dictionary) -> Window:
	if root == null or not is_instance_valid(root):
		return null
	var parent: = root.get_parent()
	while parent != null and not (parent is Control):
		parent = parent.get_parent()
	if parent == null:
		parent = root
	var existing: Variant = root.get_meta("arena_mirror_popup", null)
	if existing is Window and is_instance_valid(existing):
		existing.queue_free()
	var popup: = Window.new()
	popup.title = ""
	popup.size = MIRROR_POPUP_SIZE
	popup.transparent = true
	popup.borderless = true
	popup.unresizable = true
	popup.always_on_top = true
	popup.exclusive = true
	popup.close_requested.connect( func():
		if is_instance_valid(popup):
			popup.queue_free()
	)
	var main_panel: = Panel.new()
	main_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_panel.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	popup.add_child(main_panel)
	var outer: = MarginContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 18)
	outer.add_theme_constant_override("margin_right", 18)
	outer.add_theme_constant_override("margin_top", 16)
	outer.add_theme_constant_override("margin_bottom", 16)
	main_panel.add_child(outer)
	var vbox: = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	outer.add_child(vbox)
	var title: = Label.new()
	var title_text: = str(data.get("mirrorTitle", data.get("mirror_title", "当前竞技场镜像")))
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(title)
	var scroll: = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.scroll_deadzone = 16
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	vbox.add_child(scroll)
	var content_vbox: = VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	content_vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(content_vbox)
	var hint_lbl: = Label.new()
	hint_lbl.name = "MirrorEmptyHint"
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_lbl.add_theme_font_size_override("font_size", 13)
	hint_lbl.add_theme_color_override("font_color", Color(1.0, 0.72, 0.45))
	content_vbox.add_child(hint_lbl)
	var player_panel: = _create_section_panel()
	player_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(player_panel)
	var player_inner: = _panel_inner_vbox(player_panel)
	player_inner.add_theme_constant_override("separation", 8)
	var player_title: = Label.new()
	player_title.text = "角色信息"
	player_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_title.add_theme_font_size_override("font_size", 14)
	player_title.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
	player_inner.add_child(player_title)
	var player_body: = HBoxContainer.new()
	player_body.alignment = BoxContainer.ALIGNMENT_BEGIN
	player_body.add_theme_constant_override("separation", 10)
	player_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_inner.add_child(player_body)
	player_body.add_child(_create_mirror_portrait_slot("MirrorPlayerPortrait"))
	var player_fields: = VBoxContainer.new()
	player_fields.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_fields.add_theme_constant_override("separation", 4)
	player_body.add_child(player_fields)
	player_fields.add_child(_create_mirror_kv_row("名称", "MirrorPlayerName"))
	player_fields.add_child(_create_mirror_kv_row("等级", "MirrorPlayerLevel"))
	player_fields.add_child(_create_mirror_kv_row("境界", "MirrorPlayerRealm"))
	player_fields.add_child(_create_mirror_kv_row("投胎", "MirrorPlayerReincarnation"))
	var pet_panel: = _create_section_panel()
	pet_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(pet_panel)
	var pet_inner: = _panel_inner_vbox(pet_panel)
	pet_inner.add_theme_constant_override("separation", 8)
	var pet_title: = Label.new()
	pet_title.text = "出战宠物"
	pet_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pet_title.add_theme_font_size_override("font_size", 14)
	pet_title.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
	pet_inner.add_child(pet_title)
	var pet_body: = HBoxContainer.new()
	pet_body.alignment = BoxContainer.ALIGNMENT_BEGIN
	pet_body.add_theme_constant_override("separation", 10)
	pet_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pet_inner.add_child(pet_body)
	pet_body.add_child(_create_mirror_portrait_slot("MirrorPetPortrait"))
	var pet_fields: = VBoxContainer.new()
	pet_fields.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pet_fields.add_theme_constant_override("separation", 4)
	pet_body.add_child(pet_fields)
	pet_fields.add_child(_create_mirror_kv_row("名称", "MirrorPetName"))
	pet_fields.add_child(_create_mirror_kv_row("等级", "MirrorPetLevel"))
	var updated_lbl: = Label.new()
	updated_lbl.name = "MirrorUpdatedAt"
	updated_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	updated_lbl.add_theme_font_size_override("font_size", 13)
	updated_lbl.add_theme_color_override("font_color", Color(0.682, 0.662, 0.610))
	content_vbox.add_child(updated_lbl)
	var err_lbl: = Label.new()
	err_lbl.name = "MirrorPopupErrorLabel"
	err_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	err_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	err_lbl.add_theme_font_size_override("font_size", 13)
	err_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	err_lbl.visible = false
	content_vbox.add_child(err_lbl)
	_enable_touch_drag_passthrough(content_vbox)
	var btn_row: = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 14)
	vbox.add_child(btn_row)
	var update_btn: = Button.new()
	update_btn.name = "MirrorPopupUpdateBtn"
	update_btn.text = "更新镜像"
	update_btn.custom_minimum_size = Vector2(148, 44)
	_style_primary_action_button(update_btn)
	btn_row.add_child(update_btn)
	var close_btn: = Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(120, 44)
	UIStyle.apply_button_style(close_btn)
	btn_row.add_child(close_btn)
	popup.set_meta("arena_root", root)
	popup.set_meta("mirror_mode", str(data.get("mirrorMode", data.get("mirror_mode", "arena"))))
	root.set_meta("arena_mirror_popup", popup)
	popup.tree_exited.connect( func():
		if is_instance_valid(root) and root.has_meta("arena_mirror_popup"):
			root.remove_meta("arena_mirror_popup")
	)
	close_btn.pressed.connect( func():
		if is_instance_valid(popup):
			popup.queue_free()
	)
	update_btn.pressed.connect( func():
		if game_manager == null:
			return
		var mirror_mode: = str(data.get("mirrorMode", data.get("mirror_mode", "arena")))
		if mirror_mode == "shengsi":
			if game_manager.has_method("is_shengsi_mirror_on_cooldown") and game_manager.is_shengsi_mirror_on_cooldown():
				var cd_msg: = "更新冷却中"
				if game_manager.has_method("get_shengsi_mirror_cooldown_label"):
					cd_msg = "更新冷却中，请 %s 后再试" % str(game_manager.get_shengsi_mirror_cooldown_label())
				_set_mirror_popup_error(popup, cd_msg)
				return
			_set_mirror_popup_error(popup, "")
			if game_manager.has_method("request_shengsi_mirror_update_from_ui"):
				game_manager.request_shengsi_mirror_update_from_ui(root)
			return
		if mirror_mode == "brother_tower":
			if game_manager.has_method("is_brother_tower_mirror_on_cooldown") and game_manager.is_brother_tower_mirror_on_cooldown():
				var bt_cd_msg: = "更新冷却中"
				if game_manager.has_method("get_brother_tower_mirror_cooldown_label"):
					bt_cd_msg = "更新冷却中，请 %s 后再试" % str(game_manager.get_brother_tower_mirror_cooldown_label())
				_set_mirror_popup_error(popup, bt_cd_msg)
				return
			_set_mirror_popup_error(popup, "")
			if game_manager.has_method("request_brother_tower_mirror_update_from_ui"):
				game_manager.request_brother_tower_mirror_update_from_ui(root)
			return
		if game_manager.has_method("is_mirror_update_on_cooldown") and game_manager.is_mirror_update_on_cooldown():
			var cd_msg: = "更新冷却中"
			if game_manager.has_method("get_mirror_update_cooldown_label"):
				cd_msg = "更新冷却中，请 %s 后再试" % str(game_manager.get_mirror_update_cooldown_label())
			_set_mirror_popup_error(popup, cd_msg)
			return
		_set_mirror_popup_error(popup, "")
		if mirror_mode == "gang" and game_manager.has_method("request_gang_mirror_update_from_ui"):
			game_manager.request_gang_mirror_update_from_ui(root)
		elif mirror_mode == "treasure" and game_manager.has_method("request_treasure_mirror_update_from_ui"):
			game_manager.request_treasure_mirror_update_from_ui(root)
		elif game_manager.has_method("request_arena_mirror_update_from_ui"):
			game_manager.request_arena_mirror_update_from_ui(root)
	)
	_apply_mirror_popup_content(popup, data)
	popup.set_meta("mirror_game_manager", game_manager)
	refresh_mirror_update_cooldown_ui(root, game_manager)
	_ensure_mirror_cooldown_timer(popup, root, game_manager)
	WindowHost.attach_window_and_popup_centered(popup, parent as Control)
	return popup


static func _create_mirror_portrait_slot(frame_name: String) -> Panel:
	var frame: = Panel.new()
	frame.name = frame_name
	frame.custom_minimum_size = MIRROR_PORTRAIT_SIZE
	frame.clip_contents = true
	var style: = UIStyle.create_item_style()
	frame.add_theme_stylebox_override("panel", style)
	var holder: = Control.new()
	holder.name = "PortraitHolder"
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.add_child(holder)
	return frame


static func _resolve_mirror_pet_id(data: Dictionary) -> String:
	var pet_id: = str(data.get("petId", data.get("pet_id", ""))).strip_edges()
	if not pet_id.is_empty():
		return pet_id
	var pet_name: = str(data.get("petName", "")).strip_edges()
	if pet_name.is_empty():
		return ""
	for key in GameData.PET_DATA:
		var info: Dictionary = GameData.PET_DATA[key]
		if str(info.get("name", "")) == pet_name:
			return str(key)
	return ""


static func _refresh_mirror_portrait_frame(popup: Window, frame_name: String, character_id: int, pet_id: String) -> void :
	var frame: Panel = popup.find_child(frame_name, true, false) as Panel
	if frame == null:
		return
	var holder: Control = frame.find_child("PortraitHolder", true, false) as Control
	if holder == null:
		return
	for child in holder.get_children():
		child.queue_free()
	var inner_size: = MIRROR_PORTRAIT_SIZE
	if not pet_id.is_empty():
		var pet_widget: = PetIdleDisplay.create_avatar_widget(pet_id, inner_size)
		if pet_widget != null:
			pet_widget.set_anchors_preset(Control.PRESET_FULL_RECT)
			pet_widget.custom_minimum_size = inner_size
			holder.add_child(pet_widget)
			return
	if character_id >= 0:
		var tex: = _load_rank_avatar_texture(character_id)
		if tex != null:
			var avatar: = TextureRect.new()
			avatar.set_anchors_preset(Control.PRESET_FULL_RECT)
			avatar.custom_minimum_size = inner_size
			avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			avatar.texture = tex
			avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			holder.add_child(avatar)


static func _create_mirror_kv_row(label_text: String, value_node_name: String) -> HBoxContainer:
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var key_lbl: = Label.new()
	key_lbl.text = label_text
	key_lbl.custom_minimum_size = Vector2(52, 0)
	key_lbl.add_theme_font_size_override("font_size", 13)
	key_lbl.add_theme_color_override("font_color", Color(0.734, 0.714, 0.657))
	row.add_child(key_lbl)
	var val_lbl: = Label.new()
	val_lbl.name = value_node_name
	val_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	val_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	val_lbl.add_theme_font_size_override("font_size", 14)
	val_lbl.add_theme_color_override("font_color", Color(0.924, 0.893, 0.831))
	row.add_child(val_lbl)
	return row


static func _set_mirror_popup_label(popup: Window, node_name: String, text: String, visible: bool = true) -> void :
	var lbl: Label = popup.find_child(node_name, true, false) as Label
	if lbl == null:
		return
	lbl.text = text
	lbl.visible = visible


static func _format_mirror_updated_at(data: Dictionary) -> String:
	if not BattleSnapshotDisplay.has_summary(data, "hasMirror"):
		return ""
	var time_raw: = str(data.get("updatedAt", data.get("pinnedAt", ""))).strip_edges()
	if time_raw.is_empty():
		return "更新时间：未知"
	var date_part: = time_raw.substr(0, 10) if time_raw.length() >= 10 else time_raw
	var time_part: = ""
	if time_raw.length() >= 16:
		time_part = time_raw.substr(11, 5)
	if time_part.is_empty():
		return "更新时间：%s" % date_part
	return "更新时间：%s %s" % [date_part, time_part]


static func refresh_mirror_popup(root: Control, data: Dictionary) -> void :
	var popup: Variant = root.get_meta("arena_mirror_popup", null) if root != null else null
	if popup is Window and is_instance_valid(popup):
		_apply_mirror_popup_content(popup, data)


static func _apply_mirror_popup_content(popup: Window, data: Dictionary) -> void :
	if popup == null or not is_instance_valid(popup):
		return
	var has_mirror: = BattleSnapshotDisplay.has_summary(data, "hasMirror")
	var hint_lbl: Label = popup.find_child("MirrorEmptyHint", true, false) as Label
	if hint_lbl != null:
		hint_lbl.text = "" if has_mirror else "尚未更新镜像，请点击下方「更新镜像」同步当前角色与出战宠"
		hint_lbl.visible = not has_mirror
	if has_mirror:
		var player_name: = str(data.get("playerName", "玩家"))
		var player_level: = int(data.get("playerLevel", 1))
		var player_realm: = str(data.get("playerRealm", "—"))
		var reincarnation: = int(data.get("playerReincarnation", 0))
		var pet_name: = str(data.get("petName", ""))
		var pet_level: = int(data.get("petLevel", 0))
		var character_id: = int(data.get("characterId", data.get("character_id", 0)))
		var pet_id: = _resolve_mirror_pet_id(data)
		_refresh_mirror_portrait_frame(popup, "MirrorPlayerPortrait", character_id, "")
		_refresh_mirror_portrait_frame(popup, "MirrorPetPortrait", -1, pet_id)
		_set_mirror_popup_label(popup, "MirrorPlayerName", player_name)
		_set_mirror_popup_label(popup, "MirrorPlayerLevel", "Lv.%d" % maxi(1, player_level))
		_set_mirror_popup_label(popup, "MirrorPlayerRealm", player_realm if not player_realm.is_empty() else "—")
		_set_mirror_popup_label(
			popup, 
			"MirrorPlayerReincarnation", 
			str(reincarnation), 
			reincarnation > 0
		)
		if pet_name.is_empty():
			_set_mirror_popup_label(popup, "MirrorPetName", "暂无出战宠物")
			_set_mirror_popup_label(popup, "MirrorPetLevel", "—", false)
		else:
			_set_mirror_popup_label(popup, "MirrorPetName", pet_name)
			_set_mirror_popup_label(popup, "MirrorPetLevel", "Lv.%d" % maxi(1, pet_level), true)
	else:
		_refresh_mirror_portrait_frame(popup, "MirrorPlayerPortrait", 0, "")
		_refresh_mirror_portrait_frame(popup, "MirrorPetPortrait", -1, "")
		for node_name in [
			"MirrorPlayerName", "MirrorPlayerLevel", "MirrorPlayerRealm", 
			"MirrorPlayerReincarnation", "MirrorPetName", "MirrorPetLevel"
		]:
			_set_mirror_popup_label(popup, node_name, "—", node_name != "MirrorPlayerReincarnation")
		_set_mirror_popup_label(popup, "MirrorPlayerReincarnation", "—", false)
	var updated_lbl: Label = popup.find_child("MirrorUpdatedAt", true, false) as Label
	if updated_lbl != null:
		var updated_text: = _format_mirror_updated_at(data)
		updated_lbl.text = updated_text
		updated_lbl.visible = not updated_text.is_empty()


static func refresh_mirror_update_cooldown_ui(root: Control, game_manager) -> void :
	if root == null or game_manager == null:
		return
	var popup: Variant = root.get_meta("arena_mirror_popup", null)
	if not (popup is Window) or not is_instance_valid(popup):
		return
	if bool(popup.get_meta("mirror_update_pending", false)):
		return
	var update_btn: Button = popup.find_child("MirrorPopupUpdateBtn", true, false) as Button
	if update_btn == null:
		return
	var mode: = str(popup.get_meta("mirror_mode", ""))
	if mode == "shengsi":
		if game_manager.has_method("is_shengsi_mirror_on_cooldown") and game_manager.is_shengsi_mirror_on_cooldown():
			update_btn.disabled = true
			var label: = ""
			if game_manager.has_method("get_shengsi_mirror_cooldown_label"):
				label = str(game_manager.get_shengsi_mirror_cooldown_label())
			update_btn.text = "更新镜像(%s)" % label if not label.is_empty() else "更新镜像(冷却)"
		else:
			update_btn.disabled = false
			update_btn.text = "更新镜像"
		return
	if mode == "brother_tower":
		if game_manager.has_method("is_brother_tower_mirror_on_cooldown") and game_manager.is_brother_tower_mirror_on_cooldown():
			update_btn.disabled = true
			var bt_label: = ""
			if game_manager.has_method("get_brother_tower_mirror_cooldown_label"):
				bt_label = str(game_manager.get_brother_tower_mirror_cooldown_label())
			update_btn.text = "更新镜像(%s)" % bt_label if not bt_label.is_empty() else "更新镜像(冷却)"
		else:
			update_btn.disabled = false
			update_btn.text = "更新镜像"
		return
	if game_manager.has_method("is_mirror_update_on_cooldown") and game_manager.is_mirror_update_on_cooldown():
		update_btn.disabled = true
		var label: = ""
		if game_manager.has_method("get_mirror_update_cooldown_label"):
			label = str(game_manager.get_mirror_update_cooldown_label())
		update_btn.text = "更新镜像(%s)" % label if not label.is_empty() else "更新镜像(冷却)"
	else:
		update_btn.disabled = false
		update_btn.text = "更新镜像"


static func _mirror_popup_on_cooldown(popup: Window, game_manager) -> bool:
	var mode: = str(popup.get_meta("mirror_mode", ""))
	if mode == "shengsi":
		return game_manager.has_method("is_shengsi_mirror_on_cooldown") and game_manager.is_shengsi_mirror_on_cooldown()
	if mode == "brother_tower":
		return game_manager.has_method("is_brother_tower_mirror_on_cooldown") and game_manager.is_brother_tower_mirror_on_cooldown()
	return game_manager.has_method("is_mirror_update_on_cooldown") and game_manager.is_mirror_update_on_cooldown()


static func _ensure_mirror_cooldown_timer(popup: Window, root: Control, game_manager) -> void :
	if popup == null or not is_instance_valid(popup) or game_manager == null:
		return
	var existing: Variant = popup.get_meta("mirror_cooldown_timer", null)
	if existing is Timer and is_instance_valid(existing):
		if _mirror_popup_on_cooldown(popup, game_manager):
			existing.start()
		return
	var timer: = Timer.new()
	timer.name = "MirrorCooldownTimer"
	timer.wait_time = 1.0
	timer.autostart = false
	popup.add_child(timer)
	popup.set_meta("mirror_cooldown_timer", timer)
	timer.timeout.connect( func() -> void :
		if not is_instance_valid(popup) or not is_instance_valid(root):
			timer.stop()
			return
		refresh_mirror_update_cooldown_ui(root, game_manager)
		var mode: = str(popup.get_meta("mirror_mode", ""))
		var still_cd: = false
		if mode == "shengsi":
			still_cd = game_manager.has_method("is_shengsi_mirror_on_cooldown") and game_manager.is_shengsi_mirror_on_cooldown()
		elif mode == "brother_tower":
			still_cd = game_manager.has_method("is_brother_tower_mirror_on_cooldown") and game_manager.is_brother_tower_mirror_on_cooldown()
		else:
			still_cd = game_manager.has_method("is_mirror_update_on_cooldown") and game_manager.is_mirror_update_on_cooldown()
		if not still_cd:
			timer.stop()
	)
	popup.tree_exited.connect( func() -> void :
		if is_instance_valid(timer):
			timer.queue_free()
	)
	var start_cd: = _mirror_popup_on_cooldown(popup, game_manager)
	if start_cd:
		timer.start()


static func set_mirror_popup_pending(root: Control, pending: bool) -> void :
	if root == null:
		return
	var popup: Variant = root.get_meta("arena_mirror_popup", null)
	if not (popup is Window) or not is_instance_valid(popup):
		return
	popup.set_meta("mirror_update_pending", pending)
	var update_btn: Button = popup.find_child("MirrorPopupUpdateBtn", true, false) as Button
	if update_btn == null:
		return
	if pending:
		update_btn.disabled = true
		update_btn.text = "更新中..."
	else:
		var game_manager = popup.get_meta("mirror_game_manager", null)
		if game_manager != null:
			refresh_mirror_update_cooldown_ui(root, game_manager)
		else:
			update_btn.disabled = false
			update_btn.text = "更新镜像"


static func _set_mirror_popup_error(popup: Window, err: String) -> void :
	if popup == null or not is_instance_valid(popup):
		return
	var err_lbl: Label = popup.find_child("MirrorPopupErrorLabel", true, false) as Label
	if err_lbl == null:
		return
	err_lbl.text = err
	err_lbl.visible = not err.is_empty()


static func _set_mirror_pending(root: Control, pending: bool) -> void :
	set_mirror_popup_pending(root, pending)


static func _set_match_buttons(root: Control, pending: bool, text: String) -> void :
	if root == null:
		return
	var btn: Button = _find_node(root, "MatchBtn") as Button
	if btn == null:
		return
	btn.disabled = pending
	if not text.is_empty():
		btn.text = text


static func _set_status_error(root: Control, err: String) -> void :
	var status_label: Label = _find_node(root, "StatusLabel") as Label
	if status_label != null and not err.is_empty():
		status_label.text = err


static func set_mirror_result(root: Control, success: bool, err: String = "", preview: Dictionary = {}) -> void :
	set_mirror_popup_pending(root, false)
	var popup: Variant = root.get_meta("arena_mirror_popup", null) if root != null else null
	var game_manager = popup.get_meta("mirror_game_manager", null) if popup is Window else null
	if success:
		if not preview.is_empty():
			refresh_mirror_popup(root, preview)
		if popup is Window and is_instance_valid(popup):
			_set_mirror_popup_error(popup, "")
			if popup.has_method("move_to_foreground"):
				popup.move_to_foreground()
			popup.grab_focus()
		if game_manager != null:
			refresh_mirror_update_cooldown_ui(root, game_manager)
			if popup is Window and is_instance_valid(popup):
				_ensure_mirror_cooldown_timer(popup, root, game_manager)
		return
	var msg: = err if not err.is_empty() else "更新镜像失败"
	if popup is Window and is_instance_valid(popup):
		_set_mirror_popup_error(popup, msg)
		if game_manager != null:
			refresh_mirror_update_cooldown_ui(root, game_manager)
	else:
		_set_status_error(root, msg)


static func _api_ok(data: Dictionary) -> bool:
	return bool(data.get("ok", false)) or bool(data.get("success", false))


static func _find_node(root: Control, node_name: String) -> Node:
	if root == null:
		return null
	return root.find_child(node_name, true, false)


static func _create_stat_card(title_text: String, value_text: String, value_node_name: String) -> PanelContainer:
	var card: = PanelContainer.new()
	var card_style: = UIStyle.create_item_style()
	card_style.content_margin_left = 8
	card_style.content_margin_right = 8
	card_style.content_margin_top = 6
	card_style.content_margin_bottom = 6
	card.add_theme_stylebox_override("panel", card_style)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var vbox: = VBoxContainer.new()
	card.add_child(vbox)
	var title_label: = Label.new()
	title_label.text = title_text
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color(0.708, 0.688, 0.633))
	vbox.add_child(title_label)
	var value_label: = Label.new()
	value_label.name = value_node_name
	value_label.text = value_text
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(value_label)
	return card


static func _create_section_panel() -> PanelContainer:
	var panel: = PanelContainer.new()
	var style: = UIStyle.create_item_style()
	style.content_margin_left = PANEL_INNER_MARGIN
	style.content_margin_right = PANEL_INNER_MARGIN
	style.content_margin_top = PANEL_INNER_MARGIN
	style.content_margin_bottom = PANEL_INNER_MARGIN
	panel.add_theme_stylebox_override("panel", style)
	return panel


static func _panel_inner_vbox(panel: PanelContainer) -> VBoxContainer:
	var vbox: = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(vbox)
	return vbox


static func _load_rank_avatar_texture(character_id: int) -> Texture2D:
	var cid: = PlayerCharacterConfig.normalize_id(character_id)
	var path: = PlayerCharacterConfig.get_avatar_tx_path(cid)
	if not ResourceLoader.exists(path):
		path = PlayerCharacterConfig.get_avatar_tx_path(0)
	return load(path) as Texture2D


static func _add_ranking_table_header(parent: VBoxContainer) -> void :
	_add_ranking_table_row(parent, "名次", "玩家昵称", "当周竞技点", true, true, 0)


static func _add_ranking_table_row(parent: Node, rank_text: String, name_text: String, pts_text: String, is_header: bool = false, odd_row: bool = false, character_id: int = 0) -> void :
	var row_font_size: = 14 if is_header else 13
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	if not is_header:
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
	else:
		parent.add_child(row)
	var rank_col: = Label.new()
	rank_col.custom_minimum_size.x = RANK_NUM_COL_WIDTH
	rank_col.text = rank_text
	rank_col.add_theme_font_size_override("font_size", row_font_size)
	if is_header:
		rank_col.add_theme_color_override("font_color", Color(0.894, 0.864, 0.803))
	row.add_child(rank_col)
	if is_header:
		var av_h: = Label.new()
		av_h.custom_minimum_size = Vector2(RANK_AVATAR_SIZE, RANK_AVATAR_SIZE)
		av_h.text = "头像"
		av_h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		av_h.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		av_h.add_theme_font_size_override("font_size", row_font_size)
		av_h.add_theme_color_override("font_color", Color(0.894, 0.864, 0.803))
		row.add_child(av_h)
	else:
		var frame: = Panel.new()
		frame.custom_minimum_size = Vector2(RANK_AVATAR_SIZE, RANK_AVATAR_SIZE)
		var av: = TextureRect.new()
		av.set_anchors_preset(Control.PRESET_FULL_RECT)
		av.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		av.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		av.texture = _load_rank_avatar_texture(character_id)
		frame.add_child(av)
		row.add_child(frame)
	var name_col: = Label.new()
	name_col.text = name_text
	name_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_col.clip_text = true
	name_col.add_theme_font_size_override("font_size", row_font_size)
	if is_header:
		name_col.add_theme_color_override("font_color", Color(0.894, 0.864, 0.803))
	row.add_child(name_col)
	var pts_col: = Label.new()
	pts_col.text = pts_text
	pts_col.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pts_col.add_theme_font_size_override("font_size", row_font_size)
	if is_header:
		pts_col.add_theme_color_override("font_color", Color(0.894, 0.864, 0.803))
	row.add_child(pts_col)
