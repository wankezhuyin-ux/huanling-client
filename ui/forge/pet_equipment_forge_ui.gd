extends RefCounted

const UIStyle = preload("res://scripts/ui_style.gd")
const PetEquipmentEnhance = preload("res://scripts/pet_equipment/pet_equipment_enhance.gd")

static func create_fullscreen(game_manager) -> Control:
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", UIStyle.create_panel_style())
	panel.set_meta("game_manager", game_manager)
	panel.set_meta("selected_equip_id", "")
	panel.set_meta("selected_from_equipped", false)

	var vbox = UIStyle.create_base_vbox()
	panel.add_child(vbox)

	var title = UIStyle.create_title_label("宠装强化")
	vbox.add_child(title)

	var info_label = Label.new()
	info_label.text = "左侧选择部位与宠物装备，右侧消耗宠装强化石强化（最高+9）"
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 16)
	info_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(info_label)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.scroll_deadzone = 20
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(scroll)

	var scroll_content = VBoxContainer.new()
	scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_content.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	scroll_content.add_theme_constant_override("separation", 15)
	scroll_content.offset_left = 10
	scroll_content.offset_top = 10
	scroll_content.offset_right = -10
	scroll_content.offset_bottom = -10
	scroll.add_child(scroll_content)
	panel.set_meta("scroll_content", scroll_content)

	_build_pet_forge_view(panel)
	return panel


static func _create_section_vbox(section_title: String) -> VBoxContainer:
	var section_vbox = VBoxContainer.new()
	section_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	section_vbox.add_theme_constant_override("separation", 8)
	var title_panel = Panel.new()
	title_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_panel.custom_minimum_size = Vector2(0, 35)
	title_panel.add_theme_stylebox_override("panel", UIStyle.create_item_style())
	section_vbox.add_child(title_panel)
	var title = Label.new()
	title.text = section_title
	title.set_anchors_preset(Control.PRESET_FULL_RECT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
	title_panel.add_child(title)
	return section_vbox

static func _subsection_title(text: String) -> Label:
	var l = Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	return l

static func _workspace_panel() -> Panel:
	var p = Panel.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.custom_minimum_size = Vector2(0, 190)
	p.add_theme_stylebox_override("panel", UIStyle.create_item_style())
	return p

static func _get_equip_id(ev) -> String:
	if ev is Dictionary:
		return str(ev.get("id", ""))
	return str(ev.id)

static func _eq_dict_from_variant(ev) -> Dictionary:
	if ev is Dictionary:
		return ev.duplicate()
	if ev != null and ev.has_method("to_dict"):
		return ev.to_dict()
	return {}

static func _build_enhance_rule_text() -> String:
	var bonus_parts: Array[String] = []
	for lv in range(1, PetEquipmentEnhance.MAX_LEVEL + 1):
		var bonus_ratio: = float(PetEquipmentEnhance.ENHANCE_BONUS_BY_LEVEL[lv]) * 100.0
		bonus_parts.append("+%d: +%.0f%%" % [lv, bonus_ratio])
	var cost_parts: Array[String] = []
	for lv in range(1, PetEquipmentEnhance.MAX_LEVEL + 1):
		cost_parts.append("+%d需%d个" % [lv, lv])
	return "强化规则说明\n属性提升：%s\n强化消耗：%s" % [", ".join(bonus_parts), ", ".join(cost_parts)]

static func _build_pet_forge_view(panel: Control):
	var scroll_content = panel.get_meta("scroll_content") as VBoxContainer

	var equip_section = _create_section_vbox("装备选择")
	scroll_content.add_child(equip_section)

	var workspace = _workspace_panel()
	equip_section.add_child(workspace)
	var workspace_inner = MarginContainer.new()
	workspace_inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	workspace_inner.add_theme_constant_override("margin_left", 12)
	workspace_inner.add_theme_constant_override("margin_top", 12)
	workspace_inner.add_theme_constant_override("margin_right", 12)
	workspace_inner.add_theme_constant_override("margin_bottom", 12)
	workspace.add_child(workspace_inner)

	var equip_row = HBoxContainer.new()
	equip_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equip_row.add_theme_constant_override("separation", 15)
	workspace_inner.add_child(equip_row)

	var left_section = VBoxContainer.new()
	left_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_section.add_theme_constant_override("separation", 8)
	left_section.add_child(_subsection_title("宠物装备"))
	equip_row.add_child(left_section)

	var sel_btn = Button.new()
	sel_btn.text = "选择宠物装备"
	sel_btn.custom_minimum_size = Vector2(160, 40)
	sel_btn.add_theme_font_size_override("font_size", 16)
	UIStyle.apply_button_style(sel_btn)
	sel_btn.pressed.connect( func(): _show_equipment_picker(panel))
	left_section.add_child(sel_btn)

	var equip_name_label = Label.new()
	equip_name_label.text = "未选择"
	equip_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	equip_name_label.add_theme_font_size_override("font_size", 18)
	equip_name_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	left_section.add_child(equip_name_label)
	panel.set_meta("equip_name_label", equip_name_label)

	var equip_attrs_label = Label.new()
	equip_attrs_label.text = ""
	equip_attrs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	equip_attrs_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	equip_attrs_label.add_theme_font_size_override("font_size", 15)
	equip_attrs_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	left_section.add_child(equip_attrs_label)
	panel.set_meta("equip_attrs_label", equip_attrs_label)

	var right_section = VBoxContainer.new()
	right_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_section.add_theme_constant_override("separation", 8)
	right_section.add_child(_subsection_title("强化材料"))
	equip_row.add_child(right_section)

	var stone_label = Label.new()
	stone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stone_label.add_theme_font_size_override("font_size", 18)
	stone_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	right_section.add_child(stone_label)
	panel.set_meta("stone_label", stone_label)

	var fragment_btn = Button.new()
	fragment_btn.text = "10碎片合成1强化石"
	fragment_btn.custom_minimum_size = Vector2(180, 40)
	fragment_btn.add_theme_font_size_override("font_size", 15)
	UIStyle.apply_button_style(fragment_btn)
	fragment_btn.pressed.connect( func(): _on_synthesize_fragments_pressed(panel))
	right_section.add_child(fragment_btn)
	panel.set_meta("fragment_btn", fragment_btn)

	var preview_section = _create_section_vbox("预览")
	scroll_content.add_child(preview_section)
	var preview_box = Panel.new()
	preview_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_box.custom_minimum_size = Vector2(0, 110)
	preview_box.add_theme_stylebox_override("panel", UIStyle.create_item_style())
	preview_section.add_child(preview_box)
	var preview_inner = MarginContainer.new()
	preview_inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	preview_inner.add_theme_constant_override("margin_left", 12)
	preview_inner.add_theme_constant_override("margin_top", 10)
	preview_inner.add_theme_constant_override("margin_right", 12)
	preview_inner.add_theme_constant_override("margin_bottom", 10)
	preview_box.add_child(preview_inner)
	var preview_label = Label.new()
	preview_label.text = "请选择宠物装备"
	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_label.add_theme_font_size_override("font_size", 16)
	preview_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	preview_inner.add_child(preview_label)
	panel.set_meta("preview_label", preview_label)

	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 15)
	btn_row.custom_minimum_size = Vector2(0, 56)
	scroll_content.add_child(btn_row)
	var forge_btn = Button.new()
	forge_btn.text = "开始强化"
	forge_btn.custom_minimum_size = Vector2(200, 52)
	forge_btn.add_theme_font_size_override("font_size", 18)
	UIStyle.apply_golden_button_style(forge_btn)
	forge_btn.disabled = true
	forge_btn.pressed.connect( func(): _on_enhance_pressed(panel))
	btn_row.add_child(forge_btn)
	panel.set_meta("forge_btn", forge_btn)

	var tip = Label.new()
	tip.text = "强化失败时仍消耗材料；已穿戴的宠装也可在此强化"
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.add_theme_font_size_override("font_size", 14)
	tip.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	scroll_content.add_child(tip)
	var rule_box = Panel.new()
	rule_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rule_box.add_theme_stylebox_override("panel", UIStyle.create_item_style())
	scroll_content.add_child(rule_box)
	var rule_margin = MarginContainer.new()
	rule_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	rule_margin.add_theme_constant_override("margin_left", 12)
	rule_margin.add_theme_constant_override("margin_top", 10)
	rule_margin.add_theme_constant_override("margin_right", 12)
	rule_margin.add_theme_constant_override("margin_bottom", 10)
	rule_box.add_child(rule_margin)
	var rule_label = Label.new()
	rule_label.text = _build_enhance_rule_text()
	rule_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rule_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rule_label.add_theme_font_size_override("font_size", 14)
	rule_label.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9))
	rule_margin.add_child(rule_label)

	_update_stone_label(panel)
	_update_preview(panel)

static func _update_stone_label(panel: Control):
	var game_manager = panel.get_meta("game_manager")
	var stone_label = panel.get_meta("stone_label") as Label
	if not game_manager or not stone_label:
		return
	var n: = 0
	var frag: = 0
	if game_manager.inventory_manager:
		n = game_manager.inventory_manager.get_item_count(PetEquipmentEnhance.STONE_ITEM)
		frag = game_manager.inventory_manager.get_item_count(PetEquipmentEnhance.FRAGMENT_ITEM)
	stone_label.text = "宠装强化石：%d\n宠装碎片：%d" % [n, frag]

static func _get_selected_equipment_dict(panel: Control) -> Dictionary:
	var game_manager = panel.get_meta("game_manager")
	var eid: = str(panel.get_meta("selected_equip_id", ""))
	var from_eq: = bool(panel.get_meta("selected_from_equipped", false))
	if eid.is_empty() or game_manager == null:
		return {}
	if from_eq:
		var pem = game_manager.pet_equipment_manager
		if pem == null:
			return {}
		for slot in pem.equipped.keys():
			var eq = pem.equipped[slot]
			if eq != null and str(eq.id) == eid:
				return eq.to_dict()
	else:
		var d = game_manager.inventory_manager.get_pet_equipment_by_id(eid)
		return d.duplicate() if d is Dictionary else {}
	return {}

static func _update_preview(panel: Control):
	var preview_label = panel.get_meta("preview_label") as Label
	var forge_btn = panel.get_meta("forge_btn") as Button
	var equip_name_label = panel.get_meta("equip_name_label") as Label
	var equip_attrs_label = panel.get_meta("equip_attrs_label") as Label
	var game_manager = panel.get_meta("game_manager")
	_update_stone_label(panel)
	var d: = _get_selected_equipment_dict(panel)
	var eid: = str(panel.get_meta("selected_equip_id", ""))
	if d.is_empty() or eid.is_empty():
		if equip_name_label:
			equip_name_label.text = "未选择"
		if equip_attrs_label:
			equip_attrs_label.text = ""
		if preview_label:
			preview_label.text = "请选择宠物装备"
		if forge_btn:
			forge_btn.disabled = true
		return
	var lv: = PetEquipmentEnhance.get_level_from_dict(d)
	var base_name: = str(d.get("name", "宠装"))
	var disp: = PetEquipmentEnhance.format_display_name(base_name, lv)
	if equip_name_label:
		equip_name_label.text = disp
	if equip_attrs_label:
		equip_attrs_label.text = PetEquipmentEnhance.format_effective_stats_line(d)
	if lv >= PetEquipmentEnhance.MAX_LEVEL:
		if preview_label:
			preview_label.text = "已达最高强化等级 +%d" % PetEquipmentEnhance.MAX_LEVEL
		if forge_btn:
			forge_btn.disabled = true
		return
	var cost: = PetEquipmentEnhance.stone_cost_for_next_level(lv)
	var rate: = PetEquipmentEnhance.success_rate_for_next_level(lv)
	var have: = 0
	if game_manager and game_manager.inventory_manager:
		have = game_manager.inventory_manager.get_item_count(PetEquipmentEnhance.STONE_ITEM)
	if preview_label:
		preview_label.text = "下一级：消耗宠装强化石 x%d\n成功率：%.0f%%\n当前持有：%d" % [cost, rate * 100.0, have]
	if forge_btn:
		forge_btn.disabled = have < cost

static func _on_enhance_pressed(panel: Control):
	var game_manager = panel.get_meta("game_manager")
	var eid: = str(panel.get_meta("selected_equip_id", ""))
	var forge_btn = panel.get_meta("forge_btn") as Button
	if eid.is_empty() or game_manager == null:
		return
	if not game_manager.network or not game_manager.network.is_logged_in():
		_show_result_toast(panel, "当前网络不可用，宠装强化需联网并由服务器确认。")
		return
	var equip_dict: = _get_selected_equipment_dict(panel)
	if equip_dict.is_empty():
		_show_result_toast(panel, "未找到待强化的宠物装备")
		return
	var lv: = PetEquipmentEnhance.get_level_from_dict(equip_dict)
	var cost: = PetEquipmentEnhance.stone_cost_for_next_level(lv)
	if cost <= 0:
		_show_result_toast(panel, "该宠物装备已无法继续强化")
		return
	if game_manager.inventory_manager.get_item_count(PetEquipmentEnhance.STONE_ITEM) < cost:
		_show_result_toast(panel, "宠装强化石不足")
		return
	if forge_btn:
		forge_btn.disabled = true
	var op_id: = "pet_equipment_enhance_%s_%d_%d" % [eid, Time.get_unix_time_from_system(), Time.get_ticks_msec()]
	var on_success = func(data: Dictionary):
		if forge_btn:
			forge_btn.disabled = false
		if game_manager and data.has("saveData") and data.get("saveData") is Dictionary:
			game_manager.apply_cloud_save(data.get("saveData"), {
				"reward_inventory_slice": true, 
				"authoritative_equipment_inventory": true, 
			})
		_update_preview(panel)
		_show_result_toast(panel, str(data.get("message", "宠装强化成功")))
	var on_failed = func(error: String):
		if forge_btn:
			forge_btn.disabled = false
		_update_preview(panel)
		_show_result_toast(panel, error)
	game_manager.network.pet_equipment_enhance_success.connect(on_success, CONNECT_ONE_SHOT)
	game_manager.network.pet_equipment_enhance_failed.connect(on_failed, CONNECT_ONE_SHOT)
	game_manager.network.request_pet_equipment_enhance(eid, PetEquipmentEnhance.STONE_ITEM, op_id)

static func _on_synthesize_fragments_pressed(panel: Control):
	var game_manager = panel.get_meta("game_manager")
	var fragment_btn = panel.get_meta("fragment_btn") as Button
	if game_manager == null:
		return
	if not game_manager.network or not game_manager.network.is_logged_in():
		_show_result_toast(panel, "当前网络不可用，碎片合成需联网并由服务器确认。")
		return
	var have_frag: = 0
	if game_manager.inventory_manager:
		have_frag = game_manager.inventory_manager.get_item_count(PetEquipmentEnhance.FRAGMENT_ITEM)
	if have_frag < PetEquipmentEnhance.FRAGMENTS_PER_STONE:
		_show_result_toast(panel, "宠装碎片不足（需要%d个）" % PetEquipmentEnhance.FRAGMENTS_PER_STONE)
		return
	if fragment_btn:
		fragment_btn.disabled = true
	var op_id: = "pet_equipment_synthesize_fragments_%d_%d" % [Time.get_unix_time_from_system(), Time.get_ticks_msec()]
	var on_success = func(data: Dictionary):
		if fragment_btn:
			fragment_btn.disabled = false
		if game_manager and data.has("saveData") and data.get("saveData") is Dictionary:
			game_manager.apply_cloud_save(data.get("saveData"), {
				"reward_inventory_slice": true, 
				"authoritative_equipment_inventory": true, 
			})
		_update_preview(panel)
		_show_result_toast(panel, str(data.get("message", "宠装碎片合成成功")))
	var on_failed = func(error: String):
		if fragment_btn:
			fragment_btn.disabled = false
		_update_preview(panel)
		_show_result_toast(panel, error)
	game_manager.network.pet_equipment_synthesize_fragments_success.connect(on_success, CONNECT_ONE_SHOT)
	game_manager.network.pet_equipment_synthesize_fragments_failed.connect(on_failed, CONNECT_ONE_SHOT)
	game_manager.network.request_pet_equipment_synthesize_fragments(PetEquipmentEnhance.FRAGMENTS_PER_STONE, op_id)

static func _show_result_toast(panel: Control, msg: String):
	var game_manager = panel.get_meta("game_manager")
	if game_manager == null or str(msg).is_empty():
		return
	var tree = game_manager.get_tree()
	if tree and tree.current_scene:
		var popup = Window.new()
		popup.title = ""
		popup.borderless = true
		popup.transparent = true
		popup.unresizable = true
		popup.min_size = Vector2(420, 250)
		popup.size = Vector2(420, 250)
		var popup_panel = Panel.new()
		popup_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		popup_panel.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
		popup.add_child(popup_panel)
		var vbox = VBoxContainer.new()
		vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		vbox.offset_left = 20
		vbox.offset_top = 20
		vbox.offset_right = -20
		vbox.offset_bottom = -20
		vbox.add_theme_constant_override("separation", 16)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		popup_panel.add_child(vbox)
		var title = Label.new()
		title.text = "宠装强化"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 22)
		title.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
		vbox.add_child(title)
		var result_label = Label.new()
		result_label.text = msg
		result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		result_label.add_theme_font_size_override("font_size", 20)
		var ok_color: = Color(0.4, 1.0, 0.4) if msg.find("成功") >= 0 else Color(1.0, 0.6, 0.4)
		result_label.add_theme_color_override("font_color", ok_color)
		vbox.add_child(result_label)
		var ok_btn = Button.new()
		ok_btn.text = "确定"
		ok_btn.custom_minimum_size = Vector2(120, 45)
		UIStyle.apply_golden_button_style(ok_btn)
		ok_btn.pressed.connect( func(): popup.queue_free())
		vbox.add_child(ok_btn)
		tree.current_scene.add_child(popup)
		popup.popup_centered()

static func _show_equipment_picker(panel: Control):
	var game_manager = panel.get_meta("game_manager")
	if game_manager == null:
		return
	var popup = Window.new()
	popup.title = "选择宠物装备"
	popup.size = Vector2i(520, 520)
	popup.transient = true
	popup.borderless = true
	popup.transparent = true
	popup.unresizable = true
	popup.close_requested.connect( func(): popup.queue_free())
	var bg = Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	popup.add_child(bg)
	var root = VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 12
	root.offset_top = 12
	root.offset_right = -12
	root.offset_bottom = -12
	root.add_theme_constant_override("separation", 8)
	popup.add_child(root)
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	var pem = game_manager.pet_equipment_manager
	if pem:
		for slot in pem.equipped.keys():
			var eq2 = pem.equipped[slot]
			if eq2 == null:
				continue
			vbox.add_child(_make_pick_row(panel, popup, eq2, true))

	if vbox.get_child_count() == 0:
		var empty_l = Label.new()
		empty_l.text = "当前没有已穿戴的宠物装备"
		empty_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_l.add_theme_font_size_override("font_size", 16)
		empty_l.add_theme_color_override("font_color", Color(0.55, 0.58, 0.65))
		vbox.add_child(empty_l)
	var close_btn = Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(100, 44)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UIStyle.apply_button_style(close_btn)
	close_btn.pressed.connect( func(): popup.queue_free())
	root.add_child(close_btn)

	game_manager.get_tree().current_scene.add_child(popup)
	popup.popup_centered()

static func _make_pick_row(panel: Control, popup: Window, eq_variant, from_equipped: bool) -> Control:
	var game_manager = panel.get_meta("game_manager")
	var h = Panel.new()
	h.custom_minimum_size = Vector2(0, 56)
	h.add_theme_stylebox_override("panel", UIStyle.create_item_style())
	var hb = HBoxContainer.new()
	hb.set_anchors_preset(Control.PRESET_FULL_RECT)
	hb.offset_left = 8
	hb.offset_right = -8
	hb.offset_top = 4
	hb.offset_bottom = -4
	h.add_child(hb)
	var d: = _eq_dict_from_variant(eq_variant)
	var lv: = PetEquipmentEnhance.get_level_from_dict(d)
	var nm: = PetEquipmentEnhance.format_display_name(str(d.get("name", "")), lv)
	var src: = "穿戴中" if from_equipped else "背包"
	var lbl = Label.new()
	lbl.text = "%s  [%s]" % [nm, src]
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 16)
	hb.add_child(lbl)
	var bid: = _get_equip_id(eq_variant)
	var btn = Button.new()
	btn.text = "选择"
	btn.custom_minimum_size = Vector2(72, 32)
	UIStyle.apply_button_style(btn)
	btn.pressed.connect( func():
		panel.set_meta("selected_equip_id", bid)
		panel.set_meta("selected_from_equipped", from_equipped)
		popup.queue_free()
		_update_preview(panel)
	)
	hb.add_child(btn)
	return h
