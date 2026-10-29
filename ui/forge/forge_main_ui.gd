extends RefCounted

const ForgeManager = preload("res://scripts/forge/forge_manager.gd")
const ForgeConfig = preload("res://scripts/forge/forge_config.gd")
const UIStyle = preload("res://scripts/ui_style.gd")
const ForgeAnimation = preload("res://ui/forge/forge_animation.gd")
const ForgeEquipSelectPopup = preload("res://ui/forge/forge_equip_select_popup.gd")
const ForgeResultPopup = preload("res://ui/forge/forge_result_popup.gd")

static func create_fullscreen(game_manager) -> Control:
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", UIStyle.create_panel_style())

	panel.set_meta("game_manager", game_manager)
	panel.set_meta("main_equipment", {})
	panel.set_meta("sub_equipment", {})
	panel.set_meta("selected_attr", "")

	var forge_manager = ForgeManager.new()
	panel.set_meta("forge_manager", forge_manager)

	var vbox = UIStyle.create_base_vbox()
	panel.add_child(vbox)

	var title = UIStyle.create_title_label("打造坊")
	vbox.add_child(title)

	var info_label = Label.new()
	info_label.text = "使用极限装备锻造，转移属性"
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 16)
	info_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	vbox.add_child(info_label)

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
	content_container.add_child(scroll)

	var scroll_content = VBoxContainer.new()
	scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_content.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	scroll_content.offset_left = 10
	scroll_content.offset_top = 10
	scroll_content.offset_right = -10
	scroll_content.offset_bottom = -10
	scroll_content.add_theme_constant_override("separation", 12)
	scroll_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(scroll_content)

	panel.set_meta("scroll_content", scroll_content)

	_build_forge_view(panel)

	return panel

static func _build_forge_view(panel: Control):
	var scroll_content = panel.get_meta("scroll_content") as VBoxContainer
	var game_manager = panel.get_meta("game_manager")

	var equip_section = _create_section_panel("装备选择", true)
	scroll_content.add_child(equip_section)

	var equip_row = HBoxContainer.new()
	equip_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equip_row.add_theme_constant_override("separation", 15)
	equip_section.add_child(equip_row)

	var main_section = _create_inner_section("主炼装备")
	main_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equip_row.add_child(main_section)

	var main_btn = Button.new()
	main_btn.text = "[选择装备]"
	main_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	main_btn.custom_minimum_size = Vector2(120, 35)
	UIStyle.apply_button_style(main_btn)
	main_btn.pressed.connect( func(): _on_main_equip_select(panel))
	main_section.add_child(main_btn)

	var main_equip_name_label = Label.new()
	main_equip_name_label.text = "未选择"
	main_equip_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_equip_name_label.add_theme_font_size_override("font_size", 20)
	main_equip_name_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	main_equip_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main_equip_name_label.size_flags_horizontal = Control.SIZE_FILL
	main_section.add_child(main_equip_name_label)
	panel.set_meta("main_equip_name_label", main_equip_name_label)

	var main_equip_attrs_label = Label.new()
	main_equip_attrs_label.text = ""
	main_equip_attrs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_equip_attrs_label.add_theme_font_size_override("font_size", 16)
	main_equip_attrs_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main_equip_attrs_label.size_flags_horizontal = Control.SIZE_FILL
	main_section.add_child(main_equip_attrs_label)
	panel.set_meta("main_equip_attrs_label", main_equip_attrs_label)

	var sub_section = _create_inner_section("副炼材料")
	sub_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equip_row.add_child(sub_section)

	var sub_btn = Button.new()
	sub_btn.text = "[选择极限装备]"
	sub_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	sub_btn.custom_minimum_size = Vector2(120, 35)
	UIStyle.apply_button_style(sub_btn)
	sub_btn.pressed.connect( func(): _on_sub_equip_select(panel))
	sub_section.add_child(sub_btn)

	var sub_equip_name_label = Label.new()
	sub_equip_name_label.text = "未选择"
	sub_equip_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_equip_name_label.add_theme_font_size_override("font_size", 20)
	sub_equip_name_label.add_theme_color_override("font_color", Color(1, 0.6, 0.2))
	sub_equip_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub_equip_name_label.size_flags_horizontal = Control.SIZE_FILL
	sub_section.add_child(sub_equip_name_label)
	panel.set_meta("sub_equip_name_label", sub_equip_name_label)

	var sub_equip_attrs_label = Label.new()
	sub_equip_attrs_label.text = ""
	sub_equip_attrs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_equip_attrs_label.add_theme_font_size_override("font_size", 16)
	sub_equip_attrs_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub_equip_attrs_label.size_flags_horizontal = Control.SIZE_FILL
	sub_section.add_child(sub_equip_attrs_label)
	panel.set_meta("sub_equip_attrs_label", sub_equip_attrs_label)

	var attr_section = _create_section_panel("属性转移", false)
	scroll_content.add_child(attr_section)

	var transfer_container = VBoxContainer.new()
	transfer_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	transfer_container.add_theme_constant_override("separation", 5)
	attr_section.add_child(transfer_container)
	panel.set_meta("transfer_container", transfer_container)

	_init_transfer_placeholder(transfer_container)

	var preview_label = Label.new()
	preview_label.text = "请选择装备和属性"
	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_label.add_theme_font_size_override("font_size", 18)
	preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	attr_section.add_child(preview_label)
	panel.set_meta("preview_label", preview_label)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 15)
	btn_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	scroll_content.add_child(btn_row)

	var forge_btn = Button.new()
	forge_btn.text = "开始锻造"
	forge_btn.custom_minimum_size = Vector2(120, 45)
	UIStyle.apply_golden_button_style(forge_btn)
	forge_btn.pressed.connect( func(): _on_forge_btn_pressed(panel))
	btn_row.add_child(forge_btn)
	panel.set_meta("forge_btn", forge_btn)

	var tip_label = Label.new()
	tip_label.text = "⚠️ 锻造后副炼材料将消失"
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_label.add_theme_font_size_override("font_size", 16)
	tip_label.add_theme_color_override("font_color", Color(1, 0.7, 0.3))
	scroll_content.add_child(tip_label)

static func _create_section_panel(section_title: String, is_highlight: bool = false) -> VBoxContainer:
	var section_vbox = VBoxContainer.new()
	section_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	section_vbox.add_theme_constant_override("separation", 8)

	var title_panel = Panel.new()
	title_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_panel.custom_minimum_size = Vector2(0, 40)

	var style = StyleBoxFlat.new()
	if is_highlight:
		style.bg_color = Color(0.2, 0.15, 0.1, 0.95)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.8, 0.6, 0.2, 1)
	else:
		style.bg_color = Color(0.12, 0.14, 0.2, 0.8)
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.3, 0.4, 0.6, 0.8)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	title_panel.add_theme_stylebox_override("panel", style)
	section_vbox.add_child(title_panel)

	var title_label = Label.new()
	title_label.text = section_title
	title_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	if is_highlight:
		title_label.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	else:
		title_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	title_panel.add_child(title_label)

	return section_vbox

static func _create_inner_section(title: String) -> VBoxContainer:
	var section = VBoxContainer.new()
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.add_theme_constant_override("separation", 4)

	var title_label = Label.new()
	title_label.text = "【%s】" % title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.7))
	section.add_child(title_label)

	return section

static func _on_main_equip_select(panel: Control):
	var game_manager = panel.get_meta("game_manager")
	ForgeEquipSelectPopup.show_popup(panel, "main", game_manager)

static func _on_sub_equip_select(panel: Control):
	var game_manager = panel.get_meta("game_manager")
	ForgeEquipSelectPopup.show_popup(panel, "sub", game_manager)

static func on_equipment_selected(panel: Control, equipment: Dictionary, type: String):
	if type == "main":
		panel.set_meta("main_equipment", equipment)
		_update_main_equip(panel)
	else:
		panel.set_meta("sub_equipment", equipment)
		_update_sub_equip(panel)
	_update_transfer_info(panel)
	_update_preview(panel)

static func _update_main_equip(panel: Control):
	var main_equipment = panel.get_meta("main_equipment")
	var main_equip_name_label = panel.get_meta("main_equip_name_label") as Label
	var main_equip_attrs_label = panel.get_meta("main_equip_attrs_label") as Label

	if main_equipment.is_empty():
		main_equip_name_label.text = "未选择"
		main_equip_attrs_label.text = ""
	else:
		main_equip_name_label.text = main_equipment.get("name", "未知")
		var attrs_text = ""
		for attr in ["attack", "defense", "agility", "hp", "mp"]:
			var val = main_equipment.get(attr, 0)
			if val != 0:
				if not attrs_text.is_empty():
					attrs_text += " "
				attrs_text += "%s:%d" % [ForgeConfig.get_attr_name(attr), val]
		main_equip_attrs_label.text = attrs_text

static func _update_sub_equip(panel: Control):
	var sub_equipment = panel.get_meta("sub_equipment")
	var sub_equip_name_label = panel.get_meta("sub_equip_name_label") as Label
	var sub_equip_attrs_label = panel.get_meta("sub_equip_attrs_label") as Label

	if sub_equipment.is_empty():
		sub_equip_name_label.text = "未选择"
		sub_equip_attrs_label.text = ""
		panel.set_meta("selected_attr", "")
	else:
		var display_count: = int(sub_equipment.get("count", 1))
		sub_equip_name_label.text = "%s x%d" % [sub_equipment.get("name", "未知"), display_count]
		var slot = sub_equipment.get("slot", "")
		var attr = ForgeConfig.get_material_main_attr(slot)
		var limit_val = ForgeConfig.get_limit_value(attr)
		sub_equip_attrs_label.text = "%s: +%d" % [ForgeConfig.get_attr_name(attr), limit_val]
		panel.set_meta("selected_attr", attr)

static func _init_transfer_placeholder(container: VBoxContainer):
	for child in container.get_children():
		child.queue_free()

	var placeholder = Label.new()
	placeholder.text = "请先选择装备"
	placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.add_theme_font_size_override("font_size", 16)
	placeholder.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	container.add_child(placeholder)

static func _update_transfer_info(panel: Control):
	var main_equipment = panel.get_meta("main_equipment")
	var sub_equipment = panel.get_meta("sub_equipment")
	var transfer_container = panel.get_meta("transfer_container") as VBoxContainer
	var forge_manager = panel.get_meta("forge_manager")

	if main_equipment.is_empty() or sub_equipment.is_empty():
		_init_transfer_placeholder(transfer_container)
		return

	var attrs = forge_manager.get_transferable_attributes(main_equipment.get("slot", ""))
	if attrs.is_empty():
		_init_transfer_placeholder(transfer_container)
		return

	for child in transfer_container.get_children():
		child.queue_free()

	for attr_info in attrs:
		var attr_row = _create_attr_progress_row(attr_info, main_equipment)
		transfer_container.add_child(attr_row)

static func _create_attr_progress_row(attr_info: Dictionary, main_equipment: Dictionary) -> Control:
	var container = VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_theme_constant_override("separation", 2)

	var info_margin = MarginContainer.new()
	info_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_margin.add_theme_constant_override("margin_left", 80)
	info_margin.add_theme_constant_override("margin_right", 80)
	container.add_child(info_margin)

	var info_row = HBoxContainer.new()
	info_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_row.add_theme_constant_override("separation", 8)
	info_margin.add_child(info_row)

	var name_label = Label.new()
	name_label.text = attr_info.attr_name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.8))
	info_row.add_child(name_label)

	var current = main_equipment.get(attr_info.attribute, 0)
	var max_val = int(ForgeConfig.get_limit_value(attr_info.attribute) * attr_info.max_rate)
	var progress_ratio = 0.0
	if max_val > 0:
		progress_ratio = float(current) / float(max_val)

	var value_label = Label.new()
	value_label.text = "%d / %d" % [current, max_val]
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_font_size_override("font_size", 16)
	value_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	info_row.add_child(value_label)

	var progress_margin = MarginContainer.new()
	progress_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_margin.add_theme_constant_override("margin_left", 80)
	progress_margin.add_theme_constant_override("margin_right", 80)
	container.add_child(progress_margin)

	var progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(0, 16)
	progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.value = min(progress_ratio * 100, 100)
	progress_bar.show_percentage = false

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	bg_style.border_width_left = 1
	bg_style.border_width_right = 1
	bg_style.border_width_top = 1
	bg_style.border_width_bottom = 1
	bg_style.border_color = Color(0.3, 0.3, 0.4, 0.8)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	progress_bar.add_theme_stylebox_override("background", bg_style)

	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.4, 0.6, 0.9, 1)
	fill_style.corner_radius_top_left = 3
	fill_style.corner_radius_top_right = 3
	fill_style.corner_radius_bottom_left = 3
	fill_style.corner_radius_bottom_right = 3
	progress_bar.add_theme_stylebox_override("fill", fill_style)
	progress_margin.add_child(progress_bar)

	var rate_margin = MarginContainer.new()
	rate_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rate_margin.add_theme_constant_override("margin_left", 80)
	rate_margin.add_theme_constant_override("margin_right", 80)
	container.add_child(rate_margin)

	var rate_label = Label.new()
	rate_label.text = "上限 %.0f%%" % (attr_info.max_rate * 100)
	rate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rate_label.add_theme_font_size_override("font_size", 14)
	rate_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	rate_margin.add_child(rate_label)

	return container

static func _update_preview(panel: Control):
	var main_equipment = panel.get_meta("main_equipment")
	var sub_equipment = panel.get_meta("sub_equipment")
	var selected_attr = panel.get_meta("selected_attr")
	var preview_label = panel.get_meta("preview_label") as Label
	var forge_manager = panel.get_meta("forge_manager")
	var forge_btn = panel.get_meta("forge_btn") as Button

	if main_equipment.is_empty() or sub_equipment.is_empty() or selected_attr.is_empty():
		preview_label.text = "请选择装备"
		if forge_btn:
			forge_btn.disabled = true
		return

	preview_label.text = "正在同步服务器锻造预览..."
	if forge_btn:
		forge_btn.disabled = true
	_request_server_preview(panel, str(main_equipment.get("id", "")), str(sub_equipment.get("id", "")), selected_attr)

static func _request_server_preview(panel: Control, main_id: String, sub_id: String, selected_attr: String):
	var game_manager = panel.get_meta("game_manager")
	var preview_label = panel.get_meta("preview_label") as Label
	var forge_btn = panel.get_meta("forge_btn") as Button
	var sub_equipment = panel.get_meta("sub_equipment")
	var aggregate_entry: Dictionary = sub_equipment.get("aggregate_entry", {}) if sub_equipment is Dictionary else {}
	if aggregate_entry is Dictionary and not aggregate_entry.is_empty() and game_manager and game_manager.inventory_manager:
		var picked_items: Array = game_manager.inventory_manager.get_limit_material_aggregate_pick_items(aggregate_entry, 1)
		if picked_items.is_empty():
			preview_label.text = "未找到可用的极限材料实例"
			if forge_btn:
				forge_btn.disabled = true
			return
		var picked_item = picked_items[0]
		if picked_item == null:
			preview_label.text = "极限材料实例无效"
			if forge_btn:
				forge_btn.disabled = true
			return
		sub_id = str(picked_item.id)
		var resolved_sub = sub_equipment.duplicate(true)
		resolved_sub["id"] = sub_id
		panel.set_meta("resolved_sub_equipment", resolved_sub)
	else:
		panel.set_meta("resolved_sub_equipment", sub_equipment)
	if not game_manager or not game_manager.network or not game_manager.network.is_logged_in():
		var forge_manager = panel.get_meta("forge_manager")
		var main_equipment = panel.get_meta("main_equipment")
		var resolved_sub_equipment = panel.get_meta("resolved_sub_equipment")
		var player_cultivation = 0
		if game_manager and game_manager.player:
			player_cultivation = game_manager.player.cultivation
		var local_preview = forge_manager.preview_forge(main_equipment, resolved_sub_equipment, selected_attr, player_cultivation)
		_apply_preview_to_ui(panel, local_preview, selected_attr)
		return
	var net = game_manager.network
	var token: = "%s|%s|%s|%d" % [main_id, sub_id, selected_attr, Time.get_ticks_msec()]
	panel.set_meta("forge_preview_token", token)
	var on_success = func(data: Dictionary):
		if not is_instance_valid(panel):
			return
		if str(panel.get_meta("forge_preview_token", "")) != token:
			return
		var preview: Dictionary = data.get("preview", {}) if data.get("preview", {}) is Dictionary else {}
		_apply_preview_to_ui(panel, preview, selected_attr)
	var on_failed = func(error: String):
		if not is_instance_valid(panel):
			return
		if str(panel.get_meta("forge_preview_token", "")) != token:
			return
		preview_label.text = error
		if forge_btn:
			forge_btn.disabled = true
	net.forge_preview_success.connect(on_success, CONNECT_ONE_SHOT)
	net.forge_preview_failed.connect(on_failed, CONNECT_ONE_SHOT)
	net.request_forge_preview(main_id, sub_id, selected_attr)

static func _apply_preview_to_ui(panel: Control, preview: Dictionary, selected_attr: String):
	var preview_label = panel.get_meta("preview_label") as Label
	var forge_btn = panel.get_meta("forge_btn") as Button
	if not preview.get("valid", false):
		preview_label.text = preview.get("message", "无法锻造")
		if forge_btn:
			forge_btn.disabled = true
		return
	preview_label.text = "%s +%d~%d\n%s -%d~%d (代价)\n成功率: %.1f%%  当前需求: %d  锻造后需求: %d" % [
		ForgeConfig.get_attr_name(selected_attr), 
		preview.get("min_transfer", 0), 
		preview.get("max_transfer", 0), 
		ForgeConfig.get_attr_name(preview.get("cost_attr", "")), 
		preview.get("min_cost", 0), 
		preview.get("max_cost", 0), 
		preview.get("success_rate", 1.0) * 100.0, 
		preview.get("required_cultivation", 0), 
		preview.get("next_required_cultivation", 0)
	]
	if not preview.get("can_forge", true):
		preview_label.text += "\n⚠ " + preview.get("cultivation_message", "修行不足，无法锻造")
	if forge_btn:
		forge_btn.disabled = not preview.get("can_forge", true)

static func _on_forge_btn_pressed(panel: Control):
	var main_equipment = panel.get_meta("main_equipment")
	var sub_equipment = panel.get_meta("sub_equipment")
	var selected_attr = panel.get_meta("selected_attr")
	var forge_btn = panel.get_meta("forge_btn") as Button

	if main_equipment.is_empty() or sub_equipment.is_empty() or selected_attr.is_empty():
		return
	var game_manager = panel.get_meta("game_manager")
	if game_manager and game_manager.equipment_manager:
		var main_id: = str(main_equipment.get("id", ""))
		var still_equipped: = false
		if not main_id.is_empty():
			for slot in game_manager.equipment_manager.equipped.keys():
				var eq = game_manager.equipment_manager.equipped[slot]
				if eq != null and str(eq.id) == main_id:
					still_equipped = true
					break
		if not still_equipped:
			_show_error(panel, "仅可对已穿戴的主炼装备进行极限打造")
			return
	if not game_manager or not game_manager.network or not game_manager.network.is_logged_in():
		_show_error(panel, "当前网络不可用，锻造已阻止。\n为防止断网SL，锻造需联网并完成云端确认。")
		return

	forge_btn.disabled = true
	var snapshot = game_manager.create_secure_op_snapshot()

	ForgeAnimation.play(panel, func():
		if not is_instance_valid(panel):
			return
		var resolved_sub_equipment = panel.get_meta("resolved_sub_equipment") if panel.has_meta("resolved_sub_equipment") else sub_equipment
		var resolved_sub_id: = str(resolved_sub_equipment.get("id", ""))
		if resolved_sub_id.is_empty() and game_manager and game_manager.inventory_manager:
			var aggregate_entry: Dictionary = sub_equipment.get("aggregate_entry", {}) if sub_equipment is Dictionary else {}
			var picked_items: Array = game_manager.inventory_manager.get_limit_material_aggregate_pick_items(aggregate_entry, 1)
			if not picked_items.is_empty():
				var picked_item = picked_items[0]
				if picked_item != null:
					resolved_sub_id = str(picked_item.id)
					resolved_sub_equipment = sub_equipment.duplicate(true)
					resolved_sub_equipment["id"] = resolved_sub_id
					panel.set_meta("resolved_sub_equipment", resolved_sub_equipment)
		if resolved_sub_id.is_empty():
			if forge_btn:
				forge_btn.disabled = false
			_show_error(panel, "未找到可用的极限材料实例")
			return
		var operation_id: = "forge_%s_%d_%d" % [str(main_equipment.get("id", "")), Time.get_unix_time_from_system(), Time.get_ticks_msec()]
		_call_server_forge(panel, str(main_equipment.get("id", "")), resolved_sub_id, selected_attr, operation_id, snapshot)
	)

static func _call_server_forge(panel: Control, main_id: String, sub_id: String, selected_attr: String, operation_id: String, snapshot: Dictionary):
	var game_manager = panel.get_meta("game_manager")
	var forge_btn = panel.get_meta("forge_btn") as Button
	if not game_manager or not game_manager.network:
		if forge_btn:
			forge_btn.disabled = false
		_show_error(panel, "网络模块不可用")
		return
	var net = game_manager.network
	var finished: = {"done": false}
	var on_success: Callable
	var on_failed: Callable
	on_success = func(data: Dictionary):
		if bool(finished.get("done", false)):
			return
		finished["done"] = true
		if on_failed.is_valid() and net.forge_execute_failed.is_connected(on_failed):
			net.forge_execute_failed.disconnect(on_failed)
		if forge_btn:
			forge_btn.disabled = false
		if data.has("saveData") and data.get("saveData") is Dictionary:
			game_manager.apply_cloud_save(data.get("saveData"), {
				"reward_inventory_slice": true, 
				"authoritative_equipment_inventory": true, 
			})
		var result: Dictionary = data.get("result", {}) if data.get("result", {}) is Dictionary else {}
		if result.is_empty():
			_show_error(panel, data.get("message", "锻造完成，但服务器未返回结果"))
			return
		_apply_forge_result(panel, result, false)
		if bool(result.get("success", false)):
			ForgeResultPopup.show_popup(panel, result)
		else:
			_show_error(panel, result.get("message", data.get("message", "锻造失败")))
	on_failed = func(error: String):
		if bool(finished.get("done", false)):
			return
		finished["done"] = true
		if on_success.is_valid() and net.forge_execute_success.is_connected(on_success):
			net.forge_execute_success.disconnect(on_success)
		if forge_btn:
			forge_btn.disabled = false
		game_manager.restore_secure_op_snapshot(snapshot)
		_show_error(panel, error)
	net.forge_execute_success.connect(on_success, CONNECT_ONE_SHOT)
	net.forge_execute_failed.connect(on_failed, CONNECT_ONE_SHOT)
	net.execute_forge(main_id, sub_id, selected_attr, operation_id)

static func _apply_forge_result(panel: Control, result: Dictionary, mutate_local: bool = true):
	if result.success and result.equipment:
		var main_equipment = panel.get_meta("main_equipment")
		var game_manager = panel.get_meta("game_manager")

		var equip_id = main_equipment.get("id", "")
		if mutate_local and not equip_id.is_empty() and game_manager and game_manager.equipment_manager:
			var equip = game_manager.equipment_manager.get_equipment_by_id(equip_id)
			if equip:
				for attr in ["attack", "defense", "agility", "hp", "mp", "cultivation_req", "base_cultivation_req"]:
					if result.equipment.has(attr):
						equip.set(attr, result.equipment[attr])
				if result.equipment.has("forge_attr_counts"):
					equip.forge_attr_counts = result.equipment.get("forge_attr_counts", {})

		panel.set_meta("main_equipment", result.equipment)
		_update_main_equip(panel)

		var sub_equipment = panel.get_meta("sub_equipment")
		var aggregate_entry: Dictionary = sub_equipment.get("aggregate_entry", {}) if sub_equipment is Dictionary else {}
		if mutate_local and game_manager and game_manager.inventory_manager:
			var resolved_sub = panel.get_meta("resolved_sub_equipment") if panel.has_meta("resolved_sub_equipment") else sub_equipment
			var sub_id = resolved_sub.get("id", "")
			if not sub_id.is_empty():
				game_manager.inventory_manager.remove_item(sub_id, 1)
			if aggregate_entry is Dictionary and not aggregate_entry.is_empty():
				var refreshed_items: Array = game_manager.inventory_manager.get_limit_material_aggregate_items(aggregate_entry)
				if refreshed_items.is_empty():
					panel.set_meta("sub_equipment", {})
					panel.set_meta("resolved_sub_equipment", {})
					_update_sub_equip(panel)
				else:
					var refreshed_count: = refreshed_items.size()
					sub_equipment["count"] = refreshed_count
					var new_rep = refreshed_items[0]
					if new_rep != null:
						sub_equipment["id"] = str(new_rep.id)
					panel.set_meta("sub_equipment", sub_equipment)
					panel.set_meta("resolved_sub_equipment", sub_equipment.duplicate(true))
					_update_sub_equip(panel)
			else:
				var remaining_items = game_manager.inventory_manager.get_limit_equips()
				var still_has = false
				for item in remaining_items:
					if item.name == sub_equipment.get("name", ""):
						still_has = true
						break
				if not still_has:
					panel.set_meta("sub_equipment", {})
					panel.set_meta("resolved_sub_equipment", {})
					_update_sub_equip(panel)
		elif not mutate_local:
			var latest_sub = panel.get_meta("sub_equipment")
			var latest_aggregate: Dictionary = latest_sub.get("aggregate_entry", {}) if latest_sub is Dictionary else {}
			var has_material: = false
			if game_manager and game_manager.inventory_manager:
				if latest_aggregate is Dictionary and not latest_aggregate.is_empty():
					var refreshed_items: Array = game_manager.inventory_manager.get_limit_material_aggregate_items(latest_aggregate)
					has_material = not refreshed_items.is_empty()
					if has_material:
						latest_sub["count"] = refreshed_items.size()
						var rep = refreshed_items[0]
						if rep != null:
							latest_sub["id"] = str(rep.id)
						panel.set_meta("sub_equipment", latest_sub)
						panel.set_meta("resolved_sub_equipment", latest_sub.duplicate(true))
						_update_sub_equip(panel)
				else:
					var latest_id: = str(latest_sub.get("id", ""))
					if not latest_id.is_empty():
						for item in game_manager.inventory_manager.get_limit_equips():
							if str(item.id) == latest_id:
								has_material = true
								break
			if not has_material:
				panel.set_meta("sub_equipment", {})
				panel.set_meta("resolved_sub_equipment", {})
				_update_sub_equip(panel)

		_update_transfer_info(panel)
		_update_preview(panel)

static func _show_error(panel: Control, message: String):
	var popup = Window.new()
	popup.title = ""
	popup.borderless = true
	popup.transparent = true
	popup.unresizable = true
	popup.min_size = Vector2(300, 150)
	popup.size = Vector2(300, 150)

	var bg_panel = Panel.new()
	bg_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_panel.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	popup.add_child(bg_panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 15
	vbox.offset_top = 15
	vbox.offset_right = -15
	vbox.offset_bottom = -15
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	bg_panel.add_child(vbox)

	var label = Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(label)

	var btn = Button.new()
	btn.text = "确定"
	btn.custom_minimum_size = Vector2(80, 35)
	UIStyle.apply_button_style(btn)
	btn.pressed.connect( func(): popup.queue_free())
	vbox.add_child(btn)

	var scene_root = Engine.get_main_loop().current_scene
	if scene_root:
		scene_root.add_child(popup)
		popup.popup_centered()
	else:
		panel.add_child(popup)
		popup.popup_centered()
