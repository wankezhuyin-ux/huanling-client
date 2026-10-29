extends RefCounted
class_name SaveUI

const GameData = preload("res://scripts/game_data.gd")
const UIConstants = preload("res://scripts/ui_constants.gd")
const ConfirmDialog = preload("res://ui/components/confirm_dialog.gd")

static func show(parent: Node, game_manager) -> Window:
	var window = Window.new()
	window.title = "存档管理"
	window.size = Vector2(500, 450)
	window.borderless = true
	window.transparent = true
	window.unresizable = true
	window.close_requested.connect( func(): window.queue_free())

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 15)

	var title_label = Label.new()
	title_label.text = "💾 存档管理"
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	var separator1 = HSeparator.new()
	vbox.add_child(separator1)

	var has_save = game_manager.has_save()

	var save_info_section = _create_save_info_section(game_manager, has_save)
	vbox.add_child(save_info_section)

	var separator2 = HSeparator.new()
	vbox.add_child(separator2)

	var btn_vbox = VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 12)
	btn_vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var save_btn = Button.new()
	save_btn.text = "💾 保存游戏"
	save_btn.custom_minimum_size = Vector2(250, 50)
	save_btn.add_theme_font_size_override("font_size", 20)
	save_btn.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
	save_btn.pressed.connect( func():
		var success = game_manager.save_game()
		if success:
			_show_result_dialog(parent, "保存成功", "游戏已成功保存！", Color(0.4, 0.8, 0.4))
		else:
			_show_result_dialog(parent, "保存失败", "保存游戏失败，请重试！", Color(1, 0.5, 0.5))
		_refresh_window(window, parent, game_manager)
	)
	btn_vbox.add_child(save_btn)

	var load_btn = Button.new()
	load_btn.text = "📂 读取存档"
	load_btn.custom_minimum_size = Vector2(250, 50)
	load_btn.add_theme_font_size_override("font_size", 20)
	load_btn.add_theme_color_override("font_color", Color(0.5, 0.8, 1))
	load_btn.disabled = not has_save
	load_btn.pressed.connect( func():
		ConfirmDialog.show(parent, "读取确认", 
			"确定要读取存档吗？\n当前未保存的进度将丢失！", 
			func():
				var success = game_manager.load_game()
				if success:
					_show_result_dialog(parent, "读取成功", "存档已成功读取！", Color(0.4, 0.8, 0.4))
				else:
					_show_result_dialog(parent, "读取失败", "读取存档失败，存档可能已损坏！", Color(1, 0.5, 0.5))
				_refresh_window(window, parent, game_manager)
		)
	)
	btn_vbox.add_child(load_btn)

	vbox.add_child(btn_vbox)

	var close_btn = Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(150, 45)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect( func(): window.queue_free())
	vbox.add_child(close_btn)

	panel.add_child(vbox)
	window.add_child(panel)
	parent.add_child(window)
	window.popup_centered()

	return window

static func _create_save_info_section(game_manager, has_save: bool) -> Control:
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", 10)

	var status_label = Label.new()
	if has_save:
		status_label.text = "状态: 存档存在"
		status_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
	else:
		status_label.text = "状态: 无存档"
		status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section.add_child(status_label)

	if has_save:
		var save_info = _get_save_info()

		if not save_info.is_empty():
			var info_grid = GridContainer.new()
			info_grid.columns = 2
			info_grid.add_theme_constant_override("h_separation", 15)
			info_grid.add_theme_constant_override("v_separation", 6)

			var info_items = []

			if save_info.has("timestamp"):
				var datetime = Time.get_datetime_dict_from_unix_time(save_info.timestamp)
				var time_str = "%04d-%02d-%02d %02d:%02d:%02d" % [
					datetime.year, datetime.month, datetime.day, 
					datetime.hour, datetime.minute, datetime.second
				]
				info_items.append(["保存时间", time_str, Color(0.7, 0.7, 0.7)])

			if save_info.has("player"):
				var player_data = save_info.player
				info_items.append(["角色等级", "Lv.%d" % player_data.get("level", 1), Color(0.5, 1, 0.5)])
				info_items.append(["角色境界", player_data.get("realm", "凡人"), Color(1, 0.84, 0)])
				info_items.append(["金币", "%d" % player_data.get("gold", 0), Color(1, 0.84, 0)])

			if save_info.has("pets"):
				var pets_data = save_info.pets
				var pet_count = pets_data.get("pets", []).size() if pets_data is Dictionary else 0
				info_items.append(["宠物数量", "%d只" % pet_count, Color(0.5, 0.8, 1)])

			if save_info.has("current_map"):
				info_items.append(["当前地图", save_info.current_map, Color(0.7, 0.7, 0.7)])

			for item in info_items:
				var label_name = Label.new()
				label_name.text = item[0] + ":"
				label_name.add_theme_font_size_override("font_size", 18)
				label_name.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
				label_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				info_grid.add_child(label_name)

				var label_value = Label.new()
				label_value.text = item[1]
				label_value.add_theme_font_size_override("font_size", 18)
				label_value.add_theme_color_override("font_color", item[2])
				info_grid.add_child(label_value)

			section.add_child(info_grid)
	else:
		var no_save_label = Label.new()
		no_save_label.text = "尚未创建存档，点击\"保存游戏\"创建新存档"
		no_save_label.add_theme_font_size_override("font_size", 18)
		no_save_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		no_save_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_save_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		section.add_child(no_save_label)

	return section

static func _get_save_info() -> Dictionary:
	if FileAccess.file_exists("user://save_game.dat"):
		var save_file = FileAccess.open("user://save_game.dat", FileAccess.READ)
		if save_file:
			var encrypted = save_file.get_buffer(save_file.get_length())
			save_file.close()
			var save_data = _decrypt_save_data(encrypted)
			if not save_data.is_empty():
				return save_data

	return {}

static func _get_save_password() -> String:
	var base_key = "HL2024_SAVE_KEY_"
	var version_part = str(2)
	var hash_part = str("huanling".hash()).substr(0, 8)
	return base_key + version_part + "_" + hash_part

static func _decrypt_save_data(encrypted: PackedByteArray) -> Dictionary:
	if encrypted.size() < 8:
		return {}

	var password = _get_save_password()
	var key = password.to_utf8_buffer()

	var data_size = encrypted.size() - 8
	var data_bytes = PackedByteArray()

	for i in range(data_size):
		var key_index = i % key.size()
		data_bytes.append(encrypted[i] ^ key[key_index])

	var stored_checksum = encrypted.slice(data_size, encrypted.size())
	var calculated_checksum = _sha256_hash(data_bytes).slice(0, 8)

	if stored_checksum != calculated_checksum:
		return {}

	var json_string = data_bytes.get_string_from_utf8()
	var json = JSON.new()
	if json.parse(json_string) != OK:
		return {}

	return json.get_data()

static func _sha256_hash(data: PackedByteArray) -> PackedByteArray:
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(data)
	return ctx.finish()

static func _show_result_dialog(parent: Node, title: String, message: String, color: Color):
	var window = Window.new()
	window.title = title
	window.size = Vector2(350, 180)
	window.borderless = true
	window.transparent = true
	window.unresizable = true
	window.close_requested.connect( func(): window.queue_free())

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 15)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", color)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	var msg_label = Label.new()
	msg_label.text = message
	msg_label.add_theme_font_size_override("font_size", 16)
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(msg_label)

	var close_btn = Button.new()
	close_btn.text = "确定"
	close_btn.custom_minimum_size = Vector2(100, 40)
	close_btn.pressed.connect( func(): window.queue_free())
	vbox.add_child(close_btn)

	panel.add_child(vbox)
	window.add_child(panel)
	parent.add_child(window)
	window.popup_centered()

static func _refresh_window(old_window: Window, parent: Node, game_manager):
	old_window.queue_free()
	await old_window.tree_exited
	show(parent, game_manager)
