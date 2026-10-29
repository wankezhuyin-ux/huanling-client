extends RefCounted

const UIStyle = preload("res://scripts/ui_style.gd")
const SuitEquipmentEnhance = preload("res://scripts/suit/suit_equipment_enhance.gd")
const SuitEnhanceResultPopup = preload("res://ui/forge/suit_enhance_result_popup.gd")

const SLOT_LABELS: = {
	"weapon": "武器", 
	"armor": "衣服", 
	"helmet": "帽子", 
	"boots": "鞋子", 
	"accessory": "饰品", 
}

static func create_fullscreen(game_manager) -> Control:
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", UIStyle.create_panel_style())
	panel.set_meta("game_manager", game_manager)
	panel.set_meta("selected_equip_id", "")
	panel.set_meta("selected_slot", "")
	panel.set_meta("pending_token", "")

	var vbox = UIStyle.create_base_vbox()
	panel.add_child(vbox)

	var title = UIStyle.create_title_label("套装强化")
	vbox.add_child(title)

	var info_label = Label.new()
	info_label.text = "仅可选择当前穿戴的套装部件，消耗套装强化石强化（最高+9）"
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.add_theme_font_size_override("font_size", 16)
	info_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(info_label)

	var rule_btn_row = HBoxContainer.new()
	rule_btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(rule_btn_row)
	var rule_btn = Button.new()
	rule_btn.text = "规则说明"
	rule_btn.custom_minimum_size = Vector2(160, 40)
	rule_btn.add_theme_font_size_override("font_size", 16)
	UIStyle.apply_button_style(rule_btn)
	rule_btn.pressed.connect( func(): _show_rule_popup(panel))
	rule_btn_row.add_child(rule_btn)

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
	scroll_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(scroll_content)
	panel.set_meta("scroll_content", scroll_content)

	_build_suit_forge_view(panel)
	_setup_mouse_filter(scroll_content)
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

static func _c(text: String, hex: String) -> String:
	return "[color=%s]%s[/color]" % [hex, text]

static func _build_enhance_rule_bbcode() -> String:
	var lines: Array[String] = []
	lines.append(_c("【基本规则】", "#7EC8FF"))
	lines.append("每次消耗 %s；失败扣石。" % _c("套装强化石 x1", "#FFD966"))
	lines.append("成功率通过后随机提升 %s，可选择 %s 或 %s（放弃不退石）。" % [
		_c("1%~9%", "#7DFFB2"), 
		_c("应用", "#FFD966"), 
		_c("放弃", "#FFB07A"), 
	])
	lines.append("")
	lines.append(_c("【各等级成功率】", "#7EC8FF"))
	for lv in range(SuitEquipmentEnhance.MAX_LEVEL):
		var rate: = SuitEquipmentEnhance.success_rate_for_next_level(lv) * 100.0
		lines.append("%s → %s  %s" % [
			_c("+%d" % lv, "#E8C060"), 
			_c("+%d" % (lv + 1), "#E8C060"), 
			_c("%.1f%%" % rate, "#7DFFB2"), 
		])
	lines.append("")
	lines.append(_c("【五件同套套装加成比例】", "#7EC8FF"))
	lines.append("取五件中最低强化等级，在基础 %s 上额外提升：" % _c("30%", "#FFD966"))
	for n in range(1, SuitEquipmentEnhance.MAX_LEVEL + 1):
		var total_pct: = SuitEquipmentEnhance.total_set_bonus_percent(n) * 100.0
		lines.append("五件全部 ≥ %s 时，套装加成 %s" % [
			_c("+%d" % n, "#E8C060"), 
			_c("%.1f%%" % total_pct, "#7DFFB2"), 
		])
	return "\n".join(lines)

static func _build_suit_forge_view(panel: Control):
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
	left_section.add_child(_subsection_title("身上套装"))
	equip_row.add_child(left_section)

	var sel_btn = Button.new()
	sel_btn.text = "选择套装部位"
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

	var set_bonus_label = Label.new()
	set_bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	set_bonus_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	set_bonus_label.add_theme_font_size_override("font_size", 14)
	set_bonus_label.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	right_section.add_child(set_bonus_label)
	panel.set_meta("set_bonus_label", set_bonus_label)

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
	preview_label.text = "请选择身上套装部位"
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
	tip.text = "强化失败扣石；成功后可选择应用或放弃（放弃不退石）"
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.add_theme_font_size_override("font_size", 14)
	tip.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	scroll_content.add_child(tip)

	_update_stone_label(panel)
	_update_set_bonus_hint(panel)
	_update_preview(panel)
	_try_resume_pending_enhance(panel)

static func _try_resume_pending_enhance(panel: Control) -> void :
	var game_manager = panel.get_meta("game_manager")
	if game_manager == null:
		return
	if not str(panel.get_meta("pending_token", "")).is_empty():
		return
	var pending: Dictionary = game_manager.get_suit_enhance_pending()
	if pending.is_empty():
		return
	var token: = str(pending.get("token", "")).strip_edges()
	if token.is_empty():
		return
	var eid: = str(pending.get("equipmentId", pending.get("equipment_id", ""))).strip_edges()
	panel.set_meta("pending_token", token)
	panel.set_meta("confirm_in_flight", false)
	if str(panel.get_meta("selected_equip_id", "")).is_empty() and not eid.is_empty():
		panel.set_meta("selected_equip_id", eid)
		var slot: = str(pending.get("slot", ""))
		if not slot.is_empty():
			panel.set_meta("selected_slot", slot)
		_update_preview(panel)
	var equip_name: = "套装"
	if game_manager.equipment_manager:
		for slot_key in game_manager.equipment_manager.equipped.keys():
			var eq = game_manager.equipment_manager.equipped[slot_key]
			if eq != null and str(eq.id) == eid:
				equip_name = str(eq.name)
				break
	var current_level: = int(pending.get("currentLevel", pending.get("current_level", 0)))
	var result: = {
		"success": true, 
		"needsConfirm": true, 
		"pendingToken": token, 
		"equipmentId": eid, 
		"name": equip_name, 
		"boostPercent": float(pending.get("boostPercent", pending.get("boost_percent", 0))), 
		"currentStats": pending.get("currentStats", pending.get("current_stats", {})), 
		"previewStats": pending.get("previewStats", pending.get("preview_stats", {})), 
		"currentLevel": current_level, 
		"nextLevel": int(pending.get("nextLevel", pending.get("next_level", current_level + 1))), 
	}
	var forge_btn = panel.get_meta("forge_btn") as Button
	if forge_btn:
		forge_btn.disabled = true
	var popup_parent = game_manager.get_tree().current_scene if game_manager.get_tree() else null
	SuitEnhanceResultPopup.show(
		popup_parent, 
		result, 
		func(): _confirm_pending(panel, true), 
		func(): _confirm_pending(panel, false), 
		panel
	)

static func _show_rule_popup(panel: Control) -> void :
	var game_manager = panel.get_meta("game_manager")
	var vsize: = Vector2(540, 620)
	if game_manager and game_manager.get_tree():
		vsize = game_manager.get_tree().root.get_visible_rect().size
	var pw: = mini(540.0, vsize.x - 40.0)
	var ph: = clampf(vsize.y * 0.62, 320.0, 560.0)

	var popup = Window.new()
	popup.title = ""
	popup.borderless = true
	popup.transparent = true
	popup.unresizable = true
	popup.size = Vector2i(int(pw), int(ph))
	popup.close_requested.connect( func(): popup.queue_free())

	var main_panel = Panel.new()
	main_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_panel.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	popup.add_child(main_panel)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	main_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title_label = Label.new()
	title_label.text = "套装强化规则"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(title_label)


	var text_margin = MarginContainer.new()
	text_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_margin.add_theme_constant_override("margin_left", 4)
	text_margin.add_theme_constant_override("margin_top", 4)
	text_margin.add_theme_constant_override("margin_right", 4)
	text_margin.add_theme_constant_override("margin_bottom", 4)
	vbox.add_child(text_margin)

	var rule_label = RichTextLabel.new()
	rule_label.bbcode_enabled = true
	rule_label.fit_content = false
	rule_label.scroll_active = true
	rule_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rule_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rule_label.custom_minimum_size = Vector2(maxi(260.0, pw - 56.0), maxi(200.0, ph - 140.0))
	rule_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rule_label.add_theme_font_size_override("normal_font_size", 14)
	rule_label.add_theme_color_override("default_color", Color(0.78, 0.82, 0.9))
	rule_label.text = _build_enhance_rule_bbcode()
	text_margin.add_child(rule_label)

	var close_btn = Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(140, 48)
	close_btn.add_theme_font_size_override("font_size", 18)
	UIStyle.apply_button_style(close_btn)
	close_btn.pressed.connect( func(): popup.queue_free())
	vbox.add_child(close_btn)

	var scene_root = game_manager.get_tree().current_scene if game_manager and game_manager.get_tree() else null
	if scene_root:
		scene_root.add_child(popup)
	else:
		panel.add_child(popup)
	popup.popup_centered()

static func _setup_mouse_filter(container: Control) -> void :
	if container == null:
		return
	for child in container.get_children():
		if child is Control:
			if child is ScrollContainer:
				child.mouse_filter = Control.MOUSE_FILTER_PASS
			elif child is Button:
				child.mouse_filter = Control.MOUSE_FILTER_STOP
			else:
				child.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if child is Container:
				_setup_mouse_filter(child)

static func _slot_label(slot: String) -> String:
	return str(SLOT_LABELS.get(slot, slot))

static func _get_equipped_suit_dict(panel: Control) -> Dictionary:
	var game_manager = panel.get_meta("game_manager")
	var eid: = str(panel.get_meta("selected_equip_id", ""))
	if eid.is_empty() or game_manager == null or game_manager.equipment_manager == null:
		return {}
	for slot in game_manager.equipment_manager.equipped.keys():
		var eq = game_manager.equipment_manager.equipped[slot]
		if eq == null:
			continue
		if str(eq.id) != eid:
			continue
		if not eq.is_suit or eq.is_sealed:
			return {}
		return eq.to_dict()
	return {}

static func _update_stone_label(panel: Control):
	var game_manager = panel.get_meta("game_manager")
	var stone_label = panel.get_meta("stone_label") as Label
	if not game_manager or not stone_label:
		return
	var n: = 0
	if game_manager.inventory_manager:
		n = game_manager.inventory_manager.get_item_count(SuitEquipmentEnhance.STONE_ITEM)
	stone_label.text = "套装强化石：%d" % n

static func _update_set_bonus_hint(panel: Control):
	var game_manager = panel.get_meta("game_manager")
	var set_bonus_label = panel.get_meta("set_bonus_label") as Label
	if not game_manager or not set_bonus_label or game_manager.suit_manager == null:
		return
	var min_lv: = _get_active_full_set_min_level(game_manager)
	var pct: = SuitEquipmentEnhance.total_set_bonus_percent(min_lv) * 100.0
	if min_lv > 0:
		set_bonus_label.text = "当前五件同套最低 +%d\n套装加成比例：%.1f%%" % [min_lv, pct]
	else:
		set_bonus_label.text = "未凑齐五件同套强化加成\n基础套装加成：30%"

static func _get_active_full_set_min_level(game_manager) -> int:
	if game_manager == null or game_manager.suit_manager == null:
		return 0
	var best: = 0
	for suit_level in game_manager.suit_manager.equipped_suits.keys():
		if not game_manager.suit_manager.is_full_set_equipped(suit_level):
			continue
		var slots: Dictionary = game_manager.suit_manager.equipped_suits.get(suit_level, {})
		var min_lv: = 999
		for eq in slots.values():
			if eq == null:
				continue
			min_lv = mini(min_lv, SuitEquipmentEnhance.get_level_from_equipment(eq))
		if min_lv == 999:
			min_lv = 0
		best = maxi(best, min_lv)
	return best

static func _update_preview(panel: Control):
	var preview_label = panel.get_meta("preview_label") as Label
	var forge_btn = panel.get_meta("forge_btn") as Button
	var equip_name_label = panel.get_meta("equip_name_label") as Label
	var equip_attrs_label = panel.get_meta("equip_attrs_label") as Label
	var game_manager = panel.get_meta("game_manager")
	_update_stone_label(panel)
	_update_set_bonus_hint(panel)
	var d: = _get_equipped_suit_dict(panel)
	var eid: = str(panel.get_meta("selected_equip_id", ""))
	if d.is_empty() or eid.is_empty():
		if equip_name_label:
			equip_name_label.text = "未选择"
		if equip_attrs_label:
			equip_attrs_label.text = ""
		if preview_label:
			preview_label.text = "请选择身上穿戴的套装部位"
		if forge_btn:
			forge_btn.disabled = true
		return
	var lv: = SuitEquipmentEnhance.get_level_from_dict(d)
	var base_name: = str(d.get("name", "套装"))
	var disp: = SuitEquipmentEnhance.format_display_name(base_name, lv)
	if equip_name_label:
		equip_name_label.text = disp
	if equip_attrs_label:
		equip_attrs_label.text = SuitEquipmentEnhance.format_equipment_stats_line(d)
	if lv >= SuitEquipmentEnhance.MAX_LEVEL:
		if preview_label:
			preview_label.text = "已达最高强化等级 +%d" % SuitEquipmentEnhance.MAX_LEVEL
		if forge_btn:
			forge_btn.disabled = true
		return
	var cost: = SuitEquipmentEnhance.stone_cost_for_next_level(lv)
	var rate: = SuitEquipmentEnhance.success_rate_for_next_level(lv)
	var have: = 0
	if game_manager and game_manager.inventory_manager:
		have = game_manager.inventory_manager.get_item_count(SuitEquipmentEnhance.STONE_ITEM)
	if preview_label:
		preview_label.text = "下一级：消耗套装强化石 x%d\n成功率：%.1f%%\n属性提升：随机 1%%~9%%（成功后可选择应用）\n当前持有：%d" % [
			cost, rate * 100.0, have
		]
	if forge_btn:
		forge_btn.disabled = have < cost

static func _is_suit_enhance_ambiguous_error(error: String) -> bool:
	var msg: = str(error).strip_edges()
	if msg.is_empty():
		return false
	return msg.find("网络") >= 0\
	or msg.find("繁忙") >= 0\
	or msg.find("超时") >= 0\
	or msg.find("未能确认是否扣石") >= 0\
	or msg.find("同步云端失败") >= 0

static func _build_result_from_pending_save(data: Dictionary) -> Dictionary:
	var sd: Variant = data.get("saveData", null)
	if not sd is Dictionary:
		return {}
	var gs: Variant = (sd as Dictionary).get("gameSettings", null)
	if not gs is Dictionary:
		return {}
	var pending: Variant = (gs as Dictionary).get("pending_suit_enhance", null)
	if not pending is Dictionary or (pending as Dictionary).is_empty():
		return {}
	var p: Dictionary = pending as Dictionary
	var current_level: = int(p.get("currentLevel", p.get("current_level", 0)))
	return {
		"success": true, 
		"needsConfirm": true, 
		"pendingToken": str(p.get("token", "")), 
		"equipmentId": str(p.get("equipmentId", p.get("equipment_id", ""))), 
		"name": "套装", 
		"boostPercent": float(p.get("boostPercent", p.get("boost_percent", 0))), 
		"currentStats": p.get("currentStats", p.get("current_stats", {})), 
		"previewStats": p.get("previewStats", p.get("preview_stats", {})), 
		"currentLevel": current_level, 
		"nextLevel": int(p.get("nextLevel", p.get("next_level", current_level + 1))), 
	}

static func _on_enhance_pressed(panel: Control):
	var game_manager = panel.get_meta("game_manager")
	var eid: = str(panel.get_meta("selected_equip_id", ""))
	var forge_btn = panel.get_meta("forge_btn") as Button
	if eid.is_empty() or game_manager == null:
		return
	if not game_manager.network or not game_manager.network.is_logged_in():
		_show_result_toast(panel, "当前网络不可用，套装强化需联网并由服务器确认。")
		return
	var equip_dict: = _get_equipped_suit_dict(panel)
	if equip_dict.is_empty():
		_show_result_toast(panel, "未找到待强化的套装装备")
		return
	var lv: = SuitEquipmentEnhance.get_level_from_dict(equip_dict)
	if lv >= SuitEquipmentEnhance.MAX_LEVEL:
		_show_result_toast(panel, "该套装已无法继续强化")
		return
	if game_manager.inventory_manager.get_item_count(SuitEquipmentEnhance.STONE_ITEM) < SuitEquipmentEnhance.stone_cost_for_next_level(lv):
		_show_result_toast(panel, "套装强化石不足")
		return
	if forge_btn:
		forge_btn.disabled = true
	var reuse_ambiguous: = bool(panel.get_meta("suit_enhance_ambiguous_failure", false))
	var last_eid: = str(panel.get_meta("last_suit_enhance_equip_id", ""))
	var last_op: = str(panel.get_meta("last_suit_enhance_op_id", "")).strip_edges()
	var op_id: = last_op if reuse_ambiguous and last_eid == eid and not last_op.is_empty() else "suit_equipment_enhance_%s_%d_%d" % [eid, Time.get_unix_time_from_system(), Time.get_ticks_msec()]
	panel.set_meta("last_suit_enhance_op_id", op_id)
	panel.set_meta("last_suit_enhance_equip_id", eid)
	panel.set_meta("suit_enhance_ambiguous_failure", false)
	var on_success = func(data: Dictionary):
		panel.set_meta("suit_enhance_ambiguous_failure", false)
		panel.set_meta("last_suit_enhance_op_id", "")
		var result: Dictionary = data.get("result", {})
		var needs_confirm: = bool(data.get("needsConfirm", false)) or bool(result.get("needsConfirm", false))
		if result.is_empty() and needs_confirm:
			result = _build_result_from_pending_save(data)
		if game_manager and data.has("saveData") and data.get("saveData") is Dictionary:
			var apply_opts: = {"skip_deferred_cloud_save": true} if needs_confirm else {}
			game_manager.apply_cloud_save(data.get("saveData"), apply_opts)
		if needs_confirm:
			panel.set_meta("pending_token", str(result.get("pendingToken", "")))
			panel.set_meta("confirm_in_flight", false)
			_dismiss_tracked_popup(panel, "suit_toast_popup")
			_dismiss_tracked_popup(panel, "suit_result_popup")
			var popup_parent = game_manager.get_tree().current_scene if game_manager.get_tree() else null
			SuitEnhanceResultPopup.show(
				popup_parent, 
				result, 
				func(): _confirm_pending(panel, true), 
				func(): _confirm_pending(panel, false), 
				panel
			)
		else:
			if forge_btn:
				forge_btn.disabled = false
			_update_preview(panel)
			_show_result_toast(panel, str(data.get("message", "套装强化完成")))
	var on_failed = func(error: String):
		if _is_suit_enhance_ambiguous_error(error):
			panel.set_meta("suit_enhance_ambiguous_failure", true)
		else:
			panel.set_meta("suit_enhance_ambiguous_failure", false)
			panel.set_meta("last_suit_enhance_op_id", "")
		if error.find("请先处理上次套装强化") >= 0:
			_try_resume_pending_enhance(panel)
		if forge_btn:
			forge_btn.disabled = false
		_update_preview(panel)
		if error.find("请先处理上次套装强化") < 0:
			_show_result_toast(panel, error)
	game_manager.network.suit_equipment_enhance_success.connect(on_success, CONNECT_ONE_SHOT)
	game_manager.network.suit_equipment_enhance_failed.connect(on_failed, CONNECT_ONE_SHOT)
	game_manager.network.request_suit_equipment_enhance(eid, op_id)

static func _confirm_pending(panel: Control, accept: bool):
	if bool(panel.get_meta("confirm_in_flight", false)):
		return
	var game_manager = panel.get_meta("game_manager")
	var forge_btn = panel.get_meta("forge_btn") as Button
	var pending_token: = str(panel.get_meta("pending_token", ""))
	if pending_token.is_empty() or game_manager == null or game_manager.network == null:
		if forge_btn:
			forge_btn.disabled = false
		_update_preview(panel)
		return
	panel.set_meta("confirm_in_flight", true)
	if forge_btn:
		forge_btn.disabled = true
	var op_id: = "suit_equipment_enhance_confirm_%s_%d_%d" % [pending_token, Time.get_unix_time_from_system(), Time.get_ticks_msec()]
	var on_success = func(data: Dictionary):
		panel.set_meta("pending_token", "")
		panel.set_meta("confirm_in_flight", false)
		_dismiss_tracked_popup(panel, "suit_result_popup")
		if forge_btn:
			forge_btn.disabled = false
		if game_manager:
			game_manager.clear_suit_enhance_pending()
		if game_manager and data.has("saveData") and data.get("saveData") is Dictionary:
			var apply_opts: = {"skip_deferred_cloud_save": true}
			if accept:
				apply_opts["authoritative_equipment_inventory"] = true
			game_manager.apply_cloud_save(data.get("saveData"), apply_opts)
		_update_preview(panel)
	var on_failed = func(error: String):
		panel.set_meta("pending_token", "")
		panel.set_meta("confirm_in_flight", false)
		_dismiss_tracked_popup(panel, "suit_result_popup")
		if forge_btn:
			forge_btn.disabled = false
		_update_preview(panel)
		_show_result_toast(panel, error)
	game_manager.network.suit_equipment_enhance_confirm_success.connect(on_success, CONNECT_ONE_SHOT)
	game_manager.network.suit_equipment_enhance_confirm_failed.connect(on_failed, CONNECT_ONE_SHOT)
	game_manager.network.request_suit_equipment_enhance_confirm(pending_token, accept, op_id)

static func _dismiss_tracked_popup(panel: Control, meta_key: String) -> void :
	var old_popup = panel.get_meta(meta_key, null)
	if old_popup is Node and is_instance_valid(old_popup):
		old_popup.queue_free()
	panel.set_meta(meta_key, null)

static func _show_result_toast(panel: Control, msg: String):
	var game_manager = panel.get_meta("game_manager")
	if game_manager == null or str(msg).is_empty():
		return
	_dismiss_tracked_popup(panel, "suit_toast_popup")
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
		title.text = "套装强化"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 22)
		title.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
		vbox.add_child(title)
		var result_label = Label.new()
		result_label.text = msg
		result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		result_label.add_theme_font_size_override("font_size", 20)
		var ok_color: = Color(0.4, 1.0, 0.4) if msg.find("成功") >= 0 or msg.find("应用") >= 0 else Color(1.0, 0.6, 0.4)
		result_label.add_theme_color_override("font_color", ok_color)
		vbox.add_child(result_label)
		var ok_btn = Button.new()
		ok_btn.text = "确定"
		ok_btn.custom_minimum_size = Vector2(120, 45)
		UIStyle.apply_golden_button_style(ok_btn)
		var _toast_closed: = false
		ok_btn.pressed.connect( func():
			if _toast_closed:
				return
			_toast_closed = true
			ok_btn.disabled = true
			popup.hide()
			panel.set_meta("suit_toast_popup", null)
			popup.queue_free()
		)
		vbox.add_child(ok_btn)
		panel.set_meta("suit_toast_popup", popup)
		tree.current_scene.add_child(popup)
		popup.popup_centered()

static func _show_equipment_picker(panel: Control):
	var game_manager = panel.get_meta("game_manager")
	if game_manager == null or game_manager.equipment_manager == null:
		return
	var popup = Window.new()
	popup.title = "选择身上套装部位"
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

	var order: = ["weapon", "armor", "helmet", "boots", "accessory"]
	for slot in order:
		var eq = game_manager.equipment_manager.equipped.get(slot)
		if eq == null or not eq.is_suit or eq.is_sealed:
			continue
		vbox.add_child(_make_pick_row(panel, popup, eq, slot))

	if vbox.get_child_count() == 0:
		var empty_l = Label.new()
		empty_l.text = "当前没有穿戴套装部件"
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

static func _make_pick_row(panel: Control, popup: Window, eq, slot: String) -> Control:
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
	var lv: = SuitEquipmentEnhance.get_level_from_equipment(eq)
	var nm: = SuitEquipmentEnhance.format_display_name(str(eq.name), lv)
	var lbl = Label.new()
	lbl.text = "%s  [%s]" % [nm, _slot_label(slot)]
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 16)
	hb.add_child(lbl)
	var bid: = str(eq.id)
	var btn = Button.new()
	btn.text = "选择"
	btn.custom_minimum_size = Vector2(72, 32)
	UIStyle.apply_button_style(btn)
	btn.pressed.connect( func():
		panel.set_meta("selected_equip_id", bid)
		panel.set_meta("selected_slot", slot)
		popup.queue_free()
		_update_preview(panel)
	)
	hb.add_child(btn)
	return h
