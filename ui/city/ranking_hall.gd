extends RefCounted

const UIStyle = preload("res://scripts/ui_style.gd")

static func _create_ranking_tab_btn(text: String, tooltip: String) -> Button:
	var btn: = Button.new()
	btn.text = text
	btn.tooltip_text = tooltip
	var min_w: int = maxi(56, text.length() * 15 + 12)
	btn.custom_minimum_size = Vector2(min_w, 36)
	btn.add_theme_font_size_override("font_size", 14)
	return btn

static func _apply_ranking_tab_styles(active: String, buttons: Dictionary, tab_scroll: ScrollContainer = null) -> void :
	for key in buttons.keys():
		UIStyle.apply_tab_style(buttons[key], key == active)
	if tab_scroll and buttons.has(active):
		var btn: Control = buttons[active]
		tab_scroll.call_deferred("ensure_control_visible", btn)

static func create_fullscreen(game_manager) -> Control:
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.set_script(preload("res://ui/city/ranking_hall_panel.gd"))
	panel.add_theme_stylebox_override("panel", UIStyle.create_panel_style())

	var vbox = UIStyle.create_base_vbox()
	panel.add_child(vbox)

	var title = UIStyle.create_title_label("🏆 排行榜")
	vbox.add_child(title)

	var tab_scroll: = ScrollContainer.new()
	tab_scroll.custom_minimum_size = Vector2(0, 42)
	tab_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tab_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	tab_scroll.follow_focus = true
	vbox.add_child(tab_scroll)

	var tab_container = HBoxContainer.new()
	tab_container.add_theme_constant_override("separation", 6)
	tab_container.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	tab_scroll.add_child(tab_container)

	var player_tab_btn = _create_ranking_tab_btn("玩家", "玩家排行榜")
	tab_container.add_child(player_tab_btn)

	var pet_evolution_tab_btn = _create_ranking_tab_btn("可进化宠", "可进化宠物排行榜")
	tab_container.add_child(pet_evolution_tab_btn)

	var pet_non_evolution_tab_btn = _create_ranking_tab_btn("不可进化", "不可进化宠物排行榜")
	tab_container.add_child(pet_non_evolution_tab_btn)

	var tower_tab_btn = _create_ranking_tab_btn("无限天关", "无限天关排行榜")
	tab_container.add_child(tower_tab_btn)

	var suit_dungeon_tab_btn = _create_ranking_tab_btn("套装副本", "套装副本排行榜")
	tab_container.add_child(suit_dungeon_tab_btn)

	var gang_tab_btn = _create_ranking_tab_btn("帮派", "帮派排行榜")
	tab_container.add_child(gang_tab_btn)

	var tab_buttons: = {
		"players": player_tab_btn, 
		"pets_evolution": pet_evolution_tab_btn, 
		"pets_non_evolution": pet_non_evolution_tab_btn, 
		"tower": tower_tab_btn, 
		"suit_dungeon": suit_dungeon_tab_btn, 
		"gang": gang_tab_btn, 
	}
	_apply_ranking_tab_styles("players", tab_buttons, tab_scroll)

	var content_container = VBoxContainer.new()
	content_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_container.add_theme_constant_override("separation", 10)
	vbox.add_child(content_container)

	panel.set_meta("content_container", content_container)
	panel.set_meta("tab_scroll", tab_scroll)
	panel.set_meta("player_tab_btn", player_tab_btn)
	panel.set_meta("pet_evolution_tab_btn", pet_evolution_tab_btn)
	panel.set_meta("pet_non_evolution_tab_btn", pet_non_evolution_tab_btn)
	panel.set_meta("tower_tab_btn", tower_tab_btn)
	panel.set_meta("suit_dungeon_tab_btn", suit_dungeon_tab_btn)
	panel.set_meta("gang_tab_btn", gang_tab_btn)
	panel.set_meta("tab_buttons", tab_buttons)
	panel.set_meta("game_manager", game_manager)
	panel.set_meta("current_type", "players")

	player_tab_btn.pressed.connect( func():
		_apply_ranking_tab_styles("players", tab_buttons, tab_scroll)
		panel.load_rankings("players")
	)

	pet_evolution_tab_btn.pressed.connect( func():
		_apply_ranking_tab_styles("pets_evolution", tab_buttons, tab_scroll)
		panel.load_rankings("pets_evolution")
	)

	pet_non_evolution_tab_btn.pressed.connect( func():
		_apply_ranking_tab_styles("pets_non_evolution", tab_buttons, tab_scroll)
		panel.load_rankings("pets_non_evolution")
	)

	tower_tab_btn.pressed.connect( func():
		_apply_ranking_tab_styles("tower", tab_buttons, tab_scroll)
		panel.load_rankings("tower")
	)

	suit_dungeon_tab_btn.pressed.connect( func():
		_apply_ranking_tab_styles("suit_dungeon", tab_buttons, tab_scroll)
		panel.load_rankings("suit_dungeon")
	)

	gang_tab_btn.pressed.connect( func():
		_apply_ranking_tab_styles("gang", tab_buttons, tab_scroll)
		panel.load_rankings("gang")
	)

	return panel
