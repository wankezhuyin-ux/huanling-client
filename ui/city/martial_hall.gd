extends RefCounted

const UIStyle = preload("res://scripts/ui_style.gd")

const MARTIAL_CREATE_UI_WAIT_SEC: = 30
const MARTIAL_ICON_DIR: = "res://assets/martial/"
const MARTIAL_ICON_FALLBACK: = "res://assets/items/category/icon_martial_book.png"
const MARTIAL_ICON_DISPLAY_SIZE: = 72
static var _martial_icon_tex_cache: Dictionary = {}

static func _martial_icon_path(effect_type: String) -> String:
	var k: = String(effect_type).strip_edges()
	if k.is_empty():
		return MARTIAL_ICON_FALLBACK
	var path: = MARTIAL_ICON_DIR + "icon_%s.png" % k
	if ResourceLoader.exists(path) or FileAccess.file_exists(path):
		return path
	return MARTIAL_ICON_FALLBACK

static func _load_martial_icon_texture(effect_type: String) -> Texture2D:
	var path: = _martial_icon_path(effect_type)
	if _martial_icon_tex_cache.has(path):
		return _martial_icon_tex_cache[path]
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	elif FileAccess.file_exists(path):
		var img: = Image.load_from_file(ProjectSettings.globalize_path(path))
		if img != null and not img.is_empty():
			tex = ImageTexture.create_from_image(img)
	_martial_icon_tex_cache[path] = tex
	return tex

static func _create_martial_icon_rect(effect_type: String, size: int = MARTIAL_ICON_DISPLAY_SIZE) -> TextureRect:
	var icon: = TextureRect.new()
	icon.custom_minimum_size = Vector2(size, size)
	icon.size = Vector2(size, size)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = _load_martial_icon_texture(effect_type)
	return icon

static func _get_success_rate_percent(martial_manager) -> int:
	if martial_manager and martial_manager.has_method("get_server_martial_success_rate"):
		var rate: = float(martial_manager.get_server_martial_success_rate())
		return clampi(int(round(rate * 100.0)), 0, 100)
	return 30

static func _format_create_info_text(martial_manager, daily_limit: int, remaining: int, in_progress: bool = false) -> String:
	var rate_percent: = _get_success_rate_percent(martial_manager)
	if in_progress:
		return "每日可自创%d次，今日剩余：%d次（%d%%成功率）\n每次消耗：1,000,000金币\n\n正在参悟中，约%d秒后可查看结果。请保持在线" % [daily_limit, remaining, rate_percent, MARTIAL_CREATE_UI_WAIT_SEC]
	return "每日可自创%d次，今日剩余：%d次（%d%%成功率）\n每次消耗：1,000,000金币" % [daily_limit, remaining, rate_percent]

static func create_fullscreen(game_manager) -> Control:
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", UIStyle.create_panel_style())

	var vbox = UIStyle.create_base_vbox()
	panel.add_child(vbox)

	var title = UIStyle.create_title_label("武道馆")
	vbox.add_child(title)

	var info_label = Label.new()
	info_label.text = "自创武功，参悟武道"
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 16)
	info_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(info_label)

	panel.set_meta("game_manager", game_manager)

	var content_container = VBoxContainer.new()
	content_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_container.add_theme_constant_override("separation", 10)
	vbox.add_child(content_container)

	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.scroll_deadzone = 20
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.name = "ScrollContainer"
	content_container.add_child(scroll)

	var scroll_content = VBoxContainer.new()
	scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_content.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	scroll_content.offset_left = 10
	scroll_content.offset_top = 10
	scroll_content.offset_right = -10
	scroll_content.offset_bottom = -10
	scroll_content.add_theme_constant_override("separation", 15)
	scroll_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll_content.name = "ScrollContent"
	scroll.add_child(scroll_content)

	panel.set_meta("content_container", content_container)
	panel.set_meta("scroll_content", scroll_content)

	_build_martial_view_fullscreen(panel)
	game_manager.register_martial_hall_panel_for_create_ui(panel)
	sync_martial_create_controls_from_game_manager(panel, game_manager)

	return panel

static func _build_martial_view_fullscreen(panel: Control):
	var scroll_content = panel.get_meta("scroll_content") as VBoxContainer
	var game_manager = panel.get_meta("game_manager")

	if not game_manager or not game_manager.player:
		var no_player_label = Label.new()
		no_player_label.text = "无玩家数据"
		no_player_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		scroll_content.add_child(no_player_label)
		return

	var player = game_manager.player
	var martial_manager = game_manager.martial_arts_manager

	if not martial_manager:
		var error_label = Label.new()
		error_label.text = "武功系统未初始化"
		error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		scroll_content.add_child(error_label)
		return

	var create_section = _create_section_vbox("自创武功")
	scroll_content.add_child(create_section)

	var daily_limit = martial_manager.get_daily_create_limit()
	var remaining = martial_manager.get_remaining_create_count()
	var create_info = Label.new()
	create_info.name = "create_info"
	create_info.text = _format_create_info_text(martial_manager, daily_limit, remaining, false)
	create_info.add_theme_font_size_override("font_size", 16)
	create_info.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	create_section.add_child(create_info)

	var create_btn = Button.new()
	create_btn.name = "create_btn"
	create_btn.text = "⚔️ 开始自创武功"
	create_btn.custom_minimum_size = Vector2(220, 50)
	create_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	create_btn.add_theme_font_size_override("font_size", 20)
	UIStyle.apply_golden_button_style(create_btn)
	UIStyle.setup_button_animation(create_btn)

	if game_manager.network and game_manager.network.is_logged_in() and martial_manager.is_server_martial_count_ready() and remaining > 0:
		var tween = create_btn.create_tween()
		tween.set_loops()
		tween.tween_property(create_btn, "modulate", Color(1.15, 1.1, 0.9, 1), 0.8)
		tween.tween_property(create_btn, "modulate", Color(1, 1, 1, 1), 0.8)
		create_btn.set_meta("golden_tween", tween)

	if not game_manager.network or not game_manager.network.is_logged_in():
		create_btn.disabled = true
		create_btn.text = "登录后自创"
	elif not martial_manager.is_server_martial_count_ready():
		create_btn.disabled = true
		create_btn.text = "同步今日次数中..."
	elif remaining <= 0:
		create_btn.disabled = true
		create_btn.text = "今日次数已用完"

	create_btn.pressed.connect(game_manager.run_martial_hall_create_pressed_async.bind(panel, create_btn, create_info))
	create_section.add_child(create_btn)

	panel.set_meta("create_info", create_info)
	panel.set_meta("create_btn", create_btn)

	if game_manager.network and game_manager.network.is_logged_in():
		var on_daily_count_changed: = func(count: int, max_count: int) -> void :
			if not is_instance_valid(panel):
				return
			if panel.get_meta("martial_flow_active", false) or game_manager.martial_create_ui_flow_active():
				return
			if is_instance_valid(create_info):
				create_info.text = _format_create_info_text(martial_manager, max_count, max_count - count, false)
			if is_instance_valid(create_btn):
				if not martial_manager.is_server_martial_count_ready():
					create_btn.disabled = true
					create_btn.text = "无法同步今日次数"
				elif count >= max_count:
					create_btn.disabled = true
					create_btn.text = "今日次数已用完"
				else:
					create_btn.disabled = false
					create_btn.text = "⚔️ 开始自创武功"
		if panel.has_meta("martial_daily_count_handler"):
			var old_handler: Callable = panel.get_meta("martial_daily_count_handler")
			if martial_manager.daily_count_changed.is_connected(old_handler):
				martial_manager.daily_count_changed.disconnect(old_handler)
		panel.set_meta("martial_daily_count_handler", on_daily_count_changed)
		martial_manager.daily_count_changed.connect(on_daily_count_changed)
		martial_manager.refresh_server_count()

	var separator1 = HSeparator.new()
	scroll_content.add_child(separator1)

	var active_section = _create_section_vbox("⚡ 主动武功（最多1个）", true, true)
	scroll_content.add_child(active_section)
	var active_arts = martial_manager.get_equipped_active_arts()
	if active_arts.is_empty():
		active_section.add_child(_create_equipped_slot_placeholder("主动槽位 · 空"))
	else:
		for martial in active_arts:
			active_section.add_child(_create_martial_item_ui_fullscreen(panel, martial, true))

	var passive_section = _create_section_vbox("🛡 被动武功（最多3个）", true, false)
	scroll_content.add_child(passive_section)
	var passive_arts = martial_manager.get_equipped_passive_arts()
	var passive_slots: = 3
	for i in range(passive_slots):
		if i < passive_arts.size():
			passive_section.add_child(_create_martial_item_ui_fullscreen(panel, passive_arts[i], true))
		else:
			passive_section.add_child(_create_equipped_slot_placeholder("被动槽位 %d · 空" % (i + 1)))

	var separator2 = HSeparator.new()
	scroll_content.add_child(separator2)

	var martial_section = _create_section_vbox("📜 已学武功 (%d/%d)" % [martial_manager.martial_arts.size(), martial_manager.MAX_MARTIAL_ARTS], false)
	scroll_content.add_child(martial_section)

	if martial_manager.martial_arts.is_empty():
		martial_section.add_child(_create_placeholder_label("尚未学习武功"))
	else:
		for martial in martial_manager.martial_arts:
			martial_section.add_child(_create_martial_item_ui_fullscreen(panel, martial, false))

	_setup_mouse_filter(scroll_content)

static func _create_equipped_slot_placeholder(text: String) -> Panel:
	var slot_panel = Panel.new()
	slot_panel.custom_minimum_size = Vector2(0, 56)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.048, 0.057, 0.059, 0.5)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.655, 0.531, 0.245, 0.8)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	slot_panel.add_theme_stylebox_override("panel", style)
	var label = Label.new()
	label.text = text
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.631, 0.611, 0.564))
	slot_panel.add_child(label)
	return slot_panel

static func _martial_kind_label(martial) -> String:
	if martial == null:
		return ""
	if MartialArtsManager.is_active_effect_type(martial.effect_type):
		return "[主动]"
	return "[被动]"

static func _create_section_vbox(section_title: String, is_equipped_section: bool = false, is_active_slot_section: bool = false) -> VBoxContainer:
	var section_vbox = VBoxContainer.new()
	section_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	section_vbox.add_theme_constant_override("separation", 8)

	var title_panel = Panel.new()
	title_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_panel.custom_minimum_size = Vector2(0, 40)

	var title_style = StyleBoxFlat.new()
	if is_equipped_section:
		if is_active_slot_section:
			# 主动槽的"选中"提示：原来是一整条铜色块，压在墨底上像另一套皮。
			# 改成墨底 + 略亮金线，靠线的亮度区分层级。
			title_style.bg_color = Color(0.092, 0.076, 0.044, 0.95)
			title_style.border_color = Color(0.860, 0.712, 0.372, 1)
		else:
			title_style.bg_color = Color(0.066, 0.074, 0.074, 0.95)
			title_style.border_color = Color(0.841, 0.702, 0.380, 1)
		title_style.border_width_left = 1
		title_style.border_width_right = 1
		title_style.border_width_top = 1
		title_style.border_width_bottom = 1
	else:
		title_style.bg_color = Color(0.072, 0.080, 0.079, 0.8)
		title_style.border_width_left = 1
		title_style.border_width_right = 1
		title_style.border_width_top = 1
		title_style.border_width_bottom = 1
		title_style.border_color = Color(0.655, 0.531, 0.245, 0.8)
	title_style.corner_radius_top_left = 0
	title_style.corner_radius_top_right = 0
	title_style.corner_radius_bottom_left = 0
	title_style.corner_radius_bottom_right = 0
	title_panel.add_theme_stylebox_override("panel", title_style)
	section_vbox.add_child(title_panel)

	var title = Label.new()
	title.text = section_title
	title.set_anchors_preset(Control.PRESET_FULL_RECT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	if is_equipped_section:
		if is_active_slot_section:
			title.add_theme_color_override("font_color", Color(1, 0.85, 0.35))
		else:
			title.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
	else:
		title.add_theme_color_override("font_color", Color(0.842, 0.816, 0.756))
	title_panel.add_child(title)

	return section_vbox

static func _create_placeholder_label(text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	return label

static func _create_martial_item_ui_fullscreen(panel: Control, martial, is_equipped: bool = false) -> Panel:
	var game_manager = panel.get_meta("game_manager")

	var item_panel = Panel.new()
	item_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_panel.custom_minimum_size = Vector2(0, 110)
	item_panel.mouse_filter = Control.MOUSE_FILTER_PASS

	var style = StyleBoxFlat.new()
	if is_equipped:
		style.bg_color = Color(0.092, 0.076, 0.044, 0.92)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.8, 0.6, 0.2, 1)
	else:
		style.bg_color = Color(0.072, 0.080, 0.079, 0.6)
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.655, 0.531, 0.245, 0.8)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	item_panel.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 15
	hbox.offset_top = 8
	hbox.offset_right = -15
	hbox.offset_bottom = -8
	hbox.add_theme_constant_override("separation", 10)
	hbox.mouse_filter = Control.MOUSE_FILTER_PASS
	item_panel.add_child(hbox)

	var effect_type: = ""
	if martial != null and "effect_type" in martial:
		effect_type = str(martial.effect_type)
	hbox.add_child(_create_martial_icon_rect(effect_type))

	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 3)
	info_vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	hbox.add_child(info_vbox)

	var name_label = Label.new()
	name_label.text = "%s %s (第%d层)" % [_martial_kind_label(martial), martial.name, martial.layer]
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3) if is_equipped else Color(0.9, 0.6, 0.4))
	info_vbox.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = "%s | %s" % [martial.desc, martial.get_effect_description()]
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", Color(0.734, 0.714, 0.657))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_vbox.add_child(desc_label)

	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn_hbox.add_theme_constant_override("separation", 8)
	hbox.add_child(btn_hbox)

	if is_equipped:
		var unequip_btn = Button.new()
		unequip_btn.text = "卸下"
		unequip_btn.custom_minimum_size = Vector2(80, 40)
		unequip_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		unequip_btn.add_theme_font_size_override("font_size", 18)
		UIStyle.apply_button_style(unequip_btn)
		UIStyle.setup_button_animation(unequip_btn)
		var unequip_art_id: = str(martial.id)
		unequip_btn.pressed.connect( func():
			var live = game_manager.martial_arts_manager.get_martial_art_by_id(unequip_art_id)
			if live == null:
				_show_result_popup_fullscreen(panel, "提示", "", "武功状态已刷新，请重新打开武道馆")
				_refresh_martial_view_fullscreen(panel)
				return
			game_manager.martial_arts_manager.unequip_martial_art(live)
			_refresh_martial_view_fullscreen(panel)
		)
		btn_hbox.add_child(unequip_btn)
	else:
		if not martial.equipped:
			var equip_btn = Button.new()
			equip_btn.text = "装备"
			equip_btn.custom_minimum_size = Vector2(80, 40)
			equip_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			equip_btn.add_theme_font_size_override("font_size", 18)
			UIStyle.apply_golden_button_style(equip_btn)
			UIStyle.setup_button_animation(equip_btn)
			var equip_art_id: = str(martial.id)
			equip_btn.pressed.connect( func():
				var live = game_manager.martial_arts_manager.get_martial_art_by_id(equip_art_id)
				if live == null:
					_show_result_popup_fullscreen(panel, "提示", "", "武功状态已刷新，请重新打开武道馆")
					_refresh_martial_view_fullscreen(panel)
					return
				var reason: String = game_manager.martial_arts_manager.get_equip_reject_reason(live)
				if reason == "same_name":
					_show_result_popup_fullscreen(panel, "提示", "", "同一种武功只能装备一个！")
					return
				if reason == "same_effect_type":
					_show_result_popup_fullscreen(panel, "提示", "", "同类型武功只能装备一个！")
					return
				if reason == "active_full":
					_show_result_popup_fullscreen(panel, "提示", "", "主动武功槽已满，请先卸下！")
					return
				if reason == "passive_full":
					_show_result_popup_fullscreen(panel, "提示", "", "被动武功槽已满，最多装备3个！")
					return
				if reason == "已装备":
					_show_result_popup_fullscreen(panel, "提示", "", "该武功已装备")
					_refresh_martial_view_fullscreen(panel)
					return
				if reason == "武功不存在":
					_show_result_popup_fullscreen(panel, "提示", "", "武功状态已刷新，请重新打开武道馆")
					_refresh_martial_view_fullscreen(panel)
					return
				if not reason.is_empty():
					_show_result_popup_fullscreen(panel, "提示", "", "装备失败")
					return
				if game_manager.martial_arts_manager.equip_martial_art(live):
					_refresh_martial_view_fullscreen(panel)
				else:
					_show_result_popup_fullscreen(panel, "提示", "", "装备失败")
			)
			btn_hbox.add_child(equip_btn)

			var forget_btn = Button.new()
			forget_btn.text = "遗忘"
			forget_btn.custom_minimum_size = Vector2(80, 40)
			forget_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			forget_btn.add_theme_font_size_override("font_size", 18)
			UIStyle.apply_button_style(forget_btn)
			UIStyle.setup_button_animation(forget_btn)
			forget_btn.pressed.connect( func():
				_show_confirm_dialog_fullscreen(panel, "确认遗忘", "确定要遗忘武功「%s」吗？\n遗忘后将无法恢复！" % martial.name, func():
					var forget_art_id: = str(martial.id)
					var live = game_manager.martial_arts_manager.get_martial_art_by_id(forget_art_id)
					if live == null:
						_show_result_popup_fullscreen(panel, "提示", "", "武功状态已刷新，请重新打开武道馆")
						_refresh_martial_view_fullscreen(panel)
						return
					if game_manager.martial_arts_manager.forget_martial_art(live):
						if game_manager.has_method("save_martial_forget_to_cloud"):
							game_manager.save_martial_forget_to_cloud(forget_art_id)
					_refresh_martial_view_fullscreen(panel)
				)
			)
			btn_hbox.add_child(forget_btn)

	return item_panel

static func _refresh_martial_view_fullscreen(panel: Control):
	var scroll_content = panel.get_meta("scroll_content") as VBoxContainer
	for child in scroll_content.get_children():
		child.queue_free()
	_build_martial_view_fullscreen(panel)
	var gm = panel.get_meta("game_manager")
	if gm:
		gm.register_martial_hall_panel_for_create_ui(panel)
		sync_martial_create_controls_from_game_manager(panel, gm)


static func _show_result_popup_fullscreen(parent_control: Control, title: String, message: String, details: String, on_ok: Callable = Callable(), wait_until_closed: bool = false) -> void :

	for ch in parent_control.get_children():
		if ch.name == "MartialResultLayer":
			ch.queue_free()
	var layer = Control.new()
	layer.name = "MartialResultLayer"
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.z_index = 100
	parent_control.add_child(layer)

	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.5)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(dim)

	var popup = Panel.new()
	popup.set_anchors_preset(Control.PRESET_CENTER)
	popup.grow_horizontal = Control.GROW_DIRECTION_BOTH
	popup.grow_vertical = Control.GROW_DIRECTION_BOTH
	popup.custom_minimum_size = Vector2(450, 360)
	popup.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	layer.add_child(popup)
	var pw = parent_control.size.x
	var ph = parent_control.size.y
	if pw <= 0.0 or ph <= 0.0:
		pw = 720.0
		ph = 1280.0
	popup.position = Vector2((pw - 450.0) * 0.5, (ph - 360.0) * 0.5)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 25
	vbox.offset_top = 25
	vbox.offset_right = -25
	vbox.offset_bottom = -28
	vbox.add_theme_constant_override("separation", 14)
	popup.add_child(vbox)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)

	var content_width: = 400.0
	var title_label = Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.custom_minimum_size = Vector2(content_width, 0)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	content.add_child(title_label)

	if message != "":
		var msg_label = Label.new()
		msg_label.text = message
		msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		msg_label.custom_minimum_size = Vector2(content_width, 0)
		msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		msg_label.add_theme_font_size_override("font_size", 18)
		msg_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		content.add_child(msg_label)

	if details != "":
		var details_label = Label.new()
		details_label.text = details
		details_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		details_label.custom_minimum_size = Vector2(content_width, 0)
		details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		details_label.add_theme_font_size_override("font_size", 16)
		details_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		content.add_child(details_label)

	var ok_btn = Button.new()
	ok_btn.text = "确  定"
	ok_btn.custom_minimum_size = Vector2(120, 45)
	ok_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok_btn.add_theme_font_size_override("font_size", 18)
	UIStyle.apply_button_style(ok_btn)

	vbox.add_child(ok_btn)
	if wait_until_closed:
		var closed: = false
		ok_btn.pressed.connect( func():
			if on_ok.is_valid():
				on_ok.call()
			closed = true
			layer.queue_free()
		)
		while not closed and is_instance_valid(parent_control):
			await parent_control.get_tree().process_frame
	else:
		ok_btn.pressed.connect( func():
			if on_ok.is_valid():
				on_ok.call()
			layer.queue_free()
		)

static func _show_confirm_dialog_fullscreen(parent_control: Control, title: String, message: String, on_confirm: Callable):
	var popup = Panel.new()
	popup.set_anchors_preset(Control.PRESET_CENTER)
	popup.grow_horizontal = Control.GROW_DIRECTION_BOTH
	popup.grow_vertical = Control.GROW_DIRECTION_BOTH
	popup.custom_minimum_size = Vector2(400, 320)
	popup.add_theme_stylebox_override("panel", UIStyle.create_panel_style())
	parent_control.add_child(popup)
	popup.position = Vector2((parent_control.size.x - 400) / 2, (parent_control.size.y - 320) / 2)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 15)
	popup.add_child(vbox)

	var title_label = Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color(1, 0.5, 0.3))
	vbox.add_child(title_label)

	var msg_label = Label.new()
	msg_label.text = message
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.add_theme_font_size_override("font_size", 16)
	msg_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(msg_label)

	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_hbox)

	var cancel_btn = Button.new()
	cancel_btn.text = "取消"
	cancel_btn.custom_minimum_size = Vector2(100, 40)
	cancel_btn.add_theme_font_size_override("font_size", 16)
	UIStyle.apply_button_style(cancel_btn)
	cancel_btn.pressed.connect( func(): popup.queue_free())
	btn_hbox.add_child(cancel_btn)

	var confirm_btn = Button.new()
	confirm_btn.text = "确定"
	confirm_btn.custom_minimum_size = Vector2(100, 40)
	confirm_btn.add_theme_font_size_override("font_size", 16)
	UIStyle.apply_button_style(confirm_btn)
	confirm_btn.pressed.connect( func():
		popup.queue_free()
		on_confirm.call()
	)
	btn_hbox.add_child(confirm_btn)

static func _show_cultivation_animation_fullscreen(parent_control: Control) -> Panel:
	var popup = Panel.new()
	popup.set_anchors_preset(Control.PRESET_CENTER)
	popup.grow_horizontal = Control.GROW_DIRECTION_BOTH
	popup.grow_vertical = Control.GROW_DIRECTION_BOTH
	popup.custom_minimum_size = Vector2(300, 200)
	popup.add_theme_stylebox_override("panel", UIStyle.create_panel_style())
	parent_control.add_child(popup)
	popup.position = Vector2((parent_control.size.x - 300) / 2, (parent_control.size.y - 200) / 2)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	popup.add_child(vbox)

	var anim_label = Label.new()
	anim_label.text = "参悟中..."
	anim_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	anim_label.add_theme_font_size_override("font_size", 28)
	anim_label.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
	vbox.add_child(anim_label)

	var desc_label = Label.new()
	desc_label.text = "静心凝神，感悟天地灵气"
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 18)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(desc_label)

	popup.set_meta("anim_label", anim_label)
	popup.set_meta("desc_label", desc_label)

	return popup

static func _setup_mouse_filter(container: Control):
	for child in container.get_children():
		if child is Control:
			if child is Button:
				child.mouse_filter = Control.MOUSE_FILTER_STOP
			else:
				child.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if child is Container:
				_setup_mouse_filter(child)

static func _kill_create_btn_golden_tween(create_btn: Button) -> void :
	if create_btn.has_meta("golden_tween"):
		var tw = create_btn.get_meta("golden_tween")
		if tw is Tween and is_instance_valid(tw):
			tw.kill()
		create_btn.remove_meta("golden_tween")
	create_btn.modulate = Color.WHITE


static func _reset_martial_create_main_button_after_flow(panel: Control, game_manager, martial_manager) -> void :
	game_manager.martial_create_ui_flow_clear()
	if not is_instance_valid(panel):
		return
	for k in ["martial_flow_active", "martial_pending_view", "martial_create_snapshot"]:
		if panel.has_meta(k):
			panel.remove_meta(k)
	if not panel.has_meta("create_btn") or not panel.has_meta("create_info"):
		return
	var create_btn = panel.get_meta("create_btn") as Button
	var create_info = panel.get_meta("create_info") as Label
	if not is_instance_valid(create_btn) or not is_instance_valid(create_info):
		return
	_kill_create_btn_golden_tween(create_btn)
	var daily_limit = martial_manager.get_daily_create_limit()
	var remaining = martial_manager.get_remaining_create_count()
	create_info.text = _format_create_info_text(martial_manager, daily_limit, remaining, false)
	if not game_manager.network or not game_manager.network.is_logged_in():
		create_btn.disabled = true
		create_btn.text = "登录后自创"
	elif not martial_manager.is_server_martial_count_ready():
		create_btn.disabled = true
		create_btn.text = "同步今日次数中..."
	elif remaining <= 0:
		create_btn.disabled = true
		create_btn.text = "今日次数已用完"
	else:
		create_btn.disabled = false
		create_btn.text = "⚔️ 开始自创武功"
		UIStyle.apply_golden_button_style(create_btn)
		UIStyle.setup_button_animation(create_btn)
		if game_manager.network and game_manager.network.is_logged_in() and martial_manager.is_server_martial_count_ready() and remaining > 0:
			var tween = create_btn.create_tween()
			tween.set_loops()
			tween.tween_property(create_btn, "modulate", Color(1.15, 1.1, 0.9, 1), 0.8)
			tween.tween_property(create_btn, "modulate", Color(1, 1, 1, 1), 0.8)
			create_btn.set_meta("golden_tween", tween)

static func _clear_martial_create_flow_metas(panel: Control, game_manager) -> void :
	if game_manager:
		game_manager.martial_create_ui_flow_clear()
	if not is_instance_valid(panel):
		return
	for k in ["martial_flow_active", "martial_pending_view", "martial_create_snapshot"]:
		if panel.has_meta(k):
			panel.remove_meta(k)


static func sync_martial_create_controls_from_game_manager(panel: Control, game_manager) -> void :
	if not game_manager or not game_manager.martial_create_ui_flow_active():
		return
	if not panel.has_meta("create_btn") or not panel.has_meta("create_info"):
		return
	var create_btn = panel.get_meta("create_btn") as Button
	var create_info = panel.get_meta("create_info") as Label
	if not is_instance_valid(create_btn) or not is_instance_valid(create_info):
		return
	var mm = game_manager.martial_arts_manager
	if not mm:
		return
	panel.set_meta("martial_flow_active", true)
	_kill_create_btn_golden_tween(create_btn)
	var lim = mm.get_daily_create_limit()
	var rem = mm.get_remaining_create_count()
	create_info.text = _format_create_info_text(mm, lim, rem, true)
	var st: Dictionary = game_manager.martial_create_ui_get_sync_state()
	var now: int = int(st.get("now_ticks", 0))
	var end_ticks: int = int(st.get("countdown_end_ticks", 0))
	var pending: bool = bool(st.get("pending_view", false))
	var lr: bool = bool(st.get("learn_ready", false))
	if pending:
		create_btn.text = "查看结果"
		create_btn.disabled = false
	elif now < end_ticks:
		var ms_left: int = maxi(0, end_ticks - now)
		var sec_show: int = maxi(1, int(ceil(float(ms_left) / 1000.0)))
		create_btn.text = "参悟中 (%ds)" % sec_show
		create_btn.disabled = true
	elif not lr:
		create_btn.text = "仍在参悟中…"
		create_btn.disabled = true
	else:
		create_btn.text = "查看结果"
		create_btn.disabled = false

static func on_create_btn_pressed(panel: Control, create_btn: Button, create_info: Label, martial_manager, player, game_manager):
	if panel == null or not is_instance_valid(panel):
		return
	if game_manager.martial_create_ui_flow_active():
		_show_result_popup_fullscreen(panel, "自创武功", "", "当前参悟尚未结束，请等待倒计时或查看结果。")
		return
	if not martial_manager.is_server_martial_count_ready():
		_show_result_popup_fullscreen(panel, "自创武功", "", "正在同步今日自创次数，请稍候或检查网络后重试。")
		return
	if not martial_manager.can_create_martial_art():
		_show_result_popup_fullscreen(panel, "自创武功", "", "今日自创次数已用完，请明天再来！")
		return
	if not game_manager.network or not game_manager.network.is_logged_in():
		_show_result_popup_fullscreen(panel, "自创武功", "", "当前网络不可用，已阻止操作。\n为防止断网SL，自创武功需联网并完成云端确认。")
		return

	game_manager.register_martial_hall_panel_for_create_ui(panel)
	game_manager.martial_create_ui_flow_begin(player.realm)
	sync_martial_create_controls_from_game_manager(panel, game_manager)

static func on_view_martial_create_result(panel: Control, create_btn: Button, create_info: Label, martial_manager, player, game_manager):
	if panel == null or not is_instance_valid(panel):
		return
	var btn_ref: Button = create_btn if is_instance_valid(create_btn) else null
	if btn_ref == null and panel.has_meta("create_btn"):
		btn_ref = panel.get_meta("create_btn") as Button
	if btn_ref and is_instance_valid(btn_ref):
		btn_ref.disabled = true

	while not game_manager.is_martial_create_learn_ready():
		if not is_instance_valid(panel):
			return
		await panel.get_tree().process_frame

	var result: Dictionary = game_manager.get_martial_create_learn_result()
	if not is_instance_valid(panel):
		push_warning("[MartialHall] 自创流程结束后武道馆面板已释放，无法显示结果")
		return

	var persisted_ok: = true

	if game_manager.has_method("is_martial_create_upload_finished") and not game_manager.is_martial_create_upload_finished():
		var wait_start: = Time.get_ticks_msec()
		while not game_manager.is_martial_create_upload_finished():
			if not is_instance_valid(panel):
				return
			if (Time.get_ticks_msec() - wait_start) / 1000.0 >= 5.0:
				break
			await panel.get_tree().process_frame

	if bool(result.get("server_persisted", false)) or bool(result.get("success", false)):
		persisted_ok = true
	elif game_manager.has_method("is_martial_create_upload_ok"):
		persisted_ok = bool(game_manager.is_martial_create_upload_ok())
	if not is_instance_valid(panel):
		push_warning("[MartialHall] 自创流程落盘后武道馆面板已释放，跳过后续 UI")
		return
	if not persisted_ok and not bool(result.get("success", false)):
		await _show_result_popup_fullscreen(panel, "自创武功", "同步未完成", "云端同步尚未完成，请稍后重试或重新登录确认。", Callable(), true)
		if is_instance_valid(panel):
			_refresh_martial_view_fullscreen(panel)
		return
	if result.success:
		_broadcast_martial_create_success(game_manager, result)
	if result.success:
		var poem_show = String(result.get("poem", ""))
		var on_ok_success: = func():
			_reset_martial_create_main_button_after_flow(panel, game_manager, martial_manager)
			_clear_martial_create_flow_metas(panel, game_manager)
			if is_instance_valid(panel):
				_refresh_martial_view_fullscreen(panel)
		await _show_result_popup_fullscreen(panel, "自创武功", poem_show, String(result.get("message", "")), on_ok_success, true)
	else:
		var on_ok_fail: = func():
			_reset_martial_create_main_button_after_flow(panel, game_manager, martial_manager)
			_clear_martial_create_flow_metas(panel, game_manager)
		await _show_result_popup_fullscreen(panel, "自创武功", "参悟失败", String(result.get("message", "")), on_ok_fail, true)
	if not is_instance_valid(panel):
		push_warning("[MartialHall] 自创结果弹窗后武道馆面板已释放，跳过后续 UI")
		return

static func _broadcast_martial_create_success(game_manager, result: Dictionary) -> void :
	if game_manager == null or game_manager.player == null:
		return
	var art = result.get("art", null)
	if art == null:
		return
	var martial_name = art.name
	var martial_effect = art.effect_type
	var martial_layer = art.layer
	var effect_value = art.get_effect_value()
	var poem = String(result.get("poem", ""))
	var effect_name = MartialArtsManager.effect_type_label_zh(martial_effect)
	var announce_msg = "%s\n恭喜【%s】自创%d层武功【%s】！%s+%.1f%%" % [poem, game_manager.player.player_name, martial_layer, martial_name, effect_name, effect_value]
	game_manager.broadcast_event("martial_create", game_manager.player.player_name, {"martial_name": martial_name, "effect_type": martial_effect, "layer": martial_layer, "effect_value": effect_value}, announce_msg)
