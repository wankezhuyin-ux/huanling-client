class_name PetEquipmentUI

const PetEquipmentData = preload("res://scripts/pet_equipment/pet_equipment_data.gd")
const UIStyle = preload("res://scripts/ui_style.gd")

static func create_panel(game_manager) -> Control:
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)

	panel.set_meta("game_manager", game_manager)
	panel.set_meta("main_vbox", vbox)

	_refresh_panel(panel)

	if game_manager and game_manager.pet_equipment_manager:
		game_manager.pet_equipment_manager.equipment_changed.connect( func(slot, equipment): _refresh_panel(panel))
		game_manager.pet_equipment_manager.bonus_changed.connect( func(bonus): _refresh_panel(panel))
	if game_manager and game_manager.inventory_manager:
		game_manager.inventory_manager.pet_equipment_inventory_changed.connect( func(): _refresh_panel(panel))
		game_manager.inventory_manager.pet_equipment_warehouse_changed.connect( func(): _refresh_panel(panel))

	return panel

static func _refresh_panel(panel: Control):
	var vbox = panel.get_meta("main_vbox") as VBoxContainer
	var game_manager = panel.get_meta("game_manager")

	if not vbox or not game_manager:
		return

	for child in vbox.get_children():
		child.queue_free()

	var pet_manager = game_manager.pet_manager
	var pet_equipment_manager = game_manager.pet_equipment_manager

	var active_pet = pet_manager.get_active_pet() if pet_manager else null

	var title_label = Label.new()
	title_label.text = "宠物装备"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	vbox.add_child(title_label)

	var pet_info = Label.new()
	if active_pet:
		pet_info.text = "当前出战: %s Lv.%d  成长: %.3f" % [active_pet.pet_name, active_pet.level, active_pet.total_growth]
	else:
		pet_info.text = "当前出战: 无"
	pet_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pet_info.add_theme_font_size_override("font_size", 18)
	vbox.add_child(pet_info)

	var separator1 = HSeparator.new()
	vbox.add_child(separator1)

	var equipped_title = Label.new()
	equipped_title.text = "已穿戴装备"
	equipped_title.add_theme_font_size_override("font_size", 20)
	equipped_title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	vbox.add_child(equipped_title)

	var equipment_grid = GridContainer.new()
	equipment_grid.columns = 2
	equipment_grid.add_theme_constant_override("h_separation", 20)
	equipment_grid.add_theme_constant_override("v_separation", 15)
	vbox.add_child(equipment_grid)

	var slots = PetEquipmentData.get_all_slots()
	for slot in slots:
		var slot_panel = _create_slot_panel(slot, game_manager)
		equipment_grid.add_child(slot_panel)

	var separator2 = HSeparator.new()
	vbox.add_child(separator2)

	var bonus_title = Label.new()
	bonus_title.text = "装备加成总计"
	bonus_title.add_theme_font_size_override("font_size", 20)
	bonus_title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	vbox.add_child(bonus_title)

	var bonus = pet_equipment_manager.get_all_bonus(active_pet) if pet_equipment_manager else {"attack": 0, "defense": 0, "agility": 0, "hp": 0}

	var bonus_label = Label.new()
	bonus_label.text = "攻击 +%.0f  防御 +%.0f  敏捷 +%.0f  生命 +%.0f" % [bonus.attack, bonus.defense, bonus.agility, bonus.hp]
	bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bonus_label.add_theme_font_size_override("font_size", 18)
	if active_pet == null:
		bonus_label.text += "\n(无出战宠物时装备不生效)"
		bonus_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	vbox.add_child(bonus_label)

	var hint_label = Label.new()
	hint_label.text = "\n提示: 宠物装备请在背包-宠物装备标签页中操作"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 14)
	hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(hint_label)

static func _create_slot_panel(slot: String, game_manager) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(280, 120)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	style.border_color = Color(0.3, 0.3, 0.4)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 15
	vbox.offset_top = 10
	vbox.offset_right = -15
	vbox.offset_bottom = -10
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)

	var slot_name = PetEquipmentData.get_slot_name(slot)
	var stat_name = PetEquipmentData.get_slot_stat(slot)

	var title_label = Label.new()
	title_label.text = slot_name
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	vbox.add_child(title_label)

	var pet_equipment_manager = game_manager.pet_equipment_manager if game_manager else null
	var equipment = pet_equipment_manager.get_equipped(slot) if pet_equipment_manager else null

	if equipment:
		var name_label = Label.new()
		name_label.text = equipment.name
		name_label.add_theme_font_size_override("font_size", 16)
		name_label.add_theme_color_override("font_color", _get_rarity_color(equipment.rarity))
		vbox.add_child(name_label)

		var stat_label = Label.new()
		var stat_value = 0
		match stat_name:
			"attack": stat_value = equipment.attack
			"defense": stat_value = equipment.defense
			"agility": stat_value = equipment.agility
			"hp": stat_value = equipment.hp
		stat_label.text = "%s +%d" % [PetEquipmentData.get_stat_name(stat_name), stat_value]
		stat_label.add_theme_font_size_override("font_size", 14)
		stat_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1))
		vbox.add_child(stat_label)

		var unequip_btn = Button.new()
		unequip_btn.text = "卸下"
		unequip_btn.custom_minimum_size = Vector2(60, 30)
		unequip_btn.add_theme_font_size_override("font_size", 14)
		UIStyle.apply_button_style(unequip_btn)
		unequip_btn.pressed.connect( func():
			_unequip_slot(slot, game_manager)
		)
		vbox.add_child(unequip_btn)
	else:
		var empty_label = Label.new()
		empty_label.text = "未装备"
		empty_label.add_theme_font_size_override("font_size", 14)
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		vbox.add_child(empty_label)

	return panel

static func _unequip_slot(slot: String, game_manager):
	if not game_manager or not game_manager.pet_equipment_manager:
		return
	if not game_manager.network or not game_manager.network.is_logged_in():
		_show_message_dialog("无法卸下", "当前网络不可用，宠物装备卸下需联网并由服务器确认。")
		return

	if game_manager.inventory_manager.pet_equipment_items.size() >= game_manager.inventory_manager.MAX_PET_EQUIPMENT_INVENTORY:
		_show_message_dialog("无法卸下", "宠物装备背包已满，无法卸下装备，请先清理背包")
		return

	var op_id: = "pet_equipment_unequip_%s_%d_%d" % [slot, Time.get_unix_time_from_system(), Time.get_ticks_msec()]
	var on_success = func(data: Dictionary):
		if game_manager and data.has("saveData") and data.get("saveData") is Dictionary:
			game_manager.apply_cloud_save(data.get("saveData"), {"authoritative_equipment_inventory": true})
		# 回包里的 `equipped` 才是权威结果；`saveData` 万一没带
		# `petEquipmentData`（老版本服务端），槽位就刷不出来。
		if game_manager and game_manager.pet_equipment_manager and data.get("equipped") is Dictionary:
			game_manager.pet_equipment_manager.from_dict({"equipped": data.get("equipped")})
		_show_message_dialog("卸下成功", str(data.get("message", "已卸下宠物装备")))
	var on_failed = func(error: String):
		_show_message_dialog("卸下失败", error)
	game_manager.network.pet_equipment_unequip_success.connect(on_success, CONNECT_ONE_SHOT)
	game_manager.network.pet_equipment_unequip_failed.connect(on_failed, CONNECT_ONE_SHOT)
	game_manager.network.request_pet_equipment_unequip(slot, op_id)

static func _get_rarity_color(rarity: String) -> Color:
	var colors = {
		"common": Color(0.7, 0.7, 0.7), 
		"uncommon": Color(0.2, 0.9, 0.2), 
		"rare": Color(0.2, 0.5, 1), 
		"epic": Color(0.8, 0.2, 0.9), 
		"legendary": Color(1, 0.5, 0), 
		"mythic": Color(1, 0.2, 0.2), 
		"divine": Color(1, 0.8, 0), 
		"suit": Color(1, 0.6, 0)
	}
	return colors.get(rarity, Color(0.7, 0.7, 0.7))

static func _show_message_dialog(title: String, message: String):
	var popup = Window.new()
	popup.title = ""
	popup.size = Vector2i(420, 280)
	popup.transparent = true
	popup.borderless = true
	popup.unresizable = true

	var main_panel = Panel.new()
	main_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_panel.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	popup.add_child(main_panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 25
	vbox.offset_top = 25
	vbox.offset_right = -25
	vbox.offset_bottom = -25
	vbox.add_theme_constant_override("separation", 20)
	main_panel.add_child(vbox)

	var title_label = Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(title_label)

	var msg_label = Label.new()
	msg_label.text = message
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.add_theme_font_size_override("font_size", 18)
	msg_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(msg_label)

	var ok_btn = Button.new()
	ok_btn.text = "确定"
	UIStyle.style_popup_button(ok_btn, true)
	ok_btn.pressed.connect( func(): popup.queue_free())
	vbox.add_child(ok_btn)

	var scene_root = Engine.get_main_loop().current_scene
	if scene_root:
		scene_root.add_child(popup)
		popup.popup_centered()
