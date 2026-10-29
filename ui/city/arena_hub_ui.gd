class_name ArenaHubUI
extends RefCounted

const UIStyle = preload("res://scripts/ui_style.gd")
const PetRaiseRaceUIScript = preload("res://ui/city/pet_raise_race_ui.gd")

static func _create_placeholder_panel(message: String) -> Control:
	var panel: = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var label: = Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.734, 0.714, 0.657))
	panel.add_child(label)
	return panel

static func create_fullscreen(game_manager) -> Control:
	var panel: = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", UIStyle.create_panel_style())

	var world_boss_tab_btn: = Button.new()
	world_boss_tab_btn.text = "世界boss"
	world_boss_tab_btn.custom_minimum_size = Vector2(120, 40)
	world_boss_tab_btn.add_theme_font_size_override("font_size", 16)

	var arena_tab_btn: = Button.new()
	arena_tab_btn.text = "竞技场"
	arena_tab_btn.custom_minimum_size = Vector2(120, 40)
	arena_tab_btn.add_theme_font_size_override("font_size", 16)

	var pet_duel_tab_btn: = Button.new()
	pet_duel_tab_btn.text = "养宠赛"
	pet_duel_tab_btn.custom_minimum_size = Vector2(120, 40)
	pet_duel_tab_btn.add_theme_font_size_override("font_size", 16)

	var world_boss_content: = WorldBossUI.create_content(game_manager, panel)
	world_boss_content.name = "world_boss_content"
	world_boss_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	world_boss_content.offset_top = 52
	panel.add_child(world_boss_content)

	var tab_contents: Array = [world_boss_content, null, null]

	var ensure_arena_content: = func() -> Control:
		var cached: Control = tab_contents[1]
		if cached != null and is_instance_valid(cached):
			return cached
		var arena_content: = ArenaUI.create_content(game_manager, panel)
		arena_content.name = "arena_content"
		arena_content.set_anchors_preset(Control.PRESET_FULL_RECT)
		arena_content.offset_top = 52
		arena_content.visible = false
		panel.add_child(arena_content)
		tab_contents[1] = arena_content
		return arena_content

	var ensure_pet_duel_content: = func() -> Control:
		var cached: Control = tab_contents[2]
		if cached != null and is_instance_valid(cached):
			return cached
		var pet_duel_content: = PetRaiseRaceUIScript.create_content(game_manager, panel)
		pet_duel_content.name = "pet_duel_content"
		pet_duel_content.set_anchors_preset(Control.PRESET_FULL_RECT)
		pet_duel_content.offset_top = 52
		pet_duel_content.visible = false
		panel.add_child(pet_duel_content)
		tab_contents[2] = pet_duel_content
		return pet_duel_content

	var tab_hbox: = HBoxContainer.new()
	tab_hbox.anchor_left = 0.0
	tab_hbox.anchor_right = 1.0
	tab_hbox.anchor_top = 0.0
	tab_hbox.offset_top = 8
	tab_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_hbox.add_theme_constant_override("separation", 20)
	tab_hbox.add_child(world_boss_tab_btn)
	tab_hbox.add_child(arena_tab_btn)
	tab_hbox.add_child(pet_duel_tab_btn)
	panel.add_child(tab_hbox)

	var tab_buttons: = [world_boss_tab_btn, arena_tab_btn, pet_duel_tab_btn]

	var switch_tab: = func(active_idx: int):
		if active_idx == 1:
			ensure_arena_content.call()
		elif active_idx == 2:
			ensure_pet_duel_content.call()
		for i in range(tab_contents.size()):
			var content: Control = tab_contents[i]
			if content != null and is_instance_valid(content):
				content.visible = (i == active_idx)
		for i in range(tab_buttons.size()):
			UIStyle.apply_tab_style(tab_buttons[i], i == active_idx)
		if active_idx == 0:
			WorldBossUI.refresh_panel(game_manager, world_boss_content)
		elif active_idx == 1:
			var arena_content: Control = tab_contents[1]
			if arena_content != null and is_instance_valid(arena_content):
				ArenaUI.refresh_panel(game_manager, arena_content)
		elif active_idx == 2:
			var race_content: Control = tab_contents[2]
			if race_content != null and is_instance_valid(race_content):
				PetRaiseRaceUIScript.refresh_panel(game_manager, race_content)

	world_boss_tab_btn.pressed.connect( func(): switch_tab.call(0))
	arena_tab_btn.pressed.connect( func(): switch_tab.call(1))
	pet_duel_tab_btn.pressed.connect( func(): switch_tab.call(2))

	switch_tab.call(0)
	panel.set_meta("switch_arena_tab", switch_tab)
	return panel
