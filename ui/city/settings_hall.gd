extends RefCounted

const UIStyle = preload("res://scripts/ui_style.gd")
const VipBenefits = preload("res://scripts/vip_benefits.gd")
const LocalCacheManager = preload("res://scripts/local_cache_manager.gd")


const SETTINGS_DEBUG_TAB_ENABLED = false

const HOTFIX_SCRIPT_REV: = "diag_2090"
const PATCH_VERSION_FILE: = "user://patch_version.txt"

const SETTINGS_ACTION_BTN_W: = 260.0
const SETTINGS_ACTION_BTN_H: = 48.0

static func _pad_settings_button_style(btn: Button) -> void :
	for state in ["normal", "hover", "pressed", "disabled"]:
		var base: StyleBox = btn.get_theme_stylebox(state)
		if base == null:
			continue
		var s: StyleBox = base.duplicate()
		if s is StyleBoxFlat:
			var flat: = s as StyleBoxFlat
			flat.content_margin_left = 18
			flat.content_margin_right = 18
			flat.content_margin_top = 10
			flat.content_margin_bottom = 10
			flat.corner_radius_top_left = 0
			flat.corner_radius_top_right = 0
			flat.corner_radius_bottom_left = 0
			flat.corner_radius_bottom_right = 0
		btn.add_theme_stylebox_override(state, s)

static func _finish_settings_action_button(btn: Button, min_w: float = SETTINGS_ACTION_BTN_W) -> void :
	btn.custom_minimum_size = Vector2(min_w, SETTINGS_ACTION_BTN_H)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_pad_settings_button_style(btn)

static func _add_centered_settings_button(parent: Control, btn: Button) -> void :
	var row: = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(btn)
	parent.add_child(row)

static func create_fullscreen(game_manager) -> Control:
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", UIStyle.create_panel_style())

	var vbox = UIStyle.create_base_vbox()
	panel.add_child(vbox)

	var title = UIStyle.create_title_label("⚙️ 设置")
	vbox.add_child(title)

	var tab_container = HBoxContainer.new()
	tab_container.add_theme_constant_override("separation", 5)
	vbox.add_child(tab_container)

	var save_tab_btn = Button.new()
	save_tab_btn.text = "存档"
	save_tab_btn.custom_minimum_size = Vector2(80, 35)
	save_tab_btn.add_theme_font_size_override("font_size", 16)
	UIStyle.apply_tab_style(save_tab_btn, true)
	tab_container.add_child(save_tab_btn)

	var vip_tab_btn = Button.new()
	vip_tab_btn.text = "VIP"
	vip_tab_btn.custom_minimum_size = Vector2(80, 35)
	vip_tab_btn.add_theme_font_size_override("font_size", 16)
	UIStyle.apply_tab_style(vip_tab_btn, false)
	tab_container.add_child(vip_tab_btn)

	var noble_tab_btn = Button.new()
	noble_tab_btn.text = "贵族等级"
	noble_tab_btn.custom_minimum_size = Vector2(100, 35)
	noble_tab_btn.add_theme_font_size_override("font_size", 16)
	UIStyle.apply_tab_style(noble_tab_btn, false)
	tab_container.add_child(noble_tab_btn)

	var help_tab_btn = Button.new()
	help_tab_btn.text = "帮助"
	help_tab_btn.custom_minimum_size = Vector2(80, 35)
	help_tab_btn.add_theme_font_size_override("font_size", 16)
	UIStyle.apply_tab_style(help_tab_btn, false)
	tab_container.add_child(help_tab_btn)

	var buff_tab_btn = Button.new()
	buff_tab_btn.text = "增益状态"
	buff_tab_btn.custom_minimum_size = Vector2(100, 35)
	buff_tab_btn.add_theme_font_size_override("font_size", 16)
	UIStyle.apply_tab_style(buff_tab_btn, false)
	tab_container.add_child(buff_tab_btn)

	var capture_tab_btn = Button.new()
	capture_tab_btn.text = "捕捉设置"
	capture_tab_btn.custom_minimum_size = Vector2(100, 35)
	capture_tab_btn.add_theme_font_size_override("font_size", 16)
	UIStyle.apply_tab_style(capture_tab_btn, false)
	tab_container.add_child(capture_tab_btn)


	var debug_tab_btn = null
	if SETTINGS_DEBUG_TAB_ENABLED and not OS.has_feature("release_build"):
		debug_tab_btn = Button.new()
		debug_tab_btn.text = "调试"
		debug_tab_btn.custom_minimum_size = Vector2(80, 35)
		debug_tab_btn.add_theme_font_size_override("font_size", 16)
		UIStyle.apply_tab_style(debug_tab_btn, false)
		tab_container.add_child(debug_tab_btn)

	var content_scroll = ScrollContainer.new()
	content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

	content_scroll.scroll_deadzone = 20
	vbox.add_child(content_scroll)

	var scroll_content = VBoxContainer.new()
	scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	scroll_content.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	scroll_content.add_theme_constant_override("separation", 10)

	scroll_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_scroll.add_child(scroll_content)

	panel.set_meta("scroll_content", scroll_content)
	panel.set_meta("game_manager", game_manager)

	save_tab_btn.pressed.connect( func():
		UIStyle.apply_tab_style(save_tab_btn, true)
		UIStyle.apply_tab_style(vip_tab_btn, false)
		UIStyle.apply_tab_style(noble_tab_btn, false)
		UIStyle.apply_tab_style(help_tab_btn, false)
		UIStyle.apply_tab_style(buff_tab_btn, false)
		UIStyle.apply_tab_style(capture_tab_btn, false)
		if debug_tab_btn:
			UIStyle.apply_tab_style(debug_tab_btn, false)
		_show_save_view_fullscreen(panel)
	)

	vip_tab_btn.pressed.connect( func():
		UIStyle.apply_tab_style(save_tab_btn, false)
		UIStyle.apply_tab_style(vip_tab_btn, true)
		UIStyle.apply_tab_style(noble_tab_btn, false)
		UIStyle.apply_tab_style(help_tab_btn, false)
		UIStyle.apply_tab_style(buff_tab_btn, false)
		UIStyle.apply_tab_style(capture_tab_btn, false)
		if debug_tab_btn:
			UIStyle.apply_tab_style(debug_tab_btn, false)
		_show_vip_view_fullscreen(panel)
	)

	noble_tab_btn.pressed.connect( func():
		UIStyle.apply_tab_style(save_tab_btn, false)
		UIStyle.apply_tab_style(vip_tab_btn, false)
		UIStyle.apply_tab_style(noble_tab_btn, true)
		UIStyle.apply_tab_style(help_tab_btn, false)
		UIStyle.apply_tab_style(buff_tab_btn, false)
		UIStyle.apply_tab_style(capture_tab_btn, false)
		if debug_tab_btn:
			UIStyle.apply_tab_style(debug_tab_btn, false)
		_show_noble_view_fullscreen(panel)
	)

	help_tab_btn.pressed.connect( func():
		UIStyle.apply_tab_style(save_tab_btn, false)
		UIStyle.apply_tab_style(vip_tab_btn, false)
		UIStyle.apply_tab_style(noble_tab_btn, false)
		UIStyle.apply_tab_style(help_tab_btn, true)
		UIStyle.apply_tab_style(buff_tab_btn, false)
		UIStyle.apply_tab_style(capture_tab_btn, false)
		if debug_tab_btn:
			UIStyle.apply_tab_style(debug_tab_btn, false)
		_show_help_view_fullscreen(panel)
	)

	buff_tab_btn.pressed.connect( func():
		UIStyle.apply_tab_style(save_tab_btn, false)
		UIStyle.apply_tab_style(vip_tab_btn, false)
		UIStyle.apply_tab_style(noble_tab_btn, false)
		UIStyle.apply_tab_style(help_tab_btn, false)
		UIStyle.apply_tab_style(buff_tab_btn, true)
		UIStyle.apply_tab_style(capture_tab_btn, false)
		if debug_tab_btn:
			UIStyle.apply_tab_style(debug_tab_btn, false)
		_show_buff_view_fullscreen(panel)
	)

	capture_tab_btn.pressed.connect( func():
		UIStyle.apply_tab_style(save_tab_btn, false)
		UIStyle.apply_tab_style(vip_tab_btn, false)
		UIStyle.apply_tab_style(noble_tab_btn, false)
		UIStyle.apply_tab_style(help_tab_btn, false)
		UIStyle.apply_tab_style(buff_tab_btn, false)
		UIStyle.apply_tab_style(capture_tab_btn, true)
		if debug_tab_btn:
			UIStyle.apply_tab_style(debug_tab_btn, false)
		_show_capture_view_fullscreen(panel)
	)

	if debug_tab_btn:
		debug_tab_btn.pressed.connect( func():
			UIStyle.apply_tab_style(debug_tab_btn, true)
			UIStyle.apply_tab_style(save_tab_btn, false)
			UIStyle.apply_tab_style(vip_tab_btn, false)
			UIStyle.apply_tab_style(noble_tab_btn, false)
			UIStyle.apply_tab_style(help_tab_btn, false)
			UIStyle.apply_tab_style(buff_tab_btn, false)
			_show_debug_view_fullscreen(panel)
		)

	_show_save_view_fullscreen(panel)

	vbox.add_child(_create_hotfix_diag_label())

	return panel

static func _create_hotfix_diag_label() -> Label:
	var label: = Label.new()
	var patch_ver: = ""
	if FileAccess.file_exists(PATCH_VERSION_FILE):
		var f: = FileAccess.open(PATCH_VERSION_FILE, FileAccess.READ)
		if f:
			patch_ver = f.get_as_text().strip_edges()
			f.close()
	var text: = "脚本 rev: %s" % HOTFIX_SCRIPT_REV
	if not patch_ver.is_empty():
		text += " · 热更 %s" % patch_ver
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

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

static func _clear_content_fullscreen(panel: Control):
	var scroll_content = panel.get_meta("scroll_content") as VBoxContainer
	if not scroll_content:
		return
	var content_sc: = scroll_content.get_parent() as ScrollContainer
	if content_sc and content_sc.has_meta("_noble_resize_cb"):
		var noble_cb: Callable = content_sc.get_meta("_noble_resize_cb")
		if content_sc.is_connected("resized", noble_cb):
			content_sc.disconnect("resized", noble_cb)
		content_sc.remove_meta("_noble_resize_cb")

	scroll_content.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	scroll_content.custom_minimum_size = Vector2.ZERO
	scroll_content.add_theme_constant_override("separation", 10)

	var to_clear: = scroll_content.get_children()
	for child in to_clear:
		scroll_content.remove_child(child)
		child.queue_free()

static func _create_settings_section_card(title_text: String) -> Dictionary:
	var panel: = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style: = StyleBoxFlat.new()
	style.bg_color = Color(0.066, 0.074, 0.074, 0.75)
	style.border_color = Color(0.655, 0.531, 0.245, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(0)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	var body: = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	panel.add_child(body)
	var title: = Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	body.add_child(title)
	return {"panel": panel, "body": body}

static func _show_save_view_fullscreen(panel: Control):
	_clear_content_fullscreen(panel)
	var scroll_content = panel.get_meta("scroll_content") as VBoxContainer
	var game_manager = panel.get_meta("game_manager")

	if not scroll_content or not game_manager:
		return

	scroll_content.add_theme_constant_override("separation", 14)


	var save_sec: Dictionary = _create_settings_section_card("本地存档")
	scroll_content.add_child(save_sec["panel"])
	var save_body: VBoxContainer = save_sec["body"]
	var save_btn = Button.new()
	save_btn.text = "保存游戏"
	save_btn.add_theme_font_size_override("font_size", 20)
	UIStyle.apply_orange_action_button_style(save_btn)
	_finish_settings_action_button(save_btn)
	save_btn.pressed.connect( func():
		var result = game_manager.save_game()
		if result:
			_show_accept_only_dialog(panel, "保存成功", "游戏进度已保存到本设备。")
		else:
			_show_accept_only_dialog(panel, "保存失败", "无法写入本地存档。\n请检查存储空间或稍后重试。")
	)
	_add_centered_settings_button(save_body, save_btn)


	var music_sec: Dictionary = _create_settings_section_card("音乐设置")
	scroll_content.add_child(music_sec["panel"])
	var music_body: VBoxContainer = music_sec["body"]

	var music_toggle_hbox = HBoxContainer.new()
	music_toggle_hbox.add_theme_constant_override("separation", 10)
	music_body.add_child(music_toggle_hbox)

	var music_toggle_label = Label.new()
	music_toggle_label.text = "背景音乐:"
	music_toggle_label.add_theme_font_size_override("font_size", 20)
	music_toggle_hbox.add_child(music_toggle_label)

	var music_toggle = CheckButton.new()
	music_toggle.button_pressed = game_manager.bgm_enabled
	music_toggle.add_theme_font_size_override("font_size", 20)
	music_toggle.toggled.connect( func(pressed):
		game_manager.bgm_enabled = pressed
		game_manager._save_audio_settings_to_config()
		if pressed:
			game_manager.play_bgm()
		else:
			game_manager.stop_bgm()
		_stop_all_bgm(panel)
	)
	music_toggle_hbox.add_child(music_toggle)

	var volume_hbox = HBoxContainer.new()
	volume_hbox.add_theme_constant_override("separation", 10)
	music_body.add_child(volume_hbox)

	var volume_label = Label.new()
	volume_label.text = "音量:"
	volume_label.add_theme_font_size_override("font_size", 20)
	volume_hbox.add_child(volume_label)

	var volume_slider = HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.1
	volume_slider.value = game_manager.bgm_volume
	volume_slider.custom_minimum_size = Vector2(200, 30)
	volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_hbox.add_child(volume_slider)

	var volume_value_label = Label.new()
	volume_value_label.text = "%d%%" % int(game_manager.bgm_volume * 100)
	volume_value_label.add_theme_font_size_override("font_size", 20)
	volume_hbox.add_child(volume_value_label)
	volume_slider.value_changed.connect( func(value):
		game_manager.set_bgm_volume(value)
		volume_value_label.text = "%d%%" % int(value * 100)
	)


	if not OS.has_feature("android") and not OS.has_feature("ios") and not OS.has_feature("mobile"):
		var win_sec: Dictionary = _create_settings_section_card("电脑窗口")
		scroll_content.add_child(win_sec["panel"])
		var win_body: VBoxContainer = win_sec["body"]
		var win_hint = Label.new()
		win_hint.text = "可拖窗口边框改大小，下次启动会记住。拉宽后画面会铺满，不留黑边。若看不到标题栏，可点下面按钮缩到屏幕高度九成以内并居中。"
		win_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		win_hint.add_theme_font_size_override("font_size", 15)
		win_hint.add_theme_color_override("font_color", Color(0.842, 0.816, 0.756))
		win_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		win_body.add_child(win_hint)
		var adjust_btn = Button.new()
		adjust_btn.text = "调整窗口"
		adjust_btn.add_theme_font_size_override("font_size", 18)
		UIStyle.apply_action_button_style(adjust_btn)
		_finish_settings_action_button(adjust_btn)
		adjust_btn.pressed.connect( func():
			_on_adjust_desktop_window_pressed(panel)
		)
		_add_centered_settings_button(win_body, adjust_btn)


	var network_sec: Dictionary = _create_settings_section_card("网络功能")
	scroll_content.add_child(network_sec["panel"])
	var network_body: VBoxContainer = network_sec["body"]

	var upload_btn = Button.new()
	upload_btn.text = "上传存档到服务器"
	upload_btn.add_theme_font_size_override("font_size", 18)
	UIStyle.apply_orange_action_button_style(upload_btn)
	_finish_settings_action_button(upload_btn)
	const UPLOAD_SAVE_COOLDOWN_SEC: = 3.0
	var upload_save_cooldown: = Timer.new()
	upload_save_cooldown.wait_time = UPLOAD_SAVE_COOLDOWN_SEC
	upload_save_cooldown.one_shot = true
	upload_btn.add_child(upload_save_cooldown)
	panel.set_meta("_upload_save_cooldown", upload_save_cooldown)
	upload_save_cooldown.timeout.connect( func():
		if is_instance_valid(upload_btn):
			upload_btn.disabled = false
	)
	upload_btn.pressed.connect( func():
		if game_manager.network and game_manager.network.is_logged_in():
			_upload_save_to_server(game_manager)
			print("[设置] 存档已上传到服务器")
		else:
			print("[设置] 请先登录")
		upload_btn.disabled = true
		upload_save_cooldown.start()
	)
	_add_centered_settings_button(network_body, upload_btn)


	var cache_sec: Dictionary = _create_settings_section_card("本地缓存")
	scroll_content.add_child(cache_sec["panel"])
	var cache_body: VBoxContainer = cache_sec["body"]

	var cache_hint = Label.new()
	cache_hint.text = "若更新后仍像旧版、界面错乱或功能偶发异常，可清除本地临时缓存。不会删除云端存档和角色数据；网络正常时建议先上传存档。"
	cache_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cache_hint.add_theme_font_size_override("font_size", 15)
	cache_hint.add_theme_color_override("font_color", Color(0.842, 0.816, 0.756))
	cache_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cache_body.add_child(cache_hint)

	var clear_cache_btn = Button.new()
	clear_cache_btn.text = "清除本地缓存并重新登录"
	clear_cache_btn.add_theme_font_size_override("font_size", 17)
	UIStyle.apply_action_button_style(clear_cache_btn)
	_finish_settings_action_button(clear_cache_btn)
	clear_cache_btn.pressed.connect( func():
		_on_clear_local_cache_pressed(panel, game_manager)
	)
	_add_centered_settings_button(cache_body, clear_cache_btn)


	var exit_sec: Dictionary = _create_settings_section_card("退出游戏")
	scroll_content.add_child(exit_sec["panel"])
	var exit_body: VBoxContainer = exit_sec["body"]

	var exit_hint = Label.new()
	exit_hint.text = "下线前可使用：先完整保存并同步云端，成功后再退出。日常仍以自动精简同步为主，可减少大档上传次数。"
	exit_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	exit_hint.add_theme_font_size_override("font_size", 15)
	exit_hint.add_theme_color_override("font_color", Color(0.842, 0.816, 0.756))
	exit_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	exit_body.add_child(exit_hint)

	var quit_sync_btn = Button.new()
	quit_sync_btn.text = "退出游戏（先同步云端）"
	quit_sync_btn.add_theme_font_size_override("font_size", 18)
	UIStyle.apply_golden_button_style(quit_sync_btn)
	_finish_settings_action_button(quit_sync_btn)
	quit_sync_btn.pressed.connect( func():
		_on_quit_with_cloud_sync_pressed(panel, game_manager, quit_sync_btn)
	)
	_add_centered_settings_button(exit_body, quit_sync_btn)

static func _vip_privileges_table_cell(text: String, is_header: bool, name_column: bool) -> Label:
	var lbl: = Label.new()
	lbl.text = text

	lbl.add_theme_font_size_override("font_size", 17 if is_header else 16)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	lbl.clip_text = true
	if is_header:
		lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elif name_column:
		lbl.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	else:
		lbl.add_theme_color_override("font_color", Color(0.894, 0.864, 0.803))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return lbl



static func _vip_privileges_table_cell_panel(text: String, is_header: bool, name_column: bool, row_index: int, col_index: int) -> PanelContainer:
	var panel: = PanelContainer.new()
	var style: = StyleBoxFlat.new()
	if is_header:
		style.bg_color = Color(0.072, 0.080, 0.079, 0.88)
	else:
		style.bg_color = Color(0.057, 0.066, 0.067, 0.65)
	style.border_color = Color(0.677, 0.549, 0.254, 0.82)
	style.set_corner_radius_all(0)
	style.content_margin_left = 6
	style.content_margin_right = 5
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	if col_index == 0:
		style.border_width_left = 1
	if row_index == 0:
		style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	panel.add_theme_stylebox_override("panel", style)

	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lbl: = _vip_privileges_table_cell(text, is_header, name_column)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(lbl)
	return panel


static func _vip_privileges_table_row(container: VBoxContainer, cells: PackedStringArray, is_header: bool, row_index: int) -> void :
	var row: = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 0)

	row.custom_minimum_size = Vector2(0, 46 if is_header else 42)
	for i in cells.size():
		var name_col: = (i == 0)
		var cell: = _vip_privileges_table_cell_panel(cells[i], is_header, name_col, row_index, i)
		if name_col:
			cell.custom_minimum_size = Vector2(128, 0)
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		else:
			cell.custom_minimum_size = Vector2(48, 0)
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(cell)
	container.add_child(row)


static func _apply_vip_remain_labels(is_vip: bool, expire_raw: String, remain_lbl: Label, detail_lbl: Label) -> void :
	if not is_vip:
		remain_lbl.visible = false
		detail_lbl.visible = false
		remain_lbl.text = ""
		detail_lbl.text = ""
		return
	remain_lbl.visible = true
	var raw: = expire_raw.strip_edges()
	if raw.is_empty():
		detail_lbl.visible = false
		detail_lbl.text = ""
		remain_lbl.text = "剩余时间：待同步请点击「刷新VIP状态」"
		remain_lbl.add_theme_color_override("font_color", Color(0.822, 0.797, 0.737))
		return
	var exp_unix: = VipBenefits.parse_expire_unix(raw)
	var now_ts: = int(Time.get_unix_time_from_system())
	detail_lbl.visible = true
	detail_lbl.text = "到期：%s" % raw
	detail_lbl.add_theme_font_size_override("font_size", 14)
	detail_lbl.add_theme_color_override("font_color", Color(0.822, 0.797, 0.737))
	if exp_unix < 0:
		remain_lbl.text = "到期时间：%s" % raw
		remain_lbl.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
		detail_lbl.visible = false
		detail_lbl.text = ""
		return
	var left: = exp_unix - now_ts
	if left <= 0:
		remain_lbl.text = "VIP 已到期或即将失效请刷新"
		remain_lbl.add_theme_color_override("font_color", Color(0.9, 0.55, 0.55))
	else:
		remain_lbl.text = "剩余：%s" % _format_buff_remaining_time(left)
		remain_lbl.add_theme_color_override("font_color", Color(0.55, 1.0, 0.65))


static func _show_vip_view_fullscreen(panel: Control):
	_clear_content_fullscreen(panel)
	var scroll_content = panel.get_meta("scroll_content") as VBoxContainer
	var game_manager = panel.get_meta("game_manager")

	if not scroll_content or not game_manager:
		return

	var is_vip = false
	if game_manager.player:
		is_vip = game_manager.player.is_vip


	var vip_status_label = Label.new()
	if is_vip:
		vip_status_label.text = "✓ %s" % VipBenefits.tier_display_name(game_manager.player.vip_level)
		vip_status_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	else:
		vip_status_label.text = "您尚未开通VIP"
		vip_status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vip_status_label.add_theme_font_size_override("font_size", 24)
	vip_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scroll_content.add_child(vip_status_label)

	var vip_remain_label: = Label.new()
	vip_remain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vip_remain_label.add_theme_font_size_override("font_size", 18)
	vip_remain_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll_content.add_child(vip_remain_label)
	var vip_expire_detail_label: = Label.new()
	vip_expire_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vip_expire_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll_content.add_child(vip_expire_detail_label)
	var expire_raw0: = ""
	if game_manager.player:
		expire_raw0 = game_manager.player.vip_expire_time_str
	_apply_vip_remain_labels(is_vip, expire_raw0, vip_remain_label, vip_expire_detail_label)


	var refresh_vip_btn = Button.new()
	refresh_vip_btn.text = "刷新VIP状态"
	refresh_vip_btn.add_theme_font_size_override("font_size", 18)
	UIStyle.apply_orange_action_button_style(refresh_vip_btn)
	_finish_settings_action_button(refresh_vip_btn, 220.0)
	refresh_vip_btn.pressed.connect( func():
		if game_manager.network and game_manager.network.is_logged_in():
			game_manager.network.vip_info_loaded.connect( func(new_is_vip: bool, new_vip_level: int, daily_yb: int, new_expire: String):
				if game_manager.player:
					game_manager.player.is_vip = new_is_vip
					game_manager.player.vip_level = new_vip_level
					game_manager.player.vip_expire_time_str = new_expire
					if daily_yb > 0:
						game_manager.player.yuanbao_currency += daily_yb
						game_manager.yuanbao_changed.emit(game_manager.player.yuanbao_currency)
					game_manager.save_game()
					if new_is_vip:
						vip_status_label.text = "✓ %s" % VipBenefits.tier_display_name(new_vip_level)
						vip_status_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
					else:
						vip_status_label.text = "您尚未开通VIP"
						vip_status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
					_apply_vip_remain_labels(new_is_vip, new_expire, vip_remain_label, vip_expire_detail_label)
					_show_vip_refresh_success(panel)
				, CONNECT_ONE_SHOT)
			game_manager.network.get_vip_info()
		else:
			_show_vip_refresh_error(panel, "请先登录")
	)
	_add_centered_settings_button(scroll_content, refresh_vip_btn)


	var benefits_title = Label.new()
	benefits_title.text = "VIP特权内容"
	benefits_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	benefits_title.add_theme_font_size_override("font_size", 22)
	benefits_title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	scroll_content.add_child(benefits_title)



	var table_panel: = PanelContainer.new()
	var table_style: = StyleBoxFlat.new()
	table_style.bg_color = Color(0.072, 0.080, 0.079, 0.92)
	table_style.set_corner_radius_all(0)
	table_style.set_border_width_all(1)
	table_style.border_color = Color(0.655, 0.531, 0.245, 0.55)
	table_panel.add_theme_stylebox_override("panel", table_style)
	table_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	table_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll_content.add_child(table_panel)

	var table_margin: = MarginContainer.new()
	table_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	table_margin.add_theme_constant_override("margin_left", 10)
	table_margin.add_theme_constant_override("margin_right", 10)
	table_margin.add_theme_constant_override("margin_top", 12)
	table_margin.add_theme_constant_override("margin_bottom", 12)
	table_panel.add_child(table_margin)

	var table: = VBoxContainer.new()
	table.mouse_filter = Control.MOUSE_FILTER_IGNORE
	table.add_theme_constant_override("separation", 0)
	table_margin.add_child(table)

	var vip_tr: = 0
	_vip_privileges_table_row(table, PackedStringArray(["权益", "非VIP", "青铜", "白银", "黄金"]), true, vip_tr)
	vip_tr += 1
	_vip_privileges_table_row(table, PackedStringArray(["战斗经验", "×1.0", "×1.3", "×1.6", "×2.0"]), false, vip_tr)
	vip_tr += 1
	_vip_privileges_table_row(table, PackedStringArray(["极品捕捉(‰)", "5", "10", "15", "20"]), false, vip_tr)
	vip_tr += 1
	_vip_privileges_table_row(table, PackedStringArray(["离线时长", "8h", "12h", "16h", "24h"]), false, vip_tr)
	vip_tr += 1
	_vip_privileges_table_row(table, PackedStringArray(["离线礼包概率", "25%", "40%", "45%", "50%"]), false, vip_tr)
	vip_tr += 1
	_vip_privileges_table_row(table, PackedStringArray(["天关扫荡/日", "1", "2", "2", "3"]), false, vip_tr)
	vip_tr += 1
	_vip_privileges_table_row(table, PackedStringArray(["套装扫荡/日", "2", "3", "4", "5"]), false, vip_tr)
	vip_tr += 1
	_vip_privileges_table_row(table, PackedStringArray(["藏宝洞入阵/日", "2", "4", "5", "8"]), false, vip_tr)
	vip_tr += 1
	_vip_privileges_table_row(table, PackedStringArray(["自创武功/日", "3", "4", "5", "6"]), false, vip_tr)
	vip_tr += 1
	_vip_privileges_table_row(table, PackedStringArray(["仙魔行动力上限", "24", "30", "40", "48"]), false, vip_tr)
	vip_tr += 1
	_vip_privileges_table_row(table, PackedStringArray(["仙魔恢复(分/点)", "60", "50", "40", "30"]), false, vip_tr)
	vip_tr += 1
	_vip_privileges_table_row(table, PackedStringArray(["幻化·完美", "5%", "15%", "20%", "30%"]), false, vip_tr)
	vip_tr += 1
	_vip_privileges_table_row(table, PackedStringArray(["幻化·优良", "15%", "20%", "30%", "60%"]), false, vip_tr)
	vip_tr += 1
	_vip_privileges_table_row(table, PackedStringArray(["幻化·普通", "30%", "30%", "40%", "10%"]), false, vip_tr)
	vip_tr += 1
	_vip_privileges_table_row(table, PackedStringArray(["幻化·平均", "50%", "35%", "10%", "0%"]), false, vip_tr)
	vip_tr += 1
	_vip_privileges_table_row(table, PackedStringArray(["宠物袋格数", "50", "50", "70", "100"]), false, vip_tr)
	vip_tr += 1
	_vip_privileges_table_row(table, PackedStringArray(["每日登录元宝", "0", "10", "20", "40"]), false, vip_tr)
	vip_tr += 1
	_vip_privileges_table_row(table, PackedStringArray(["每日变异蛋", "—", "—", "—", "1颗"]), false, vip_tr)
	vip_tr += 1
	_vip_privileges_table_row(table, PackedStringArray(["聊天档位标识", "—", "VIP1", "VIP2", "VIP3"]), false, vip_tr)

	var vip_merge_formula: = Label.new()
	vip_merge_formula.text = "宠物幻化·继承公式：成长=攻+防+敏三项之和；其中高/低指主宠与副宠总成长中的较高者与较低者。\n• 完美：取较高总成长\n• 优良：高×0.8 + 低×0.2\n• 普通：高×0.7 + 低×0.3\n• 平均：(主宠总成长 + 副宠总成长) ÷ 2"
	vip_merge_formula.add_theme_font_size_override("font_size", 14)
	vip_merge_formula.modulate = Color(0.822, 0.797, 0.737)
	vip_merge_formula.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vip_merge_formula.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_content.add_child(vip_merge_formula)

	var benefits_note: = Label.new()
	benefits_note.text = "青铜 / 白银 / 黄金为三档会员，限时有效；表内 — 表示无该项。聊天中三档分别显示 VIP1、VIP2、VIP3 前缀。藏宝洞入阵次数按日重置并以成功入阵计数。上表所列幻化·※相关列为各继承类型在不同 VIP 档位下的出现概率；黄金档当前为完美30% / 优良60% / 普通10% / 平均0%。黄金VIP每日登录由邮件随机发放金、木、水、火、土变异宠物蛋之一，当天只发一封。"
	benefits_note.add_theme_font_size_override("font_size", 14)
	benefits_note.modulate = Color(0.708, 0.688, 0.633)
	benefits_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	benefits_note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_content.add_child(benefits_note)


	var activation_title = Label.new()
	activation_title.text = "如何开通VIP"
	activation_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	activation_title.add_theme_font_size_override("font_size", 22)
	activation_title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	scroll_content.add_child(activation_title)


	var step1 = Label.new()
	step1.text = "① 加入交流群：41501141"
	step1.add_theme_font_size_override("font_size", 16)
	scroll_content.add_child(step1)

	var step2 = Label.new()
	step2.text = "② 联系群主开通VIP"
	step2.add_theme_font_size_override("font_size", 16)
	scroll_content.add_child(step2)

	var step3 = Label.new()
	step3.text = "③ 在页面顶部点击橙色的刷新VIP状态按钮后即可生效"
	step3.add_theme_font_size_override("font_size", 16)
	scroll_content.add_child(step3)


	var note_label = Label.new()
	note_label.text = "注：VIP有效期以开通时约定为准"
	note_label.modulate = Color(0.6, 0.6, 0.6)
	note_label.add_theme_font_size_override("font_size", 14)
	note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scroll_content.add_child(note_label)

static func _show_vip_refresh_success(panel: Control):
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.5)
	panel.add_child(overlay)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var popup = Panel.new()
	popup.custom_minimum_size = Vector2(300, 150)
	popup.add_theme_stylebox_override("panel", UIStyle.create_panel_style())
	center.add_child(popup)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	popup.add_child(vbox)

	var label = Label.new()
	label.text = "VIP状态已刷新"
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.4, 1, 0.4))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)

	await panel.get_tree().create_timer(1.5).timeout
	overlay.queue_free()

static func _show_vip_refresh_error(panel: Control, message: String):
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.5)
	panel.add_child(overlay)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var popup = Panel.new()
	popup.custom_minimum_size = Vector2(300, 150)
	popup.add_theme_stylebox_override("panel", UIStyle.create_panel_style())
	center.add_child(popup)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	popup.add_child(vbox)

	var label = Label.new()
	label.text = message
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)

	await panel.get_tree().create_timer(1.5).timeout
	overlay.queue_free()

static func _format_buff_remaining_time(remaining_seconds: int) -> String:
	var total: = maxi(0, remaining_seconds)
	var days: = total / 86400
	var hours: = (total % 86400) / 3600
	var minutes: = (total % 3600) / 60
	if days > 0:
		return "%d天%d小时" % [days, hours]
	if hours > 0:
		return "%d小时%d分钟" % [hours, minutes]
	return "%d分钟" % minutes


static func _show_noble_view_fullscreen(panel: Control):
	_clear_content_fullscreen(panel)
	var scroll_content = panel.get_meta("scroll_content") as VBoxContainer
	var game_manager = panel.get_meta("game_manager")

	if not scroll_content or not game_manager:
		return


	scroll_content.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	var RANK_NAMES: = ["平民", "一等贵族", "二等贵族", "三等贵族", "四等贵族", "五等贵族", "六等贵族", 
		"七等贵族", "八等贵族", "九等贵族", "亲王", "郡王", "亲公", "国公", "皇帝"]
	var THRESHOLDS: = [1000, 2000, 5000, 8000, 11000, 15000, 20000, 26000, 43000, 51000, 60000, 70000, 81000, 93000, 106000]
	var MERGE_BONUS: = [0, 2, 4, 6, 8, 9, 10, 16, 23, 30, 37, 43, 50, 57, 63, 70]
	var MARTIAL_BONUS: = [0, 3, 7, 10, 13, 17, 20, 23, 27, 30, 33, 37, 40, 43, 47, 50]
	var PET_DAMAGE: = [0, 0, 0, 0, 0, 0, 3, 5, 7, 10, 13, 16, 19, 22, 25, 30]
	var EXP_BONUS: = PET_DAMAGE
	var EXTREME_EQUIP: = [0, 0, 0, 0, 1, 2, 3, 4, 5, 5, 5, 5, 5, 5, 5, 5]

	scroll_content.add_theme_constant_override("separation", 10)

	var _noble_subpanel_style: StyleBoxFlat
	_noble_subpanel_style = StyleBoxFlat.new()
	_noble_subpanel_style.bg_color = Color(0.048, 0.057, 0.059, 0.96)
	_noble_subpanel_style.set_border_width_all(1)
	_noble_subpanel_style.border_color = Color(0.699, 0.566, 0.262, 0.5)
	_noble_subpanel_style.set_corner_radius_all(0)
	_noble_subpanel_style.content_margin_left = 12
	_noble_subpanel_style.content_margin_top = 10
	_noble_subpanel_style.content_margin_right = 12
	_noble_subpanel_style.content_margin_bottom = 10


	var title_label = Label.new()
	title_label.text = "👑 贵族特权"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	scroll_content.add_child(title_label)


	var status_card = PanelContainer.new()
	status_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_card.add_theme_stylebox_override("panel", _noble_subpanel_style.duplicate())
	scroll_content.add_child(status_card)

	var status_vbox = VBoxContainer.new()
	status_vbox.add_theme_constant_override("separation", 8)
	status_card.add_child(status_vbox)


	var noble_level_label = Label.new()
	noble_level_label.text = "⏳ 加载中..."
	noble_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	noble_level_label.add_theme_font_size_override("font_size", 20)
	status_vbox.add_child(noble_level_label)


	var consumed_label = Label.new()
	consumed_label.text = "累计消耗：--"
	consumed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	consumed_label.add_theme_font_size_override("font_size", 20)
	consumed_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	consumed_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_vbox.add_child(consumed_label)

	var progress_bar: = ProgressBar.new()
	progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_bar.custom_minimum_size = Vector2(0, 22)
	progress_bar.value = 0
	progress_bar.max_value = 100
	progress_bar.show_percentage = false
	status_vbox.add_child(progress_bar)


	var progress_text_label: = Label.new()
	progress_text_label.text = ""
	progress_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_text_label.add_theme_font_size_override("font_size", 20)
	progress_text_label.modulate = Color(0.822, 0.797, 0.737)
	progress_text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_vbox.add_child(progress_text_label)


	var refresh_row = HBoxContainer.new()
	refresh_row.alignment = BoxContainer.ALIGNMENT_CENTER
	refresh_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var refresh_btn = Button.new()
	refresh_btn.text = "🔄 刷新贵族数据"
	refresh_btn.add_theme_font_size_override("font_size", 18)
	UIStyle.apply_orange_action_button_style(refresh_btn)
	_finish_settings_action_button(refresh_btn, 240.0)
	refresh_row.add_child(refresh_btn)
	status_vbox.add_child(refresh_row)


	var main_row: = HBoxContainer.new()
	var vh: = 720
	if panel.is_inside_tree():
		vh = int(panel.get_viewport().get_visible_rect().size.y)

	main_row.custom_minimum_size = Vector2(0, maxi(280, vh - 260))
	main_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	main_row.add_theme_constant_override("separation", 8)
	scroll_content.add_child(main_row)

	var left_wrap: = PanelContainer.new()
	left_wrap.custom_minimum_size = Vector2(132, 0)
	left_wrap.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var left_style: StyleBoxFlat = _noble_subpanel_style.duplicate()
	left_style.content_margin_left = 6
	left_style.content_margin_right = 4
	left_style.content_margin_top = 6
	left_style.content_margin_bottom = 6
	left_wrap.add_theme_stylebox_override("panel", left_style)
	main_row.add_child(left_wrap)


	var left_vbox: = VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	left_vbox.add_theme_constant_override("separation", 3)
	left_wrap.add_child(left_vbox)

	var rank_buttons: Array[Button] = []
	for i in range(15):
		var lv: = i + 1
		var btn: = Button.new()
		btn.text = "贵族%d" % lv
		btn.custom_minimum_size = Vector2(120, 44)
		btn.add_theme_font_size_override("font_size", 20)
		btn.tooltip_text = "%s\n需求：%d 元宝" % [RANK_NAMES[min(lv, RANK_NAMES.size() - 1)], THRESHOLDS[i]]
		rank_buttons.append(btn)
		left_vbox.add_child(btn)

	var right_wrap: = PanelContainer.new()
	right_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var right_style: StyleBoxFlat = _noble_subpanel_style.duplicate()
	right_style.content_margin_left = 8
	right_style.content_margin_right = 8
	right_style.content_margin_top = 8
	right_style.content_margin_bottom = 8
	right_wrap.add_theme_stylebox_override("panel", right_style)
	main_row.add_child(right_wrap)


	var right_vbox: = VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	right_vbox.add_theme_constant_override("separation", 10)
	right_wrap.add_child(right_vbox)

	var detail_title: = Label.new()
	detail_title.text = "选择等级查看权益"
	detail_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	detail_title.add_theme_font_size_override("font_size", 20)
	detail_title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	detail_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(detail_title)

	var detail_container: = VBoxContainer.new()
	detail_container.add_theme_constant_override("separation", 6)
	detail_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(detail_container)

	var right_mid_sep: = HSeparator.new()
	right_mid_sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(right_mid_sep)


	var claim_area: = VBoxContainer.new()
	claim_area.add_theme_constant_override("separation", 6)
	claim_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(claim_area)

	var claim_title_lbl = Label.new()
	claim_title_lbl.text = "🎁 可领取奖励"
	claim_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	claim_title_lbl.add_theme_font_size_override("font_size", 20)
	claim_title_lbl.add_theme_color_override("font_color", Color(1, 0.84, 0))
	claim_area.add_child(claim_title_lbl)

	var claim_row: = VBoxContainer.new()
	claim_row.alignment = BoxContainer.ALIGNMENT_CENTER
	claim_row.add_theme_constant_override("separation", 8)
	claim_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	claim_area.add_child(claim_row)

	var claim_empty_label: = Label.new()
	claim_empty_label.text = "无"
	claim_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	claim_empty_label.add_theme_font_size_override("font_size", 20)
	claim_empty_label.modulate = Color(0.75, 0.75, 0.75)
	claim_area.add_child(claim_empty_label)

	var claim_status_label: = Label.new()
	claim_status_label.text = ""
	claim_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	claim_status_label.add_theme_font_size_override("font_size", 16)
	claim_status_label.modulate = Color(0.75, 0.75, 0.75)
	claim_area.add_child(claim_status_label)

	var equip_claim_btn = Button.new()
	equip_claim_btn.text = "领取极限装备礼包"
	equip_claim_btn.add_theme_font_size_override("font_size", 18)
	equip_claim_btn.visible = false
	UIStyle.apply_orange_action_button_style(equip_claim_btn)
	_finish_settings_action_button(equip_claim_btn)
	claim_row.add_child(equip_claim_btn)

	var pet10_claim_btn = Button.new()
	pet10_claim_btn.text = "领取9.9哪吒"
	pet10_claim_btn.add_theme_font_size_override("font_size", 18)
	pet10_claim_btn.visible = false
	UIStyle.apply_orange_action_button_style(pet10_claim_btn)
	_finish_settings_action_button(pet10_claim_btn)
	claim_row.add_child(pet10_claim_btn)


	_enable_touch_drag_passthrough(status_card)
	_enable_touch_drag_passthrough(main_row)
	_enable_touch_drag_passthrough(left_wrap)
	_enable_touch_drag_passthrough(right_wrap)
	_enable_touch_drag_passthrough(left_vbox)
	_enable_touch_drag_passthrough(right_vbox)


	var current_level: = 0
	var current_data: Dictionary = {}
	var noble_runtime: = {
		"level": 0, 
		"claims": {}
	}
	var selected_level: = 1

	var _apply_claim_btn_state = func(btn: Button, base_text: String, claim_key: String, required_lv: int, claims: Dictionary, view_lv: int) -> String:
		var current_lv: = int(noble_runtime.get("level", 0))
		btn.visible = true
		btn.text = base_text
		UIStyle.apply_muted_noble_claim_button_style(btn)
		_finish_settings_action_button(btn)

		if claim_key == "extreme_equip":
			var reward_data: Dictionary = {}
			if claims.has("extreme_equip") and claims["extreme_equip"] is Dictionary:
				reward_data = (claims["extreme_equip"] as Dictionary).get("rewardData", {}) as Dictionary
			var claimed_map: = {}
			var lv_list = reward_data.get("claimedLevels", [])
			if lv_list is Array:
				for one in lv_list:
					var lv_i: = int(one)
					if lv_i >= 4 and lv_i <= 15:
						claimed_map[str(lv_i)] = true
			var cnt_for_view: = int(EXTREME_EQUIP[min(max(view_lv, 0), EXTREME_EQUIP.size() - 1)])
			btn.text = "领取极限装备礼包 x%d" % cnt_for_view
			if view_lv > current_lv:
				btn.disabled = true
				btn.tooltip_text = "未达本页贵族等级，可切换到不高于自身等级的页面领取"
				btn.modulate = Color(1, 1, 1, 1)
				return "本页为预览（未达该页等级）"
			if current_lv < required_lv:
				btn.disabled = true
				btn.tooltip_text = "当前贵族等级%d，达到贵族等级%d后可领取" % [current_lv, required_lv]
				btn.modulate = Color(0.9, 0.9, 0.9, 1)
				return "未达到领取等级（当前%d级，需要%d级）" % [current_lv, required_lv]
			if claimed_map.has(str(view_lv)):
				btn.disabled = true
				btn.tooltip_text = "该等级极限礼包已领取"
				btn.modulate = Color(0.9, 0.9, 0.9, 1)
				return "该等级奖励状态：已领取"
			btn.disabled = false
			UIStyle.apply_orange_action_button_style(btn)
			_finish_settings_action_button(btn)
			btn.tooltip_text = "满足领取条件，点击领取本等级礼包"
			btn.modulate = Color(1, 1, 1, 1)
			return "该等级奖励状态：可领取"
		if view_lv > current_lv:
			btn.disabled = true
			btn.tooltip_text = "未达本页贵族等级，可切换到不高于自身等级的页面领取"
			btn.modulate = Color(1, 1, 1, 1)
			return "本页为预览（未达该页等级）"
		var reached: = current_lv >= required_lv
		var claimed: = claims.has(claim_key) and claims.get(claim_key) != null
		if not reached:
			btn.disabled = true
			btn.tooltip_text = "当前贵族等级%d，达到贵族等级%d后可领取" % [current_lv, required_lv]
			btn.modulate = Color(0.9, 0.9, 0.9, 1)
			return "未达到领取等级（当前%d级，需要%d级）" % [current_lv, required_lv]
		if claimed:
			btn.disabled = true
			btn.tooltip_text = "该奖励已领取"
			btn.modulate = Color(0.9, 0.9, 0.9, 1)
			return "该奖励状态：已领取"
		btn.disabled = false
		UIStyle.apply_orange_action_button_style(btn)
		_finish_settings_action_button(btn)
		btn.tooltip_text = "满足领取条件，点击领取"
		btn.modulate = Color(1, 1, 1, 1)
		return "该奖励状态：可领取"

	var _refresh_claim_area = func(lv: int, claims: Dictionary):
		if claims.is_empty():
			claims = noble_runtime.get("claims", {})
		equip_claim_btn.visible = lv >= 4
		pet10_claim_btn.visible = lv == 10

		var status_texts: Array[String] = []
		if equip_claim_btn.visible:
			status_texts.append("极限礼包：" + _apply_claim_btn_state.call(equip_claim_btn, "领取极限装备礼包", "extreme_equip", 4, claims, lv))
		if pet10_claim_btn.visible:
			status_texts.append("9.9哪吒：" + _apply_claim_btn_state.call(pet10_claim_btn, "领取9.9哪吒", "special_pet_10", 10, claims, lv))

		claim_row.visible = equip_claim_btn.visible or pet10_claim_btn.visible
		claim_empty_label.visible = not claim_row.visible
		claim_status_label.visible = claim_row.visible
		claim_status_label.text = "\n".join(status_texts)

	var show_rank_detail = func(lv: int):
		selected_level = lv
		detail_title.text = "贵族等级%d权益（需消耗元宝额度%d）" % [lv, THRESHOLDS[lv - 1]]
		for child in detail_container.get_children():
			child.queue_free()

		if MERGE_BONUS[lv] > 0:
			detail_container.add_child(_create_benefit_item("💰", "幻化完美概率 +%d%%" % MERGE_BONUS[lv]))
		if MARTIAL_BONUS[lv] > 0:
			detail_container.add_child(_create_benefit_item("⚔️", "自创武功成功率 +%d%%" % MARTIAL_BONUS[lv]))
		if lv >= 1:
			detail_container.add_child(_create_benefit_item("🏰", "兄弟天关每日通关 +%d 次" % lv))
		if lv >= 3:
			detail_container.add_child(_create_benefit_item("🤝", "解锁助战槽1（无需投胎 100 次）"))
		if lv >= 5:
			detail_container.add_child(_create_benefit_item("🗺️", "可进困难地图（无需投胎 100 次）"))
		if lv >= 6:
			detail_container.add_child(_create_benefit_item("🤝", "解锁助战槽2（无需投胎 200 次）"))
		if lv >= 9:
			detail_container.add_child(_create_benefit_item("🤝", "解锁助战槽3（无需投胎 300 次）"))
		if lv >= 10:
			detail_container.add_child(_create_benefit_item("🗺️", "可进地狱地图（无需投胎 200 次）"))
		if lv >= 12:
			detail_container.add_child(_create_benefit_item("🤝", "解锁助战槽4（无需投胎 400 次）"))
		if lv >= 15:
			detail_container.add_child(_create_benefit_item("🤝", "解锁助战槽5（无需投胎 500 次）"))
			detail_container.add_child(_create_benefit_item("🗺️", "可进史诗地图（无需投胎 300 次）"))
		if PET_DAMAGE[lv] > 0:
			detail_container.add_child(_create_benefit_item("🐾", "出战宠物攻防敏 +%d%%" % PET_DAMAGE[lv]))
		if EXP_BONUS[lv] > 0:
			detail_container.add_child(_create_benefit_item("📘", "经验加成 +%d%%" % EXP_BONUS[lv]))
		if EXTREME_EQUIP[lv] > 0:
			detail_container.add_child(_create_benefit_item("🎁", "极限装备礼包 ×%d" % EXTREME_EQUIP[lv]))
		if lv >= 11:
			var item = _create_benefit_item("📖", "单系宠物图鉴激活（联系群主）")
			item.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
			detail_container.add_child(item)
		if lv == 10:
			detail_container.add_child(_create_benefit_item("🎉", "特殊宠物：1级成长9.9哪吒（变异1，自带溅射lv1）"))
		if lv >= 15:
			var item = _create_benefit_item("👑", "联系群主私人定制13.9变异2图档宠(自带宠物技能溅射Iv2)")
			item.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
			detail_container.add_child(item)

		for idx in range(rank_buttons.size()):
			var rb = rank_buttons[idx]
			if idx + 1 == lv:
				rb.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
				var selected_style: = StyleBoxFlat.new()
				selected_style.bg_color = Color(0.072, 0.080, 0.079, 0.98)
				selected_style.set_border_width_all(2)
				selected_style.border_color = Color(1.000, 0.905, 0.640, 0.95)
				selected_style.set_corner_radius_all(0)
				rb.add_theme_stylebox_override("normal", selected_style)
				rb.add_theme_stylebox_override("hover", selected_style)
				rb.add_theme_stylebox_override("pressed", selected_style)
			elif idx + 1 <= int(noble_runtime.get("level", 0)):
				rb.add_theme_color_override("font_color", Color(1, 0.95, 0.85))
				var reached_style: = StyleBoxFlat.new()
				reached_style.bg_color = Color(0.118, 0.100, 0.058, 0.92)
				reached_style.set_border_width_all(1)
				reached_style.border_color = Color(1.0, 0.68, 0.2, 0.95)
				reached_style.set_corner_radius_all(0)
				rb.add_theme_stylebox_override("normal", reached_style)
				rb.add_theme_stylebox_override("hover", reached_style)
				rb.add_theme_stylebox_override("pressed", reached_style)
			else:
				rb.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78))
				var default_style: = StyleBoxFlat.new()
				default_style.bg_color = Color(0.072, 0.080, 0.079, 0.9)
				default_style.set_border_width_all(1)
				default_style.border_color = Color(0.655, 0.531, 0.245, 0.9)
				default_style.set_corner_radius_all(0)
				rb.add_theme_stylebox_override("normal", default_style)
				rb.add_theme_stylebox_override("hover", default_style)
				rb.add_theme_stylebox_override("pressed", default_style)

		var claims: Dictionary = noble_runtime.get("claims", {})
		_refresh_claim_area.call(lv, claims)

		_enable_touch_drag_passthrough(detail_container)

	var update_noble_ui = func(data: Dictionary):
		current_data = data
		current_level = int(data.get("nobleLevel", 0))
		noble_runtime["level"] = current_level
		var raw_consumed: int = int(data.get("totalConsumed", 0))
		var display_cap: int = THRESHOLDS[THRESHOLDS.size() - 1]
		var display_consumed: int = mini(raw_consumed, display_cap)
		var progress_str: String = str(data.get("progress", "0/1000"))
		noble_runtime["claims"] = data.get("claims", {})

		if current_level > 0:
			noble_level_label.text = "贵族等级 %d / %s" % [current_level, RANK_NAMES[min(current_level, RANK_NAMES.size() - 1)]]
			noble_level_label.add_theme_color_override("font_color", Color(1, 0.84, 0) if current_level >= 10 else Color(0.3, 0.9, 0.3))
		else:
			noble_level_label.text = "尚未成为贵族"
			noble_level_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))

		consumed_label.text = "累计消耗：%d 元宝" % display_consumed

		var parts = progress_str.split("/")
		if parts.size() == 2 and parts[0].is_valid_float() and parts[1].is_valid_float():
			var cur_val: = float(parts[0])
			var max_val: = float(parts[1])
			var cur_display: = minf(float(display_cap), cur_val)
			progress_bar.max_value = max_val if max_val > 0 else 1.0
			progress_bar.value = minf(cur_display, max_val)
			progress_text_label.text = "%d/%d" % [int(floor(cur_display)), int(floor(max_val))]
		else:
			progress_text_label.text = progress_str if not progress_str.is_empty() else "--"
			progress_bar.max_value = 1.0
			progress_bar.value = 1.0 if progress_str == "已满级" or current_level >= 15 else 0.0

		var max_view_lv: = maxi(1, current_level if current_level > 0 else 1)
		var keep_lv: = mini(max_view_lv, maxi(1, selected_level))
		show_rank_detail.call(keep_lv)




	for i in range(rank_buttons.size()):
		var lv: = i + 1
		rank_buttons[i].pressed.connect( func(): show_rank_detail.call(lv))


	refresh_btn.pressed.connect( func():
		if game_manager.network and game_manager.network.is_logged_in():
			refresh_btn.disabled = true
			refresh_btn.text = "⏳ 查询中..."

			game_manager.network.noble_info_loaded.connect( func(data: Dictionary):
				update_noble_ui.call(data)
				refresh_btn.disabled = false
				refresh_btn.text = "🔄 刷新贵族数据"
			, CONNECT_ONE_SHOT)

			game_manager.network.noble_info_failed.connect( func(error: String):
				noble_level_label.text = "❌ 获取失败"
				noble_level_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
				consumed_label.text = error
				progress_text_label.text = ""
				refresh_btn.disabled = false
				refresh_btn.text = "🔄 刷新贵族数据"
			, CONNECT_ONE_SHOT)

			game_manager.network.get_noble_info()
		else:
			noble_level_label.text = "❌ 请先登录"
			noble_level_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	)


	equip_claim_btn.pressed.connect( func(): _do_noble_claim(game_manager, "extreme_equip", equip_claim_btn, panel, selected_level))
	pet10_claim_btn.pressed.connect( func(): _do_noble_claim(game_manager, "special_pet_10", pet10_claim_btn, panel))


	if game_manager.network and game_manager.network.is_logged_in():
		refresh_btn.pressed.emit()

static func _localize_noble_claim_error(english: String) -> String:
	var t: String = str(english).strip_edges()
	if t.is_empty():
		return "操作失败，请稍后再试。"
	var key: = t
	if t.contains("—"):
		key = t.split("—")[0].strip_edges()
	match key:
		"Already claimed", "已领取":
			return "该奖励已领取，请在邮件中查收；若已领取，按钮将随刷新变为已领取状态。"
		"Not eligible for this reward", "Ineligible for this reward":
			return "暂不符合该奖励的领取条件（等级或权益未满足）。"
		"claimType required":
			return "请求参数错误，请重试或联系管理。"
		"operationId required":
			return "操作编号缺失，请重试。"
		"Invalid claim type":
			return "领取类型无效，请重试或更新客户端。"
		"claimLevel required for extreme_equip":
			return "极限装备领取缺少等级参数，请刷新界面后重试。"
		"未登录":
			return t
		"网络请求失败", "无法连接到服务器", "请求超时，请检查网络后重试":
			return t
		_:
			pass
	if t.to_lower() == "already claimed":
		return "该奖励已领取。"
	if t.to_lower() == "not eligible for this reward" or t.to_lower().begins_with("not eligible"):
		return "暂不符合该奖励的领取条件。"
	if t.begins_with("服务器") or t.contains("HTTP"):
		return t
	return "操作失败。%s" % t

static func _extract_noble_success_message(data: Dictionary) -> String:
	var r: Variant = data.get("reward", null)
	if r is Dictionary:
		var rd: Dictionary = r
		var s: String = str(rd.get("description", "")).strip_edges()
		if not s.is_empty():
			return "%s。奖励已发至邮箱，请在邮件中查收。" % s
	if bool(data.get("duplicate", false)):
		return "该操作已处理。正在为你同步最新贵族与领取信息。"
	return "领取成功。奖励已发至邮箱，请在邮件中查收。"

static func _find_noble_refresh_button_in_subtree(n: Node) -> Button:
	if n is Button and "刷新" in str((n as Button).text):
		return n as Button
	for c in n.get_children():
		var b: Button = _find_noble_refresh_button_in_subtree(c)
		if b:
			return b
	return null

static func _trigger_noble_settings_refresh(panel: Control) -> void :
	if not is_instance_valid(panel) or not panel.has_meta("scroll_content"):
		return
	var root: Node = panel.get_meta("scroll_content") as Node
	if not root:
		return
	var btn: Button = _find_noble_refresh_button_in_subtree(root)
	if btn:
		btn.pressed.emit()

static func _do_noble_claim(game_manager, claim_type: String, btn: Button, panel: Control, claim_level: int = 0):
	if not game_manager.network or not game_manager.network.is_logged_in():
		return

	btn.disabled = true
	btn.text = "⏳ 领取中..."

	game_manager.network.noble_claim_success.connect( func(data: Dictionary):
		var msg: = _extract_noble_success_message(data)
		_trigger_noble_settings_refresh(panel)
		_show_accept_only_dialog(panel, "领取成功", msg)
	, CONNECT_ONE_SHOT)

	game_manager.network.noble_claim_failed.connect( func(error: String):
		_trigger_noble_settings_refresh(panel)
		var err_zh: String = _localize_noble_claim_error(error)
		_show_accept_only_dialog(panel, "提示", err_zh)
	, CONNECT_ONE_SHOT)

	game_manager.network.claim_noble_reward(claim_type, claim_level)


static func _create_benefit_item(icon: String, text: String) -> Label:
	var label = Label.new()
	label.text = "%s  %s" % [icon, text]
	label.add_theme_font_size_override("font_size", 20)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label

static func _add_exp_bonus_status_line(scroll_content: VBoxContainer, title: String, pct: float, active_extra: String = "") -> void :
	var line: = Label.new()
	var shown: = 0.0
	if pct > 0.01:
		shown = pct
	if shown > 0.01:
		var pct_text: = ("%.1f" % shown).trim_suffix(".0")
		if active_extra.is_empty():
			line.text = "%s：生效中 +%s%%" % [title, pct_text]
		else:
			line.text = "%s：生效中 +%s%%（%s）" % [title, pct_text, active_extra]
		line.add_theme_color_override("font_color", Color(0.55, 1.0, 0.65))
	else:
		line.text = "%s：未生效" % title
		line.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	line.add_theme_font_size_override("font_size", 18)
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll_content.add_child(line)

static func _show_buff_view_fullscreen(panel: Control):
	_clear_content_fullscreen(panel)
	var scroll_content = panel.get_meta("scroll_content") as VBoxContainer
	var game_manager = panel.get_meta("game_manager")
	if not scroll_content or not game_manager:
		return

	var buff_title = Label.new()
	buff_title.text = "增益状态"
	buff_title.add_theme_font_size_override("font_size", 22)
	buff_title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	scroll_content.add_child(buff_title)

	var buff_note = Label.new()
	buff_note.text = "这里显示限时增益和当前经验加成。"
	buff_note.add_theme_font_size_override("font_size", 14)
	buff_note.modulate = Color(0.822, 0.797, 0.737)
	buff_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll_content.add_child(buff_note)

	var now_ts: = int(Time.get_unix_time_from_system())
	var player = game_manager.player
	var double_exp_left: = 0
	if player != null:
		double_exp_left = maxi(0, int(player.double_exp_until) - now_ts)

	var double_exp_status = Label.new()
	if double_exp_left > 0:
		double_exp_status.text = "双倍经验丹：生效中，剩余 %s" % _format_buff_remaining_time(double_exp_left)
		double_exp_status.add_theme_color_override("font_color", Color(0.55, 1.0, 0.65))
	else:
		double_exp_status.text = "双倍经验丹：未生效"
		double_exp_status.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	double_exp_status.add_theme_font_size_override("font_size", 18)
	double_exp_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll_content.add_child(double_exp_status)

	var newbie_exp_left: = 0
	if player != null:
		newbie_exp_left = maxi(0, int(player.newbie_exp_until) - now_ts)
	var newbie_exp_status = Label.new()
	if newbie_exp_left > 0:
		newbie_exp_status.text = "新人经验加成：生效中（野外/离线 +100%%），剩余 %s" % _format_buff_remaining_time(newbie_exp_left)
		newbie_exp_status.add_theme_color_override("font_color", Color(0.55, 1.0, 0.65))
	else:
		newbie_exp_status.text = "新人经验加成：未生效（注册起 10 天内有效）"
		newbie_exp_status.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	newbie_exp_status.add_theme_font_size_override("font_size", 18)
	newbie_exp_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll_content.add_child(newbie_exp_status)

	var vip_pct: = 0.0
	if player != null:
		var vip_mult: = VipBenefits.exp_multiplier(VipBenefits.tier_from_player(player))
		vip_pct = (vip_mult - 1.0) * 100.0
	_add_exp_bonus_status_line(scroll_content, "VIP经验加成", vip_pct)

	var gang_pct: = 0.0
	if game_manager.has_method("get_gang_exp_bonus_percent"):
		gang_pct = float(game_manager.get_gang_exp_bonus_percent())
	_add_exp_bonus_status_line(scroll_content, "帮派经验加成", gang_pct)

	var noble_lv: = clampi(int(game_manager.noble_level), 0, 15)
	var noble_pct: = float(NobleBenefits.EXP_BONUS[noble_lv])
	if "noble_exp_bonus" in game_manager:
		noble_pct = float(maxi(0, int(game_manager.noble_exp_bonus)))
	_add_exp_bonus_status_line(scroll_content, "贵族经验加成", noble_pct)

	var fabao_pct: = (FabaoStatBonus.exp_multiplier() - 1.0) * 100.0
	_add_exp_bonus_status_line(scroll_content, "法宝经验加成", fabao_pct)

	var map_pct: = 0
	var map_name: = ""
	if game_manager.fabao_manager:
		var tier_id: = str(game_manager.fabao_manager.current_difficulty)
		map_pct = FabaoConfig.map_exp_bonus_pct(tier_id)
		map_name = FabaoConfig.display_name(tier_id)
	_add_exp_bonus_status_line(scroll_content, "地图难度经验加成", float(map_pct), map_name)

	var catchup_status = Label.new()
	var catchup_on: = false
	var catchup_ups: = 1
	var catchup_gap: = 0
	var catchup_first: = 0
	if player != null:
		catchup_on = bool(player.catchup_enabled)
		catchup_ups = clampi(int(player.catchup_field_max_level_ups), 1, 10)
		catchup_gap = maxi(0, int(player.catchup_gap))
		catchup_first = maxi(0, int(player.catchup_first_reincarnation))
	if not catchup_on:
		catchup_status.text = "投胎追赶：后台未开启（野外一场仍只升 1 级）"
		catchup_status.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	elif catchup_ups > 1:
		catchup_status.text = "投胎追赶：落后第一名 %d 投（第一名 %d），野外一场最多连升 %d 级" % [catchup_gap, catchup_first, catchup_ups]
		catchup_status.add_theme_color_override("font_color", Color(0.55, 1.0, 0.65))
	else:
		catchup_status.text = "投胎追赶：已开启，当前差距不足档位（一场仍 1 级）"
		catchup_status.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	catchup_status.add_theme_font_size_override("font_size", 18)
	catchup_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll_content.add_child(catchup_status)

	var refresh_btn = Button.new()
	refresh_btn.text = "刷新状态"
	refresh_btn.add_theme_font_size_override("font_size", 18)
	UIStyle.apply_orange_action_button_style(refresh_btn)
	_finish_settings_action_button(refresh_btn, 220.0)
	refresh_btn.pressed.connect( func():
		refresh_btn.disabled = true
		refresh_btn.text = "同步中..."
		var gm = game_manager
		if gm and gm.network and gm.network.is_logged_in():
			if not gm.network.player_buffs_loaded.is_connected(_on_buffs_loaded):
				gm.network.player_buffs_loaded.connect(_on_buffs_loaded.bind(panel, refresh_btn))
			gm.network.get_player_buffs()
		else:
			_show_buff_view_fullscreen(panel)
	)
	_add_centered_settings_button(scroll_content, refresh_btn)

static func _on_buffs_loaded(data: Dictionary, panel: Control, refresh_btn: Button):
	var gm = panel.get_meta("game_manager")
	if gm and gm.network:
		if gm.network.player_buffs_loaded.is_connected(_on_buffs_loaded):
			gm.network.player_buffs_loaded.disconnect(_on_buffs_loaded)
	if gm and gm.player and not data.has("error"):
		if data.has("double_exp_until"):
			gm.player.double_exp_until = int(data.get("double_exp_until", 0))
		if data.has("newbie_exp_until"):
			gm.player.newbie_exp_until = maxi(0, int(data.get("newbie_exp_until", 0)))
		if data.has("catchup_enabled"):
			gm.player.catchup_enabled = bool(data.get("catchup_enabled", false))
		if data.has("catchup_first_reincarnation"):
			gm.player.catchup_first_reincarnation = maxi(0, int(data.get("catchup_first_reincarnation", 0)))
		if data.has("catchup_gap"):
			gm.player.catchup_gap = maxi(0, int(data.get("catchup_gap", 0)))
		if data.has("catchup_field_max_level_ups"):
			gm.player.catchup_field_max_level_ups = clampi(int(data.get("catchup_field_max_level_ups", 1)), 1, 10)
		if data.has("catchup_day"):
			gm.player.catchup_day = str(data.get("catchup_day", ""))
	if is_instance_valid(refresh_btn):
		refresh_btn.disabled = false
		refresh_btn.text = "刷新状态"
	_show_buff_view_fullscreen(panel)

static func _show_capture_view_fullscreen(panel: Control):
	_clear_content_fullscreen(panel)
	var scroll_content = panel.get_meta("scroll_content") as VBoxContainer
	var game_manager = panel.get_meta("game_manager")
	if not scroll_content or not game_manager:
		return
	var title_label = Label.new()
	title_label.text = "自动捕捉设置"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	scroll_content.add_child(title_label)
	var toggle_hbox = HBoxContainer.new()
	toggle_hbox.add_theme_constant_override("separation", 10)
	scroll_content.add_child(toggle_hbox)
	var toggle_label = Label.new()
	toggle_label.text = "自动捕捉:"
	toggle_label.add_theme_font_size_override("font_size", 18)
	toggle_hbox.add_child(toggle_label)
	var toggle = CheckButton.new()
	toggle.button_pressed = game_manager.auto_capture_enabled
	toggle.add_theme_font_size_override("font_size", 18)
	toggle.toggled.connect( func(pressed):
		game_manager.auto_capture_enabled = pressed
	)
	toggle_hbox.add_child(toggle)
	var growth_hbox = HBoxContainer.new()
	growth_hbox.add_theme_constant_override("separation", 10)
	scroll_content.add_child(growth_hbox)
	var growth_label = Label.new()
	growth_label.text = "最低成长率:"
	growth_label.add_theme_font_size_override("font_size", 18)
	growth_hbox.add_child(growth_label)
	var growth_spin = SpinBox.new()
	growth_spin.min_value = 0.5
	growth_spin.max_value = 99.0
	growth_spin.step = 0.1
	growth_spin.value = game_manager.min_growth_threshold
	growth_spin.add_theme_font_size_override("font_size", 18)
	growth_spin.value_changed.connect( func(value):
		game_manager.min_growth_threshold = value
	)
	growth_hbox.add_child(growth_spin)
	var help_label = Label.new()
	help_label.text = "说明:\n- 自动捕捉开启后，战斗胜利会尝试捕捉怪物\n- 成长率低于设定值的宠物会自动投入图鉴\n- 图鉴已满50只的宠物类型不再捕捉"
	help_label.add_theme_font_size_override("font_size", 16)
	help_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	help_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll_content.add_child(help_label)
	var separator = HSeparator.new()
	scroll_content.add_child(separator)
	var save_btn = Button.new()
	save_btn.text = "保存设置"
	save_btn.add_theme_font_size_override("font_size", 18)
	UIStyle.apply_orange_action_button_style(save_btn)
	_finish_settings_action_button(save_btn, 220.0)
	save_btn.pressed.connect( func():
		save_btn.disabled = true
		var want_auto: bool = toggle.button_pressed
		var want_growth: float = growth_spin.value
		if not game_manager.network or not game_manager.network.is_logged_in():
			game_manager.auto_capture_enabled = want_auto
			game_manager.min_growth_threshold = want_growth
			game_manager.save_game()
			save_btn.disabled = false
			_show_accept_only_dialog(panel, "保存成功", "设置已保存\n当前未登录，仅保存在本设备；登录后请再点一次保存同步到云端。")
			return
		var prev_auto: bool = game_manager.auto_capture_enabled
		var prev_growth: float = game_manager.min_growth_threshold
		var api_result: Dictionary = await game_manager.request_capture_settings_authority(want_auto, want_growth)
		if not is_instance_valid(panel) or not is_instance_valid(save_btn):
			return
		save_btn.disabled = false
		if not bool(api_result.get("ok", false)):
			game_manager.auto_capture_enabled = prev_auto
			game_manager.min_growth_threshold = prev_growth
			if is_instance_valid(toggle):
				toggle.button_pressed = prev_auto
			if is_instance_valid(growth_spin):
				growth_spin.value = prev_growth
			_show_accept_only_dialog(panel, "保存失败", str(api_result.get("error", "云端同步失败，请稍后重试。")))
			return
		toggle.button_pressed = game_manager.auto_capture_enabled
		growth_spin.value = game_manager.min_growth_threshold
		_show_accept_only_dialog(panel, "保存成功", "设置已同步\n自动捕捉设置已写入云端。")
	)
	_add_centered_settings_button(scroll_content, save_btn)

static func _show_help_view_fullscreen(panel: Control):
	_clear_content_fullscreen(panel)
	var scroll_content = panel.get_meta("scroll_content") as VBoxContainer

	if not scroll_content:
		return

	var help_title = Label.new()
	help_title.text = "新手玩法指引"
	help_title.add_theme_font_size_override("font_size", 22)
	help_title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	scroll_content.add_child(help_title)

	var help_text = RichTextLabel.new()
	help_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	help_text.bbcode_enabled = true
	help_text.add_theme_font_size_override("normal_font_size", 15)
	help_text.custom_minimum_size = Vector2(0, 4200)
	help_text.text = "[color=yellow]═══════════════════════════════════[/color]\n[color=yellow]        幻灵归虚 - 新手玩法指引[/color]\n[color=yellow]═══════════════════════════════════[/color]\n\n[color=orange]目录[/color]\n一、游戏简介    二、角色系统    三、战斗系统\n四、宠物系统    五、装备系统    六、套装副本\n七、天关挑战    八、五行副本    九、藏宝洞\n十、境界与飞升  十一、武功系统  十二、离线与经验\n十三、元宝与贵族 十四、资源道具  十五、仙魔战场\n十六、新手建议  十七、异常排查\n\n═══════════════════════════════════\n[color=orange]一、游戏简介[/color]\n═══════════════════════════════════\n\n《幻灵归虚》是一款放置类修仙手游，玩家通过战斗、养成、挑战副本等方式提升实力。\n\n[color=cyan]核心玩法循环[/color]\n野外战斗 → 获得经验、金币、装备 → 提升等级和实力\n    ↓\n挑战天关/副本 → 获得稀有奖励、宠物蛋、礼包\n    ↓\n捕捉培养宠物 → 炼化、进化、学习技能 → 增强战斗力\n    ↓\n飞升转世 → 突破境界限制 → 获得永久属性\n\n═══════════════════════════════════\n[color=orange]二、角色系统[/color]\n═══════════════════════════════════\n\n[color=cyan]基础属性[/color]\n\n属性      说明          初始值    成长方式\n─────────────────────────────────────\n等级      角色等级      1级      获得经验升级\n生命(HP)  生命值        100      升级、体质加点、装备\n内力(MP)  内力值        100      升级、灵力加点、装备\n攻击      攻击力        10       升级、力量加点、装备\n防御      防御力        10       升级、耐力加点、装备\n敏捷      敏捷值        10       升级、敏捷加点、装备\n修行值    角色修行      0        使用修行丹药、飞升\n\n[color=cyan]属性点分配[/color]\n\n每级获得的属性点数根据境界不同：\n• 凡人、散仙：每级3点\n• 地仙、天仙：每级4点\n• 大罗金仙、幻灵天神：每级5点\n\n可自由分配到以下属性：\n• 体质：每点+10生命\n• 力量：每点+1攻击\n• 耐力：每点+1防御\n• 敏捷：每点+1敏捷\n• 灵力：每点+5内力\n\n═══════════════════════════════════\n[color=orange]三、战斗系统[/color]\n═══════════════════════════════════\n\n[color=cyan]战斗流程[/color]\n\n1. 野外地图自动遭遇怪物，进入回合制战斗\n2. 按敏捷排序依次行动（怪物连续段合并为1秒窗口）\n3. 击败所有怪物或达到回合上限则战斗结束\n4. 野外最大10回合，天关30回合，副本20-30回合\n\n[color=cyan]连击机制[/color]\n\n条件：玩家和宠物的敏捷都[color=gold]高于[/color]所有敌人\n效果：人物出手后宠物紧跟一次追加攻击，全段必中\n\n[color=cyan]合击机制[/color]\n\n条件：玩家和宠物的敏捷都[color=gold]低于[/color]目标怪物\n效果：人物和宠物联手攻击同一目标，[color=gold]100%命中[/color]\n注意：触发合击时宠物不会再独立行动，只在人物回合一起出手\n\n[color=cyan]伤害计算[/color]\n\n[color=gold]野外打怪、天关等：[/color]\n基础伤害 = 攻击方攻击 - 防御方防御/2\n实际伤害 = max(1, 基础伤害) × 随机系数(0.8~1.2) × 五行克制倍率\n有克制/被克时，宠物再乘魂魄加成。贵族已含在出战宠的攻击、防御、敏捷里，不再另乘伤害\n\n[color=gold]PVP（竞技场、藏宝洞、仙魔、帮派战、领地战）：[/color]\n克制只改出手攻击，对方防御不变，攻守双方魂魄参与后再算攻防差\n克制：攻击 ×（克制基数 ×（1＋攻方魂魄%）－守方魂魄%），最低保底×1（守方魂魄可抵消加成，不能把克制扣成弱势）\n被克：攻击 × clamp(被克基数＋攻方魂魄%－守方魂魄%, 0%~100%)（攻方抵消减伤，守方反抵消；最高打平，不能翻成克制）\n然后：新攻击 − 原防御/2，再乘随机(0.8~1.2)。贵族已含在出战宠攻防敏里，不再另乘伤害\n\n[color=cyan]五行相克[/color]\n\n五行    克制    被克制\n─────────────────────\n金      木      火\n木      土      金\n土      水      木\n水      火      土\n火      金      水\n\n天系：克制金/木/水/火/土（加伤）；被五系攻击时减伤；天对天互不克制\n天系宠魂魄：有克制时按「克制目标」的那一系取加成（例：打金吃火魂魄）\n\n进化宠/人物：克制+30% / 被克-30%\n不可进化宠：克制+50% / 被克-50%\n\n═══════════════════════════════════\n[color=orange]四、宠物系统[/color]\n═══════════════════════════════════\n\n[color=cyan]宠物类型[/color]\n\n类型          特点                    最大等级\n─────────────────────────────────────────\n可进化宠物    可进化3次，成长高        1200级\n不可进化宠物  无法进化，成长稳定       1500级\n\n[color=cyan]宠物获取途径[/color]\n\n• 野外战斗自动捕捉（需开启自动捕捉）\n• 宠物蛋孵化（5+宠物蛋、五行属性宠物蛋）\n• 宠物礼包开启（6+~12+可进化/不可进化宠礼包、仙魔礼包等）\n• 乾坤炉炼化（见下方）\n• 离线宠物礼包、天关礼包等\n• 支持[color=gold]批量使用[/color]宠物蛋和礼包\n\n[color=cyan]宠物成长系统[/color]\n\n宠物属性 = 基础属性 + (等级-1) × 成长值\n每次升级随机获得成长增量，受世代和血统种子成长影响\n满级（1200/1500）后不再升级\n\n[color=cyan]宠物类型与成长倾向[/color]\n\n类型      攻击成长    防御成长    敏捷成长    特点\n─────────────────────────────────────────────────\n攻击型      高          中          低      攻击突出\n防御型      低          高          中      防御突出\n敏捷型      中          低          高      敏捷突出\n平衡型      中          中          中      属性均衡\n生命型      中          中          中      生命值高\n\n[color=cyan]宠物升级丹[/color]\n\n• 使用后出战宠物[color=gold]直接升至满级[/color]，并计算成长\n• 需联网使用，服务端权威结算\n• 使用前会自动同步出战宠物状态\n• 换宠后请确认同步完成再使用\n\n[color=cyan]宠物技能系统[/color]\n\n• 宠物可学习技能书（溅射、连射、反击、神佑等）\n• 技能书需联网使用，服务端权威\n• 每只宠物最多4个技能槽位\n• 技能可升级（消耗同技能书），最高3级\n\n[color=cyan]宠物勋章[/color]\n\n• 未转生宠物：每个形态从不满级再次冲到满级时，可获得 1 枚随机满级勋章（勇猛/冷静/果敢）\n• 每次进化成功也会随机获得 1 枚勋章（与满级章分开）\n• 已转生宠物满级不再发放满级勋章\n• 宠物补章器：在背包中使用，为出战宠物随机补一枚勋章（每种最多 5，合计最多 15）\n\n[color=cyan]宠物装备[/color]\n\n• 宠物可穿戴专属装备（头、胸、腿、饰、武）\n• 宠物装备仓库上限：背包10件，仓库100件\n• 宠物装备可强化、分解\n\n[color=cyan]宠物魂魄[/color]\n\n• 炼化/开蛋获得的宠物可投入魂魄，为出战宠物提供属性加成\n• 魂魄投入消耗金币\n\n[color=cyan]乾坤炉·宠物炼化[/color]\n\n• 入口：主城乾坤炉\n• 放入8只[color=gold]1级、0代[/color]宠物；可进化宠须为幼年形态\n• 每次消耗[color=gold]1000万金币[/color]\n• 新宠物[color=gold]成长[/color] = 八只材料宠总成长的平均值\n• 种类按三池概率随机：[color=gold]普通池80% / 稀有池18% / 极稀有池2%[/color]\n\n[color=cyan]统一宠物池[/color]\n\n以下玩法共用同一套三池权重抽取宠物种类：\n• 乾坤炉炼化 • 五行属性宠物蛋 • 5+宠物蛋 • 仙魔宠物礼包\n\n成长区间（以实际开出为准）：\n• 五行属性宠物蛋：约4.0~7.0  • 5+宠物蛋：约5.0~6.0\n• 仙魔礼包：见礼包说明\n\n═══════════════════════════════════\n[color=orange]五、装备系统[/color]\n═══════════════════════════════════\n\n[color=cyan]人物装备部位[/color]\n\n部位    主要属性    说明\n─────────────────────────\n武器    攻击        提升攻击力\n头盔    生命        提升生命值\n衣服    防御        提升防御力\n鞋子    敏捷        提升敏捷值\n饰品    内力        提升内力值\n\n[color=cyan]装备品质[/color]\n\n品质    颜色    属性倍率\n─────────────────────────\n普通    白色    1.0倍\n优秀    绿色    1.5倍\n稀有    蓝色    2.0倍\n史诗    紫色    3.0倍\n传说    橙色    4.0倍\n神话    红色    5.0倍\n至尊    金色    6.25倍\n\n[color=cyan]装备获取[/color]\n\n• 野外战斗掉落普通~史诗装备\n• 乾坤炉套装转换：3件同名已解封、未强化、未锁定套装，随机换成1件同名新套装\n• 套装副本：掉落封印套装（需解封）\n• 内测先锋/开荒等礼包\n\n[color=cyan]装备仓库[/color]\n\n• 人物装备背包上限：15件\n• 背包满后新装备自动存入仓库\n\n═══════════════════════════════════\n[color=orange]六、套装副本系统[/color]\n═══════════════════════════════════\n\n[color=cyan]系统简介[/color]\n\n套装副本共21层，每层对应一套套装，是获取强力套装的主要途径。\n\n[color=cyan]封印套装[/color]\n\n• 掉落：封印套装各部位掉率5%，解封石5%\n• 解封：消耗1颗解封石+1000万金币，成功率50%\n• 解封石：普通解封石（1-10层）、高级解封石（11-21层）\n• 解封后属性有±10%波动\n\n[color=cyan]套装属性加成[/color]\n\n集齐5件套激活套装加成：攻击/防御/敏捷/生命/内力各+30%（基于套装基础值）\n\n[color=cyan]扫荡功能[/color]\n\n• 普通玩家每日3次，VIP玩家5次\n• 扫荡奖励：金币+概率掉落封印套装和解封石（需已通关该层）\n\n═══════════════════════════════════\n[color=orange]七、天关挑战[/color]\n═══════════════════════════════════\n\n[color=cyan]系统简介[/color]\n\n天关为高层闯关玩法，可达[color=gold]2000层[/color]，每层有强大守卫。\n\n[color=cyan]挑战规则[/color]\n\n• 消耗：100万金币/次\n• 回合限制：30回合\n• 已通关层可扫荡\n\n[color=cyan]天关奖励[/color]\n\n• 普通层：经验、金币\n• 每10层BOSS：天关礼包\n• 100层倍数：对应百关里程碑礼包（100关礼包~2000关礼包）\n• 天关礼包可开出5+宠物蛋、五行属性宠物蛋、琳琳、纹地龙等\n\n═══════════════════════════════════\n[color=orange]八、五行副本[/color]\n═══════════════════════════════════\n\n[color=cyan]系统简介[/color]\n\n五行副本按金/木/水/火/土分为五种元素关卡，每种元素有简单/普通/困难三个难度。\n\n[color=cyan]挑战规则[/color]\n\n• 每日免费挑战次数有限，可消耗[color=gold]元宝（100元宝/次）[/color]购买额外次数\n• 元宝挑战每日限1次\n• 每波多只怪物，共多波，回合限制30回合\n• 通关后根据难度发放奖励（包含稀有宠物蛋、技能书等）\n\n[color=cyan]副本奖励[/color]\n\n奖励包括：金宠物转生令牌、金变异宠物蛋、极限装备、金币、技能书等\n具体掉率以游戏内实际为准\n\n═══════════════════════════════════\n[color=orange]九、藏宝洞[/color]\n═══════════════════════════════════\n\n[color=cyan]系统简介[/color]\n\n藏宝洞为PVP夺宝玩法，玩家报名后通过服务端镜像模拟战斗决出名次。\n\n[color=cyan]参与规则[/color]\n\n• 报名消耗金币（随轮次递增）\n• 每轮多件宝箱，每件宝箱由多名玩家争夺\n• 战斗由服务端模拟结算，使用玩家和宠物的镜像数据\n• 克制与魂魄按 PVP 公式（只改攻击、防御不变再算伤害；攻守双方魂魄可抵消与反抵消）\n• 排名靠前者获得宝箱奖励\n\n[color=cyan]宝箱奖励[/color]\n\n• 青铜/白银/黄金宝箱，内含随机道具奖励\n• 战斗过程可在游戏内查看回放日志\n\n═══════════════════════════════════\n[color=orange]十、境界与飞升[/color]\n═══════════════════════════════════\n\n[color=cyan]境界系统[/color]\n\n境界        等级要求    修行要求\n─────────────────────────────────\n凡人        初始        -\n散仙        800级       -\n地仙        800级       5,000\n天仙        1000级      50,000\n大罗金仙    1000级      100,000\n幻灵天神    1000级      200,000\n\n[color=cyan]飞升[/color]\n\n• 达到条件后点击\"飞升\"突破，等级重置为1级；已分配的五维属性点清零，仅保留投胎累计的永久属性点并重新分配；装备保留\n• 每次飞升后属性点分配上限提高\n\n[color=cyan]转世（投胎）[/color]\n\n• 最大转世次数：2000次\n• 第1～999次每次获得[color=gold]25点永久属性点[/color]；第1000次及以后每次[color=gold]10点[/color]（已分配属性清零，永久点保留并重新分配）\n• 投胎≥500且为50的倍数（500/550/600…）各获1点天赋；天赋只加成出战宠攻防敏血（每项最多30点），洗点每次100元宝\n• 转世后保留所有装备和宠物\n• 转世重置悟道仙丹使用次数（每世最多5颗）\n\n[color=cyan]修行值[/color]\n\n• 修行值来源：使用修行丹药（聚灵丹+100、凝神丹+200、悟道仙丹+500）\n• 飞升时需要满足修行值要求\n• 悟道仙丹每世限用[color=gold]5颗[/color]，投胎后重置\n\n═══════════════════════════════════\n[color=orange]十一、武功系统[/color]\n═══════════════════════════════════\n\n[color=cyan]系统简介[/color]\n\n武功（Martial Arts）为角色提供属性加成。\n\n[color=cyan]武功类型[/color]\n\n• 攻击型：加成攻击力\n• 防御型：加成防御力\n• 敏捷型：加成敏捷值\n• 生命型：加成生命值\n• 内力型：加成内力值\n\n[color=cyan]武功品质[/color]\n\n与装备品质一致：普通→优秀→稀有→史诗→传说→神话→至尊\n\n实际属性 = (基础属性 + 装备属性) × (1 + 武功加成%)\n\n═══════════════════════════════════\n[color=orange]十二、离线与经验[/color]\n═══════════════════════════════════\n\n[color=cyan]离线挂机[/color]\n\n• 离线奖励按你下线时所在野外地图结算，和在线自动打野同一套节奏\n• 服务端会按该图刷怪，并用你已装备的武功、出战宠技能做多场模拟：人宠打完后，同一回合里该出手的怪一起算约 1 秒\n• 用平均一场时间和平均经验/金币，再按离线时长折算场次（VIP 仍限制最长离线小时）\n• 每一场按野外追赶规则入账：一场最多连升规定级数，升满后多出的经验清零，不能攒到下一场\n• 重新上线时自动领取；VIP、双倍经验、新人加成、帮派加成仍会叠在每场经验上\n\n[color=cyan]双倍经验[/color]\n\n• 使用双倍经验丹激活双倍经验\n• 双倍经验丹(日)：24小时\n• 双倍经验丹(周)：7天\n• 双倍经验丹(月)：30天\n• 可叠加使用延长有效期，支持批量使用\n• 双倍经验期间[color=gold]野外战斗和离线经验翻倍[/color]\n\n[color=cyan]新人经验加成[/color]\n\n• 自账号注册起 10 天内生效\n• 野外战斗与离线挂机的人物/宠物经验加算 +100%\n• 与 VIP、双倍经验丹、帮派经验加成加算叠加\n• 任务领奖不加此加成\n\n[color=cyan]投胎追赶（野外连升）[/color]\n\n• 由管理后台开关控制，关闭时野外和离线折算的每一场仍只升 1 级\n• 打开后，按与全服投胎第一名的差距决定一场最多连升几级（档位后台可改）\n• 升满当场允许的级数后，多出来的经验清零，不能攒到下场（在线野外与离线折算场次相同）\n• 飞升/投胎回 1 级不影响；只看投胎次数差距\n• 与上面的 10 天经验加成是两套，可同时有\n\n[color=cyan]离线宠物礼包[/color]\n\n• 离线奖励中可能包含离线宠物礼包\n• 在背包中使用，按当前地图奖池开出宠物\n\n═══════════════════════════════════\n[color=orange]十三、元宝与贵族[/color]\n═══════════════════════════════════\n\n[color=cyan]元宝系统[/color]\n\n• 元宝可通过活动、贵族每日领取等方式获得\n• 用途：商城购买道具、五行副本额外挑战等\n• 元宝商店商品：开荒礼包、悟道仙丹礼包、宠物升级丹、双倍经验丹、6+~8+可进化/不可进化宠礼包、宠物补章器等\n\n[color=cyan]元宝抽奖[/color]\n\n• 消耗元宝进行抽奖，可获得变异阿努、金币、极限装备、五行属性宠物蛋、7+可进化宠礼包等\n\n[color=cyan]贵族系统（VIP）[/color]\n\n• 贵族等级1~3，享受多项特权\n• 每日可领取元宝（等级越高越多）\n• 经验加成、离线收益提升\n• 额外天关/套装副本扫荡次数\n• 出战宠物攻防敏加成（与图鉴等加算，不加血）\n• 聊天频道VIP标识\n\n═══════════════════════════════════\n[color=orange]十四、资源道具[/color]\n═══════════════════════════════════\n\n[color=cyan]金币获取[/color]\n\n来源          数量\n─────────────────────\n野外战斗      少量\n出售装备      中等\n天关挑战      大量\n套装副本      大量\n大佬金币袋    10万/袋\n\n[color=cyan]修行丹药[/color]\n\n丹药        修行值    每世限用  来源\n─────────────────────────────────────\n聚灵丹      +100      无限制    打造、掉落\n凝神丹      +200      无限制    打造、掉落\n悟道仙丹    +500      5颗       仙魔、任务、活动\n\n[color=cyan]宠物相关道具[/color]\n\n道具            用途\n─────────────────────────────\n宠物升级丹      出战宠物直升满级\n宠物补章器      随机补一枚未获得的勋章\n5+宠物蛋        随机孵化5.0~6.0成长宠物\n五行属性宠物蛋  指定元素随机孵化4.0~7.0成长宠物\n宠物技能书      为宠物学习/升级技能\n离线宠物礼包    按地图奖池开出宠物\n宠装强化石      强化宠物装备\n宠装碎片        合成宠物装备\n\n[color=cyan]金币袋（大佬赞助）[/color]\n\n• 醉剑、神的遗愿、风歌夜曲、摆烂松、人间大炮、我的理想、板砖、立羽、铭大大、长空秋雁、大橘大利、人间事、思念\n• 每个10万金币，野外战斗掉落\n\n═══════════════════════════════════\n[color=orange]十五、仙魔战场[/color]\n═══════════════════════════════════\n\n[color=cyan]参与[/color]\n\n• 入口：主城仙魔战场（需满足修行条件）\n• 加入仙道/魔道阵营后可使用行动力探险\n• 战斗、宝物、灵兽等随机事件\n• 对战按 PVP 克制公式结算（与野外打怪不同，详见「伤害计算」）\n\n[color=cyan]行动力[/color]\n\n• 上限：普通玩家24点，VIP玩家48点\n• 随时间恢复，VIP恢复更快\n• 每次探险消耗1点\n\n[color=cyan]奖励[/color]\n\n• 仙魔灵兽/神兽/变异/野生礼包：背包中使用，遵循统一宠物池\n• 仙魔宝箱：存入宝箱栏，开启后获得随机道具\n• 周结算积分排名，发放称号和奖励\n\n═══════════════════════════════════\n[color=orange]十六、新手建议[/color]\n═══════════════════════════════════\n\n[color=cyan]前期（1-800级）[/color]\n\n1. 挂机升级，尽快达到800级准备飞升\n2. 捕捉宠物，尽早获得高成长宠物（20+成长）\n3. 每日挑战天关，获取金币和礼包\n4. 用野外掉落装备过渡\n5. 攒金币为炼化做准备\n\n[color=cyan]中期（散仙-地仙）[/color]\n\n1. 攻略套装副本，收集套装\n2. 培养主力宠物至满级\n3. 开始使用宠物蛋和礼包，注意统一宠物池机制\n4. 乾坤炉炼化获取更优宠物\n5. 提升境界至地仙\n\n[color=cyan]后期（天仙及以上）[/color]\n\n1. 追求高成长宠物（30+）和神话/至尊装备\n2. 挑战高层天关和五行副本高难度\n3. 参与藏宝洞PvP\n4. 为宠物学习技能、穿戴装备\n5. 累积元宝和贵族等级\n\n═══════════════════════════════════\n[color=orange]十七、异常排查[/color]\n═══════════════════════════════════\n\n[color=cyan]更新后仍像旧版 / 界面错乱 / 功能偶发异常[/color]\n\n1. 打开【设置】→【存档】→【清除本地缓存并重新登录】\n2. 不会删除云端存档和角色数据\n3. 网络正常时，建议先点【上传存档到服务器】再清除\n4. 若清除了热更补丁，游戏会自动重启；重启后重新登录即可\n\n[color=cyan]说明[/color]\n\n• 本功能只清理本地临时缓存（如热更补丁、公告游标等）\n• 不会清理待上传队列、本地加密存档、账号密码与未领取邮件"






























































































































































































































































































































































































































































































































































	scroll_content.add_child(help_text)

static func _show_debug_view_fullscreen(panel: Control):
	_clear_content_fullscreen(panel)
	var scroll_content = panel.get_meta("scroll_content") as VBoxContainer
	var game_manager = panel.get_meta("game_manager")

	if not scroll_content or not game_manager:
		return

	var debug_title = Label.new()
	debug_title.text = "调试功能"
	debug_title.add_theme_font_size_override("font_size", 22)
	debug_title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	scroll_content.add_child(debug_title)

	var btn_data = [
		["+1000 经验", func(): _on_debug_exp(game_manager)], 
		["+10000 金币", func(): _on_debug_gold(game_manager)], 
		["满血满蓝", func(): _on_debug_heal(game_manager)], 
		["+400 等级", func(): _on_debug_level_up(game_manager)], 
		["获得随机装备", func(): _on_debug_random_equipment(game_manager)], 
		["获得随机武功", func(): _on_debug_random_martial_pressed(game_manager)], 
		["+1万修行值", func(): _on_debug_cultivation(game_manager)], 
		["获得指定套装", func(): _on_debug_get_suit(game_manager)], 
		["宠物图鉴全满", func(): _on_debug_max_pet_collection(game_manager)], 
		["进化宠等级归1", func(): _on_debug_reset_evolved_pet_levels(game_manager)]
	]

	for data in btn_data:
		var btn = Button.new()
		btn.text = data[0]
		btn.custom_minimum_size = Vector2(0, 50)
		btn.add_theme_font_size_override("font_size", 20)
		btn.pressed.connect(data[1])
		scroll_content.add_child(btn)

static func _upload_save_to_server(game_manager):
	if not game_manager:
		return
	game_manager.upload_cloud_save(true)

## 一次性修复：把「已经进化过、但等级没被重置」的宠物拉回 1 级。
## 服务端 /pet/evolve 从不重置等级，所以修复前进化的宠物都停在高等级；
## 这条规则补齐之后，用这里统一收拾一遍历史数据。
static func _on_debug_reset_evolved_pet_levels(game_manager):
	if not game_manager or not game_manager.pet_manager:
		return
	var pm = game_manager.pet_manager
	var fixed: = 0
	for i in range(pm.get_pet_count()):
		var pet = pm.get_pet(i)
		if pet == null:
			continue
		# 只有真正进化过的宠物才该归 1（evolution_stage > 0）；
		# 不可进化 / 幼年 的宠物资质再高也跟这条规则无关，别误伤。
		if int(pet.evolution_stage) <= 0:
			continue
		if int(pet.level) <= 1:
			continue
		print("[调试] 进化宠归1：%s Lv.%d → Lv.1" % [pet.pet_name, int(pet.level)])
		pet.level = 1
		pet.experience = 0
		pm._update_pet_stats(pet)
		fixed += 1
	if fixed > 0:
		pm.pet_list_changed.emit()
	print("[调试] 共修复 %d 只已进化宠物的等级" % fixed)
	game_manager.save_game(true)

static func _remove_quit_sync_wait_layer(panel: Control) -> void :
	if not is_instance_valid(panel) or not panel.has_meta("_quit_sync_wait_layer"):
		return
	var layer = panel.get_meta("_quit_sync_wait_layer")
	panel.remove_meta("_quit_sync_wait_layer")
	if is_instance_valid(layer):
		layer.queue_free()

static func _show_quit_sync_wait_layer(panel: Control) -> void :
	if not is_instance_valid(panel):
		return
	_remove_quit_sync_wait_layer(panel)
	var layer: = CanvasLayer.new()
	layer.layer = 120
	var dim: = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.64)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(dim)
	var cc: = CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(cc)
	var lbl: = Label.new()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
	cc.add_child(lbl)
	var base: = "正在保存并同步云端存档"
	lbl.text = base
	var timer: = Timer.new()
	timer.wait_time = 0.42
	timer.autostart = true
	timer.one_shot = false
	var dots: = 0
	timer.timeout.connect( func():
		dots = (dots + 1) % 4
		lbl.text = base + ".".repeat(dots)
	)
	layer.add_child(timer)
	panel.add_child(layer)
	panel.set_meta("_quit_sync_wait_layer", layer)

static func _show_accept_only_dialog(panel: Node, title: String, message: String, on_confirmed: Callable = Callable()) -> void :
	if panel == null or not is_instance_valid(panel):
		return
	var lines: = str(message).split("\n")
	var popup_width: int = 500
	var content_height: int = maxi(100, int(lines.size()) * 28)
	var popup_height: int = 180 + content_height

	var dlg: = Window.new()
	dlg.title = ""
	dlg.size = Vector2i(popup_width, popup_height)
	dlg.transparent = true
	dlg.borderless = true
	dlg.unresizable = true
	dlg.close_requested.connect( func(): if is_instance_valid(dlg): dlg.queue_free())
	panel.add_child(dlg)

	var main_panel: = Panel.new()
	main_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_panel.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	dlg.add_child(main_panel)

	var vbox: = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 25
	vbox.offset_top = 25
	vbox.offset_right = -25
	vbox.offset_bottom = -25
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	main_panel.add_child(vbox)

	var title_label: = Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(title_label)

	var scroll: = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var inner_vbox: = VBoxContainer.new()
	inner_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(inner_vbox)

	for line in lines:
		var line_label: = Label.new()
		line_label.text = line
		line_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		line_label.add_theme_font_size_override("font_size", 18)
		line_label.add_theme_color_override("font_color", Color(0.894, 0.864, 0.803))
		line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		inner_vbox.add_child(line_label)

	var btn_container: = CenterContainer.new()
	btn_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(btn_container)

	var ok_btn: = Button.new()
	ok_btn.text = "确定"
	UIStyle.style_popup_button(ok_btn, true)
	ok_btn.pressed.connect( func():
		if on_confirmed.is_valid():
			on_confirmed.call()
		if is_instance_valid(dlg):
			dlg.queue_free()
	)
	btn_container.add_child(ok_btn)

	dlg.popup_centered()
	UIStyle.animate_window_popup(dlg)

static func _style_popup_action_button(btn: Button, is_confirm: bool) -> void :
	UIStyle.style_popup_button(btn, is_confirm)

static func _show_confirm_dialog(
	panel: Control, 
	title: String, 
	message: String, 
	confirm_text: String, 
	cancel_text: String, 
	on_confirm: Callable, 
	on_cancel: Callable = Callable()
) -> void :
	if not is_instance_valid(panel):
		return
	var lines: = str(message).split("\n")
	var popup_width: int = 520
	var content_height: int = maxi(100, int(lines.size()) * 28)
	var popup_height: int = 210 + content_height

	var dlg: = Window.new()
	dlg.title = ""
	dlg.size = Vector2i(popup_width, popup_height)
	dlg.transparent = true
	dlg.borderless = true
	dlg.unresizable = true
	dlg.close_requested.connect( func():
		if on_cancel.is_valid():
			on_cancel.call()
		if is_instance_valid(dlg):
			dlg.queue_free()
	)
	panel.add_child(dlg)

	var main_panel: = Panel.new()
	main_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_panel.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	dlg.add_child(main_panel)

	var vbox: = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 25
	vbox.offset_top = 25
	vbox.offset_right = -25
	vbox.offset_bottom = -25
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	main_panel.add_child(vbox)

	var title_label: = Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(title_label)

	var scroll: = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var inner_vbox: = VBoxContainer.new()
	inner_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(inner_vbox)

	for line in lines:
		var line_label: = Label.new()
		line_label.text = line
		line_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		line_label.add_theme_font_size_override("font_size", 18)
		line_label.add_theme_color_override("font_color", Color(0.894, 0.864, 0.803))
		line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		inner_vbox.add_child(line_label)

	var btn_hbox: = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 24)
	btn_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(btn_hbox)

	var cancel_btn: = Button.new()
	cancel_btn.text = cancel_text
	cancel_btn.custom_minimum_size = Vector2(140, 50)
	cancel_btn.add_theme_font_size_override("font_size", 18)
	_style_popup_action_button(cancel_btn, false)
	cancel_btn.pressed.connect( func():
		if on_cancel.is_valid():
			on_cancel.call()
		if is_instance_valid(dlg):
			dlg.queue_free()
	)
	btn_hbox.add_child(cancel_btn)

	var confirm_btn: = Button.new()
	confirm_btn.text = confirm_text
	confirm_btn.custom_minimum_size = Vector2(140, 50)
	confirm_btn.add_theme_font_size_override("font_size", 18)
	_style_popup_action_button(confirm_btn, true)
	confirm_btn.pressed.connect( func():
		if on_confirm.is_valid():
			on_confirm.call()
		if is_instance_valid(dlg):
			dlg.queue_free()
	)
	btn_hbox.add_child(confirm_btn)

	dlg.popup_centered()
	UIStyle.animate_window_popup(dlg)

static func _show_confirm_clear_cache_dialog(panel: Control, on_confirm: Callable) -> void :
	_show_confirm_dialog(
		panel, 
		"清除本地缓存", 
		(
			"将清除热更补丁、界面缓存等本地临时数据。\n\n"
			+ "不会删除云端存档和角色数据。\n\n"
			+ "清除后需重新登录；若清除了热更补丁，游戏会自动重启。\n\n"
			+ "网络正常时，建议先点「上传存档到服务器」。"
		), 
		"确认清除", 
		"取消", 
		on_confirm
	)

static func _on_adjust_desktop_window_pressed(panel: Control) -> void :
	if not is_instance_valid(panel) or panel.get_tree() == null:
		return
	var main = panel.get_tree().root.get_node_or_null("Main")
	if main == null:
		main = panel.get_tree().current_scene
	if main == null or not main.has_method("fit_desktop_window_to_usable_screen"):
		_show_accept_only_dialog(panel, "调整窗口", "当前无法调整窗口。")
		return
	main.fit_desktop_window_to_usable_screen()
	_show_accept_only_dialog(panel, "调整窗口", "已把窗口缩到屏幕高度的九成以内并居中。下次启动会按这次的大小打开。")

static func _stop_upload_save_cooldown(panel: Control) -> void :
	if not is_instance_valid(panel) or not panel.has_meta("_upload_save_cooldown"):
		return
	var timer = panel.get_meta("_upload_save_cooldown")
	if timer is Timer and is_instance_valid(timer):
		(timer as Timer).stop()

static func _cache_clear_dialog_host(panel: Control) -> Node:
	var tree: = Engine.get_main_loop() as SceneTree
	if tree != null:
		var main: = tree.root.get_node_or_null("Main")
		if main != null and is_instance_valid(main):
			return main
		if tree.current_scene != null and is_instance_valid(tree.current_scene):
			return tree.current_scene
		return tree.root
	if is_instance_valid(panel):
		return panel
	return null

static func _on_clear_local_cache_pressed(panel: Control, game_manager) -> void :
	if not is_instance_valid(panel) or game_manager == null:
		return
	_show_confirm_clear_cache_dialog(panel, func():
		_execute_clear_local_cache(panel, game_manager)
	)

static func _execute_clear_local_cache(panel: Control, game_manager) -> void :
	if game_manager == null:
		return
	_stop_upload_save_cooldown(panel)
	var uid: = 0
	if game_manager.network:
		uid = int(game_manager.network.user_id)
		if game_manager.network.has_method("abandon_inflight_save_upload"):
			game_manager.network.abandon_inflight_save_upload()
	var result: Dictionary = LocalCacheManager.clear_safe_local_cache(uid)
	var patch_cleared: = bool(result.get("patch_cleared", false))
	var removed_count: = int(result.get("removed_count", 0))
	print("[设置] 已清除本地缓存 count=%d patch=%s" % [removed_count, patch_cleared])
	if patch_cleared:
		if game_manager.network and game_manager.network.has_method("resume_request_queue_if_idle"):
			game_manager.network.resume_request_queue_if_idle()
		var host: = _cache_clear_dialog_host(panel)
		_show_accept_only_dialog(
			host, 
			"缓存已清除", 
			"本地热更补丁已清除。\n\n游戏将重启以加载最新版本。\n\n您的云端存档不会受影响。", 
			func():
				var tree: = Engine.get_main_loop() as SceneTree
				if tree == null:
					return
				OS.set_restart_on_exit(true)
				tree.quit()
		)
		return
	game_manager.request_return_to_login()

static func _show_confirm_quit_dialog(panel: Control, message: String, on_quit: Callable, on_stay: Callable) -> void :
	_show_confirm_dialog(panel, "退出游戏", message, "仍要退出", "取消", on_quit, on_stay)

static func _on_quit_with_cloud_sync_pressed(panel: Control, game_manager, quit_btn: Button) -> void :
	if not is_instance_valid(panel) or not game_manager:
		return
	if panel.get_meta("_quit_sync_in_progress", false):
		return
	panel.set_meta("_quit_sync_in_progress", true)
	if quit_btn:
		quit_btn.disabled = true
	_show_quit_sync_wait_layer(panel)
	var gm = game_manager
	var done: = func(detail: String):
		panel.set_meta("_quit_sync_in_progress", false)
		_remove_quit_sync_wait_layer(panel)
		if quit_btn and is_instance_valid(quit_btn):
			quit_btn.disabled = false
		match detail:
			gm.QUIT_SYNC_SYNC_DONE, gm.QUIT_SYNC_LOCAL_ONLY:
				panel.get_tree().quit()
			gm.QUIT_SYNC_GATE_BLOCKED:
				quit_btn.disabled = true
				_show_confirm_quit_dialog(panel, 
					"尚未完成首次云端同步，无法上传完整存档。已保存本地进度。\n仍要退出游戏吗？", 
					func(): panel.get_tree().quit(), 
					func():
						if quit_btn and is_instance_valid(quit_btn):
							quit_btn.disabled = false
				)
			gm.QUIT_SYNC_UPLOAD_FAIL:
				quit_btn.disabled = true
				_show_confirm_quit_dialog(panel, 
					"云端同步失败（已保存本地）。\n仍要退出游戏吗？", 
					func(): panel.get_tree().quit(), 
					func():
						if quit_btn and is_instance_valid(quit_btn):
							quit_btn.disabled = false
				)
			gm.QUIT_SYNC_SAVE_FAIL:
				_show_accept_only_dialog(panel, "保存失败", "无法完成本地存档，请检查存储空间与权限后重试。")
			_:
				_show_accept_only_dialog(panel, "提示", "操作未完成，请稍后再试。")
	gm.quit_sync_finished.connect(done, CONNECT_ONE_SHOT)
	gm.perform_quit_cloud_sync()

static func _on_debug_exp(game_manager):
	game_manager.player.add_exp(1000)

static func _on_debug_gold(game_manager):
	game_manager.player.gold += 10000

static func _on_debug_heal(game_manager):
	game_manager.player.hp = game_manager.player.get_max_hp()
	game_manager.player.mp = game_manager.player.get_max_mp()

static func _on_debug_level_up(game_manager):
	var player = game_manager.player
	var GameData = preload("res://scripts/game_data.gd")
	var actual_player_levels = min(400, GameData.MAX_LEVEL_EVOLUTION - player.level)
	player.level += actual_player_levels
	player.points += actual_player_levels * 4
	player.hp = player.get_max_hp()
	player.mp = player.get_max_mp()

	var pet_manager = game_manager.pet_manager
	var has_pet_changed = false
	for i in range(pet_manager.get_pet_count()):
		var pet = pet_manager.get_pet(i)
		if pet == null:
			continue
		var pet_result = pet_manager.debug_level_up_pet_fast(pet, 400)
		if pet_result.leveled_up:
			has_pet_changed = true

	if has_pet_changed:

		pet_manager.pet_list_changed.emit()

	print("[调试] 人物和所有宠物等级+%d, 获得%d点属性点!" % [actual_player_levels, actual_player_levels * 4])

static func _on_debug_random_martial_pressed(game_manager):
	if not game_manager or not game_manager.martial_arts_manager or not game_manager.player:
		return

	game_manager.martial_arts_manager.learn_martial_art(game_manager.player.realm)

static func _on_debug_random_equipment(game_manager):
	if game_manager.equipment_manager:
		var equipment = game_manager.equipment_manager.roll_equipment_drop(game_manager.player.cultivation, game_manager.player.realm)
		if equipment:
			game_manager.equipment_manager.add_to_inventory(equipment)
			print("[调试] 获得装备: %s" % equipment.name)
		else:
			print("[调试] 未获得装备（掉落概率）")

static func _on_debug_cultivation(game_manager):
	game_manager.player.cultivation += 10000
	print("[调试] 修行值增加1万！当前修行值：%d" % game_manager.player.cultivation)

static func _on_debug_get_suit(game_manager):
	_show_suit_select_dialog(game_manager)

static func _show_suit_select_dialog(game_manager):
	var dialog = Panel.new()
	dialog.set_anchors_preset(Control.PRESET_CENTER)
	dialog.custom_minimum_size = Vector2(350, 280)
	dialog.add_theme_stylebox_override("panel", UIStyle.create_panel_style())

	var tree = game_manager.get_tree()
	tree.current_scene.add_child(dialog)
	var viewport_size = tree.root.get_visible_rect().size
	dialog.position = (viewport_size - dialog.custom_minimum_size) / 2

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 15)
	dialog.add_child(vbox)

	var title = Label.new()
	title.text = "选择要获得的套装 (1-20)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(title)


	var option_btn = OptionButton.new()
	option_btn.custom_minimum_size = Vector2(0, 40)
	var SuitDatabaseDetailed = load("res://scripts/data/suit_database_detailed.gd")
	for i in range(1, 21):
		var suit_data = SuitDatabaseDetailed.get_suit_data(i)
		option_btn.add_item("%d层 - %s" % [i, suit_data.name], i)
	option_btn.select(0)
	vbox.add_child(option_btn)


	var btn_hbox = HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(btn_hbox)

	var confirm_btn = Button.new()
	confirm_btn.text = "确认获得"
	confirm_btn.custom_minimum_size = Vector2(0, 45)
	confirm_btn.add_theme_font_size_override("font_size", 18)
	UIStyle.apply_action_button_style(confirm_btn)
	confirm_btn.pressed.connect( func():
		var selected_level = option_btn.get_selected_id()
		_give_suit_to_player(selected_level, game_manager)
		dialog.queue_free()
	)
	btn_hbox.add_child(confirm_btn)

	var cancel_btn = Button.new()
	cancel_btn.text = "取消"
	cancel_btn.custom_minimum_size = Vector2(0, 45)
	cancel_btn.add_theme_font_size_override("font_size", 18)
	cancel_btn.add_theme_color_override("font_color", Color(0.8, 0.5, 0.5))
	UIStyle.apply_action_button_style(cancel_btn)
	cancel_btn.pressed.connect( func(): dialog.queue_free())
	btn_hbox.add_child(cancel_btn)

static func _give_suit_to_player(suit_level: int, game_manager):
	var gained_items = []
	var slots = ["weapon", "helmet", "armor", "boots", "accessory"]

	if game_manager.equipment_manager:
		for slot in slots:
			var equipment = game_manager.equipment_manager.create_suit_equipment(suit_level, slot)
			if equipment:
				game_manager.equipment_manager.add_to_inventory(equipment)
				gained_items.append(equipment.name)

	print("[调试] 已获得套装Lv.%d 全套共%d件！" % [suit_level, gained_items.size()])

static func _on_debug_max_pet_collection(game_manager):
	if not game_manager or not game_manager.pet_collection_manager:
		print("[调试] 宠物图鉴管理器未初始化")
		return

	var collection_manager = game_manager.pet_collection_manager


	var result = collection_manager.debug_max_all_collections()

	print("[调试] 宠物图鉴已全部点满！")
	print("[调试] 共处理 %d 种宠物" % result.success_count)
	print("[调试] 当前总加成:")
	print("  - 攻击：%.2f%%" % (result.total_bonuses.attack * 100))
	print("  - 防御：%.2f%%" % (result.total_bonuses.defense * 100))
	print("  - 敏捷：%.2f%%" % (result.total_bonuses.agility * 100))
	print("  - 生命：%.2f%%" % (result.total_bonuses.hp * 100))

static func _stop_all_bgm(panel: Control):
	var tree = panel.get_tree()
	if tree:
		var root = tree.root
		for child in root.get_children():
			if child.has_method("stop_login_bgm"):
				child.stop_login_bgm()
