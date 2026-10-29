extends RefCounted
class_name MartialArtsUI

const GameData = preload("res://scripts/game_data.gd")
const UIConstants = preload("res://scripts/ui_constants.gd")
const ConfirmDialog = preload("res://ui/components/confirm_dialog.gd")

static func show(parent: Node, martial_arts_manager, player) -> Window:
	var window = Window.new()
	window.title = "武功系统"
	window.size = Vector2(600, 700)
	window.borderless = true
	window.transparent = true
	window.unresizable = true
	window.close_requested.connect( func(): window.queue_free())

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 15
	vbox.offset_top = 15
	vbox.offset_right = -15
	vbox.offset_bottom = -15
	vbox.add_theme_constant_override("separation", 10)

	var title_label = Label.new()
	title_label.text = "🥋 武功系统"
	title_label.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title_label)

	var info_hbox = HBoxContainer.new()
	info_hbox.add_theme_constant_override("separation", 20)

	var count_label = Label.new()
	count_label.text = "已学武功: %d/%d" % [martial_arts_manager.martial_arts.size(), MartialArtsManager.MAX_MARTIAL_ARTS]
	count_label.add_theme_font_size_override("font_size", 18)
	info_hbox.add_child(count_label)

	var equipped_label = Label.new()
	equipped_label.text = "已装备: %d/%d" % [martial_arts_manager.equipped_arts.size(), MartialArtsManager.MAX_EQUIPPED]
	equipped_label.add_theme_font_size_override("font_size", 18)
	equipped_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1))
	info_hbox.add_child(equipped_label)

	vbox.add_child(info_hbox)

	var separator1 = HSeparator.new()
	vbox.add_child(separator1)

	var equipped_section = _create_equipped_section(martial_arts_manager, window, parent, player)
	vbox.add_child(equipped_section)

	var separator2 = HSeparator.new()
	vbox.add_child(separator2)

	var learned_label = Label.new()
	learned_label.text = "📚 已学武功"
	learned_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(learned_label)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.scroll_deadzone = 20
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS

	var arts_list = VBoxContainer.new()
	arts_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arts_list.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	arts_list.add_theme_constant_override("separation", 8)

	var all_arts = martial_arts_manager.get_all_arts()
	for i in range(all_arts.size()):
		var art = all_arts[i]
		var art_panel = _create_art_panel(art, martial_arts_manager, window, parent, player, i)
		arts_list.add_child(art_panel)

	if all_arts.is_empty():
		var empty_label = Label.new()
		empty_label.text = "尚未学习任何武功，点击\"参悟武功\"学习..."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 16)
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		arts_list.add_child(empty_label)

	scroll.add_child(arts_list)
	vbox.add_child(scroll)

	var btn_hbox = HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 15)
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var learn_btn = Button.new()
	learn_btn.text = "参悟武功"
	learn_btn.custom_minimum_size = Vector2(120, 45)
	learn_btn.add_theme_font_size_override("font_size", 18)
	learn_btn.add_theme_color_override("font_color", Color(0.4, 0.8, 1))
	if GameManager.instance and GameManager.instance.network and GameManager.instance.network.is_logged_in():
		if not martial_arts_manager.is_server_martial_count_ready():
			learn_btn.disabled = true
			learn_btn.text = "同步次数中..."
		martial_arts_manager.daily_count_changed.connect( func(count: int, max_count: int):
			if is_instance_valid(learn_btn):
				if not martial_arts_manager.is_server_martial_count_ready():
					learn_btn.disabled = true
					learn_btn.text = "无法同步次数"
				elif count >= max_count:
					learn_btn.disabled = true
					learn_btn.text = "今日次数已用完"
				else:
					learn_btn.disabled = false
					learn_btn.text = "参悟武功"
		)
		martial_arts_manager.refresh_server_count()
	learn_btn.pressed.connect( func():
		if not GameManager.instance or not GameManager.instance.network or not GameManager.instance.network.is_logged_in():
			_show_learn_failed(parent, "当前网络不可用，已阻止参悟。\n为防止断网SL，参悟需联网并完成云端确认。")
			return
		if not martial_arts_manager.is_server_martial_count_ready():
			_show_learn_failed(parent, "正在同步今日自创次数，请稍候或检查网络后重试。")
			return
		var result = await martial_arts_manager.learn_martial_art(player.realm)

		if bool(result.get("success", false)):
			GameManager.instance.save_game(false)
			_show_learn_result(parent, result)
		else:
			_show_learn_failed(parent, result.message)
		_refresh_window(window, parent, martial_arts_manager, player)
	)
	btn_hbox.add_child(learn_btn)

	var close_btn = Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(120, 45)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect( func(): window.queue_free())
	btn_hbox.add_child(close_btn)

	vbox.add_child(btn_hbox)

	panel.add_child(vbox)
	window.add_child(panel)
	parent.add_child(window)
	window.popup_centered()

	return window

static func _create_equipped_section(martial_arts_manager, window: Window, parent: Node, player) -> Control:
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", 8)

	var equipped_title = Label.new()
	equipped_title.text = "⚔️ 已装备武功 (最多2个)"
	equipped_title.add_theme_font_size_override("font_size", 20)
	section.add_child(equipped_title)

	var slots_hbox = HBoxContainer.new()
	slots_hbox.add_theme_constant_override("separation", 15)
	slots_hbox.alignment = BoxContainer.ALIGNMENT_CENTER

	for i in range(MartialArtsManager.MAX_EQUIPPED):
		var slot_panel = PanelContainer.new()
		slot_panel.custom_minimum_size = Vector2(260, 90)

		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.12, 0.15, 1)
		style.set_border_width_all(2)
		style.border_color = Color(0.3, 0.4, 0.5, 1)
		slot_panel.add_theme_stylebox_override("panel", style)

		var vbox = VBoxContainer.new()
		vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		vbox.offset_left = 10
		vbox.offset_top = 8
		vbox.offset_right = -10
		vbox.offset_bottom = -8
		vbox.add_theme_constant_override("separation", 4)

		var slot_label = Label.new()
		slot_label.text = "槽位 %d" % (i + 1)
		slot_label.add_theme_font_size_override("font_size", 18)
		slot_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		vbox.add_child(slot_label)

		if i < martial_arts_manager.equipped_arts.size():
			var art = martial_arts_manager.equipped_arts[i]

			var name_label = Label.new()
			name_label.text = art.name
			name_label.add_theme_font_size_override("font_size", 18)
			name_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
			vbox.add_child(name_label)

			var effect_label = Label.new()
			effect_label.text = art.get_effect_description() + " (%d层)" % art.layer
			effect_label.add_theme_font_size_override("font_size", 18)
			effect_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
			vbox.add_child(effect_label)
		else:
			var empty_label = Label.new()
			empty_label.text = "空"
			empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
			empty_label.add_theme_font_size_override("font_size", 16)
			empty_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
			empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			vbox.add_child(empty_label)

		slot_panel.add_child(vbox)
		slots_hbox.add_child(slot_panel)

	section.add_child(slots_hbox)
	return section

static func _create_art_panel(art, martial_arts_manager, window: Window, parent: Node, player, index: int) -> Control:
	var item_panel = PanelContainer.new()
	item_panel.custom_minimum_size = Vector2(0, 60)

	var bg_color = Color(0.1, 0.1, 0.12, 1) if index % 2 == 0 else Color(0.08, 0.08, 0.1, 1)
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_border_width_all(1)
	style.border_color = Color(0.25, 0.25, 0.3, 1)
	item_panel.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 10
	hbox.offset_top = 5
	hbox.offset_right = -10
	hbox.offset_bottom = -5
	hbox.add_theme_constant_override("separation", 12)

	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 2)

	var name_hbox = HBoxContainer.new()
	name_hbox.add_theme_constant_override("separation", 10)

	var name_label = Label.new()
	name_label.text = art.name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1) if art.equipped else Color(0.7, 0.7, 0.7))
	name_hbox.add_child(name_label)

	var realm_label = Label.new()
	realm_label.text = "[%s]" % art.realm
	realm_label.add_theme_font_size_override("font_size", 18)
	realm_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	name_hbox.add_child(realm_label)

	if art.equipped:
		var equipped_mark = Label.new()
		equipped_mark.text = "【已装备】"
		equipped_mark.add_theme_font_size_override("font_size", 18)
		equipped_mark.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
		name_hbox.add_child(equipped_mark)

	info_vbox.add_child(name_hbox)

	var desc_label = Label.new()
	desc_label.text = "%s | %d层" % [art.get_effect_description(), art.layer]
	desc_label.add_theme_font_size_override("font_size", 18)
	desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	info_vbox.add_child(desc_label)

	hbox.add_child(info_vbox)

	if art.equipped:
		var unequip_btn = Button.new()
		unequip_btn.text = "卸下"
		unequip_btn.custom_minimum_size = Vector2(60, 38)
		unequip_btn.add_theme_font_size_override("font_size", 18)
		unequip_btn.pressed.connect( func():
			martial_arts_manager.unequip_martial_art(art)
			_refresh_window(window, parent, martial_arts_manager, player)
		)
		hbox.add_child(unequip_btn)
	else:
		if martial_arts_manager.equipped_arts.size() < MartialArtsManager.MAX_EQUIPPED:
			var equip_btn = Button.new()
			equip_btn.text = "装备"
			equip_btn.custom_minimum_size = Vector2(60, 38)
			equip_btn.add_theme_font_size_override("font_size", 18)
			equip_btn.pressed.connect( func():
				martial_arts_manager.equip_martial_art(art)
				_refresh_window(window, parent, martial_arts_manager, player)
			)
			hbox.add_child(equip_btn)

	item_panel.add_child(hbox)
	return item_panel

static func _show_learn_result(parent: Node, result: Dictionary):
	var window = Window.new()
	window.title = "参悟成功"
	window.size = Vector2(400, 200)
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
	title_label.text = "🎉 参悟成功！"
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	var msg_label = Label.new()
	msg_label.text = result.message
	msg_label.add_theme_font_size_override("font_size", 16)
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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

static func _show_learn_failed(parent: Node, message: String):
	var window = Window.new()
	window.title = "参悟失败"
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

	var msg_label = Label.new()
	msg_label.text = message
	msg_label.add_theme_font_size_override("font_size", 16)
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
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

static func _refresh_window(old_window: Window, parent: Node, martial_arts_manager, player):
	old_window.queue_free()
	await old_window.tree_exited
	show(parent, martial_arts_manager, player)
