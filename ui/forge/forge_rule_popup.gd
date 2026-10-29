extends RefCounted
class_name ForgeRulePopup

const UIStyle = preload("res://scripts/ui_style.gd")
const ForgeConfig = preload("res://scripts/forge/forge_config.gd")

static func show_popup(parent: Control, main_equipment: Dictionary, sub_equipment: Dictionary, forge_manager) -> Window:
	var popup = Window.new()
	popup.title = ""
	popup.borderless = true
	popup.transparent = true
	popup.unresizable = true
	popup.min_size = Vector2(500, 500)
	popup.size = Vector2(500, 500)

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	popup.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "转移规则"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(title)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var list_container = VBoxContainer.new()
	list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_container.add_theme_constant_override("separation", 10)
	scroll.add_child(list_container)

	var attrs = forge_manager.get_transferable_attributes(main_equipment.get("slot", ""))
	for attr_info in attrs:
		_add_rule_item(list_container, attr_info, main_equipment, sub_equipment)

	var close_btn = Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(0, 40)
	UIStyle.apply_button_style(close_btn)
	close_btn.pressed.connect( func(): popup.queue_free())
	vbox.add_child(close_btn)

	var scene_root = Engine.get_main_loop().current_scene
	if scene_root:
		scene_root.add_child(popup)
		popup.popup_centered()
	else:
		parent.add_child(popup)
		popup.popup_centered()

	return popup

static func _add_rule_item(container: VBoxContainer, attr_info: Dictionary, main_equipment: Dictionary, sub_equipment: Dictionary):
	var item_panel = Panel.new()
	item_panel.add_theme_stylebox_override("panel", UIStyle.create_item_style())

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 10
	vbox.offset_top = 8
	vbox.offset_right = -10
	vbox.offset_bottom = -8
	vbox.add_theme_constant_override("separation", 5)
	item_panel.add_child(vbox)

	var header = HBoxContainer.new()
	vbox.add_child(header)

	var priority_label = Label.new()
	priority_label.text = "优先级%d" % attr_info.priority
	priority_label.add_theme_font_size_override("font_size", 16)
	header.add_child(priority_label)

	var attr_label = Label.new()
	attr_label.text = attr_info.attr_name
	attr_label.add_theme_font_size_override("font_size", 20)
	attr_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(attr_label)

	var max_rate_label = Label.new()
	max_rate_label.text = "上限 %.0f%%" % (attr_info.max_rate * 100)
	max_rate_label.add_theme_font_size_override("font_size", 16)
	header.add_child(max_rate_label)

	var detail1 = Label.new()
	detail1.text = "每次转移: %.0f%% ~ %.0f%% (随机)" % [attr_info.per_transfer_min * 100, attr_info.per_transfer_max * 100]
	detail1.add_theme_font_size_override("font_size", 16)
	detail1.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	vbox.add_child(detail1)

	var detail2 = Label.new()
	detail2.text = "代价: %s (转移值的 %.0f%%)" % [attr_info.cost_attr_name, ForgeConfig.COST_RATE * 100]
	detail2.add_theme_font_size_override("font_size", 16)
	detail2.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	vbox.add_child(detail2)

	container.add_child(item_panel)
