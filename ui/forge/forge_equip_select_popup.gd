extends RefCounted
class_name ForgeEquipSelectPopup

const UIStyle = preload("res://scripts/ui_style.gd")
const ForgeConfig = preload("res://scripts/forge/forge_config.gd")
const ForgeData = preload("res://scripts/forge/forge_data.gd")

signal equipment_selected(equipment: Dictionary, type: String)

static func show_popup(parent: Control, type: String, game_manager) -> Window:
	var popup = Window.new()
	popup.title = ""
	popup.borderless = true
	popup.transparent = true
	popup.unresizable = true
	popup.min_size = Vector2(500, 600)
	popup.size = Vector2(500, 600)

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
	title.text = "选择%s" % ("主炼装备" if type == "main" else "副炼材料")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(title)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var list_container = VBoxContainer.new()
	list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list_container)

	if type == "main":
		_populate_main_equipment_list(list_container, popup, parent, game_manager)
	else:
		_populate_sub_equipment_list(list_container, popup, parent, game_manager)

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

static func _populate_main_equipment_list(container: VBoxContainer, popup: Window, parent: Control, game_manager):
	if not game_manager or not game_manager.equipment_manager:
		var empty_label = Label.new()
		empty_label.text = "暂无已穿戴装备"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		container.add_child(empty_label)
		return

	var equipped = game_manager.equipment_manager.equipped
	var has_equipped: = false

	for slot in equipped.keys():
		var equipment = equipped[slot]
		if equipment:
			has_equipped = true
			_add_equipment_item(container, popup, parent, equipment.to_dict(), "main")
	if not has_equipped:
		var empty_label = Label.new()
		empty_label.text = "请先穿戴装备后再进行极限打造"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		container.add_child(empty_label)

static func _populate_sub_equipment_list(container: VBoxContainer, popup: Window, parent: Control, game_manager):
	if not game_manager or not game_manager.inventory_manager:
		var empty_label = Label.new()
		empty_label.text = "背包系统未初始化"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		container.add_child(empty_label)
		return

	var aggregate_entries: Array = game_manager.inventory_manager.get_limit_material_bag_aggregates()
	if aggregate_entries.is_empty():
		var empty_label = Label.new()
		empty_label.text = "背包中没有极限装备\n可通过藏宝洞抽奖、活动或邮件等途径获取"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		container.add_child(empty_label)
		return

	for aggregate in aggregate_entries:
		var representative = aggregate.get("representative_item", null)
		if representative == null:
			continue
		var display_name = ForgeData.normalize_limit_material_name(str(aggregate.get("name", representative.name)))
		var custom_data = representative.custom_data.duplicate()
		if str(custom_data.get("slot", "")).is_empty() or str(custom_data.get("attr", "")).is_empty():
			var meta = ForgeData.limit_material_slot_attr(display_name)
			if str(custom_data.get("slot", "")).is_empty():
				custom_data["slot"] = str(meta.get("slot", ""))
			if str(custom_data.get("attr", "")).is_empty():
				custom_data["attr"] = str(meta.get("attr", ""))
		var equipment = {
			"id": representative.id, 
			"name": display_name, 
			"slot": custom_data.get("slot", ""), 
			"count": int(aggregate.get("count", 1)), 
			"is_limit": true, 
			"aggregate_entry": aggregate, 
		}
		var attr = str(custom_data.get("attr", ""))
		if not attr.is_empty():
			equipment[attr] = ForgeConfig.get_limit_value(attr)
		_add_limit_equip_item(container, popup, parent, equipment, int(aggregate.get("count", 1)))

static func _add_limit_equip_item(container: VBoxContainer, popup: Window, parent: Control, equipment: Dictionary, count: int):
	var item_panel = Panel.new()
	item_panel.custom_minimum_size = Vector2(0, 60)
	item_panel.add_theme_stylebox_override("panel", UIStyle.create_item_style())

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 10
	hbox.offset_top = 5
	hbox.offset_right = -10
	hbox.offset_bottom = -5
	hbox.add_theme_constant_override("separation", 10)
	item_panel.add_child(hbox)

	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(info_vbox)

	var name_label = Label.new()
	name_label.text = "%s x%d" % [equipment.get("name", "未知"), count]
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(1, 0.6, 0.2))
	info_vbox.add_child(name_label)

	var slot_label = Label.new()
	slot_label.text = ForgeConfig.get_slot_name(equipment.get("slot", ""))
	slot_label.add_theme_font_size_override("font_size", 16)
	slot_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	info_vbox.add_child(slot_label)

	var select_btn = Button.new()
	select_btn.text = "选择"
	select_btn.custom_minimum_size = Vector2(60, 30)
	UIStyle.apply_button_style(select_btn)
	select_btn.pressed.connect( func():
		var CraftingMainUI = load("res://ui/forge/crafting_main_ui.gd")
		CraftingMainUI.on_equipment_selected(parent, equipment, "sub")
		popup.queue_free()
	)
	hbox.add_child(select_btn)

	container.add_child(item_panel)

static func _add_equipment_item(container: VBoxContainer, popup: Window, parent: Control, equipment: Dictionary, type: String):
	var item_panel = Panel.new()
	item_panel.custom_minimum_size = Vector2(0, 60)
	item_panel.add_theme_stylebox_override("panel", UIStyle.create_item_style())

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 10
	hbox.offset_top = 5
	hbox.offset_right = -10
	hbox.offset_bottom = -5
	hbox.add_theme_constant_override("separation", 10)
	item_panel.add_child(hbox)

	var name_label = Label.new()
	name_label.text = equipment.get("name", "未知装备")
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_label)

	var slot_label = Label.new()
	slot_label.text = ForgeConfig.get_slot_name(equipment.get("slot", ""))
	slot_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	hbox.add_child(slot_label)

	var select_btn = Button.new()
	select_btn.text = "选择"
	select_btn.custom_minimum_size = Vector2(60, 30)
	UIStyle.apply_button_style(select_btn)
	select_btn.pressed.connect( func():
		var CraftingMainUI = load("res://ui/forge/crafting_main_ui.gd")
		CraftingMainUI.on_equipment_selected(parent, equipment, type)
		popup.queue_free()
	)
	hbox.add_child(select_btn)

	container.add_child(item_panel)
