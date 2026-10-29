extends RefCounted

const UIStyle = preload("res://scripts/ui_style.gd")
const SuitEquipmentEnhance = preload("res://scripts/suit/suit_equipment_enhance.gd")

static func show(
	parent_node: Node, 
	result_data: Dictionary, 
	on_apply: Callable, 
	on_reject: Callable, 
	track_panel: Control = null
) -> void :
	if parent_node == null:
		return
	var boost_pct: = float(result_data.get("boostPercent", result_data.get("boost_percent", 0)))
	var current_stats: Dictionary = result_data.get("currentStats", result_data.get("current_stats", {}))
	var preview_stats: Dictionary = result_data.get("previewStats", result_data.get("preview_stats", {}))
	var current_level: = int(result_data.get("currentLevel", result_data.get("current_level", 0)))
	var next_level: = int(result_data.get("nextLevel", result_data.get("next_level", current_level + 1)))
	var equip_name: = str(result_data.get("name", "套装"))

	var popup = Window.new()
	popup.title = ""
	popup.borderless = true
	popup.transparent = true
	popup.unresizable = true
	popup.min_size = Vector2(480, 420)
	popup.size = Vector2(480, 420)
	if track_panel:
		track_panel.set_meta("suit_result_popup", popup)

	var reject_btn: Button
	var apply_btn: Button
	var _closed: = false
	var _finish = func(apply_cb: Callable):
		if _closed:
			return
		_closed = true
		if reject_btn:
			reject_btn.disabled = true
		if apply_btn:
			apply_btn.disabled = true
		popup.hide()
		if track_panel:
			track_panel.set_meta("suit_result_popup", null)
		popup.queue_free()
		if apply_cb.is_valid():
			apply_cb.call_deferred()

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	popup.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_top = 16
	vbox.offset_right = -20
	vbox.offset_bottom = -16
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "强化成功！请选择是否应用"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(title)

	var name_label = Label.new()
	name_label.text = "%s  +%d → +%d" % [equip_name, current_level, next_level]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(name_label)

	var boost_label = Label.new()
	boost_label.text = "本次属性提升：+%.1f%%" % (boost_pct * 100.0)
	boost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boost_label.add_theme_font_size_override("font_size", 18)
	boost_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6))
	vbox.add_child(boost_label)

	var before_label = Label.new()
	before_label.text = "当前：%s" % SuitEquipmentEnhance.format_stats_line(current_stats)
	before_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	before_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	before_label.add_theme_font_size_override("font_size", 15)
	before_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	vbox.add_child(before_label)

	var after_label = Label.new()
	after_label.text = "应用后：%s" % SuitEquipmentEnhance.format_stats_line(preview_stats)
	after_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	after_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	after_label.add_theme_font_size_override("font_size", 15)
	after_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	vbox.add_child(after_label)

	var tip = Label.new()
	tip.text = "放弃后等级与属性不变，但强化石已消耗"
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.add_theme_font_size_override("font_size", 13)
	tip.add_theme_color_override("font_color", Color(0.65, 0.7, 0.8))
	vbox.add_child(tip)

	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_row)

	reject_btn = Button.new()
	reject_btn.text = "放弃本次结果"
	reject_btn.custom_minimum_size = Vector2(150, 44)
	UIStyle.apply_button_style(reject_btn)
	reject_btn.pressed.connect( func(): _finish.call(on_reject))
	btn_row.add_child(reject_btn)

	apply_btn = Button.new()
	apply_btn.text = "应用本次结果"
	apply_btn.custom_minimum_size = Vector2(150, 44)
	UIStyle.apply_golden_button_style(apply_btn)
	apply_btn.pressed.connect( func(): _finish.call(on_apply))
	btn_row.add_child(apply_btn)

	parent_node.add_child(popup)
	popup.popup_centered()
