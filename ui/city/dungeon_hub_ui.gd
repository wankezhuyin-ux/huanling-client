class_name DungeonHubUI
extends RefCounted

const UIStyle = preload("res://scripts/ui_style.gd")

static func create_fullscreen(game_manager) -> Control:
	var panel: = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", UIStyle.create_panel_style())

	var suit_tab_btn: = Button.new()
	suit_tab_btn.text = "套装副本"
	suit_tab_btn.custom_minimum_size = Vector2(120, 40)
	suit_tab_btn.add_theme_font_size_override("font_size", 16)

	var elements_tab_btn: = Button.new()
	elements_tab_btn.text = "五行副本"
	elements_tab_btn.custom_minimum_size = Vector2(120, 40)
	elements_tab_btn.add_theme_font_size_override("font_size", 16)

	var atlas_tab_btn: = Button.new()
	atlas_tab_btn.text = "图鉴副本"
	atlas_tab_btn.custom_minimum_size = Vector2(120, 40)
	atlas_tab_btn.add_theme_font_size_override("font_size", 16)

	var suit_content: = SuitDungeonUI.create_fullscreen(game_manager)
	suit_content.name = "suit_content"
	suit_content.offset_top = 52
	panel.add_child(suit_content)


	var tab_contents: Array = [suit_content, null, null]

	var ensure_elements_content: = func() -> Control:
		var cached: Control = tab_contents[1]
		if cached != null and is_instance_valid(cached):
			return cached
		var elements_content: = FiveElementsDungeonUI.create_content(game_manager, panel)
		elements_content.name = "elements_content"
		elements_content.set_anchors_preset(Control.PRESET_FULL_RECT)
		elements_content.offset_top = 52
		elements_content.visible = false
		panel.add_child(elements_content)
		tab_contents[1] = elements_content
		return elements_content

	var ensure_atlas_content: = func() -> Control:
		var cached: Control = tab_contents[2]
		if cached != null and is_instance_valid(cached):
			return cached
		var atlas_content: = AtlasDungeonUI.create_content(game_manager, panel)
		atlas_content.name = "atlas_content"
		atlas_content.set_anchors_preset(Control.PRESET_FULL_RECT)
		atlas_content.offset_top = 52
		atlas_content.visible = false
		panel.add_child(atlas_content)
		tab_contents[2] = atlas_content
		return atlas_content

	var tab_hbox: = HBoxContainer.new()
	tab_hbox.anchor_left = 0.0
	tab_hbox.anchor_right = 1.0
	tab_hbox.anchor_top = 0.0
	tab_hbox.offset_top = 8
	tab_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_hbox.add_theme_constant_override("separation", 20)
	tab_hbox.add_child(suit_tab_btn)
	tab_hbox.add_child(elements_tab_btn)
	tab_hbox.add_child(atlas_tab_btn)
	panel.add_child(tab_hbox)

	var tab_buttons: = [suit_tab_btn, elements_tab_btn, atlas_tab_btn]

	var switch_tab: = func(active_idx: int):
		if active_idx == 1:
			ensure_elements_content.call()
		elif active_idx == 2:
			ensure_atlas_content.call()
		for i in range(tab_contents.size()):
			var content: Control = tab_contents[i]
			if content != null and is_instance_valid(content):
				content.visible = (i == active_idx)
		for i in range(tab_buttons.size()):
			UIStyle.apply_tab_style(tab_buttons[i], i == active_idx)
		if active_idx == 1:
			FiveElementsDungeonUI.refresh_panel(game_manager, panel)
		elif active_idx == 2:
			AtlasDungeonUI.refresh_panel_and_sync(game_manager, panel)
		elif active_idx == 0:
			SuitDungeonUI.refresh_panel(game_manager, suit_content)

	suit_tab_btn.pressed.connect( func(): switch_tab.call(0))
	elements_tab_btn.pressed.connect( func(): switch_tab.call(1))
	atlas_tab_btn.pressed.connect( func(): switch_tab.call(2))

	switch_tab.call(0)

	return panel
