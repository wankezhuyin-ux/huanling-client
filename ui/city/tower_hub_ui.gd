class_name TowerHubUI
extends RefCounted


const UIStyle = preload("res://scripts/ui_style.gd")
const TowerUI = preload("res://ui/city/tower_ui.gd")
const BROTHER_TOWER_UI_SCRIPT_PATH: = "res://ui/city/brother_tower_ui.gd"

static func _bt_ui() -> GDScript:
	return load(BROTHER_TOWER_UI_SCRIPT_PATH) as GDScript

static func _ensure_bt_tab_panel(tab_contents: Array, game_manager, panel: Control) -> void :
	var cached: Variant = tab_contents[1]
	if cached is Control and is_instance_valid(cached):
		return
	var bt_ui: GDScript = _bt_ui()
	if bt_ui == null:
		push_error("[TowerHubUI] 兄弟天关脚本加载失败")
		return
	var content_node: Control = bt_ui.call("create_content", game_manager, panel) as Control
	if content_node == null:
		return
	content_node.name = "brother_tower_content"
	content_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_node.offset_top = 52
	content_node.visible = false
	panel.add_child(content_node)
	tab_contents[1] = content_node

static func _switch_tower_tab(tab_contents: Array, tab_buttons: Array, game_manager, panel: Control, active_idx: int) -> void :
	if active_idx == 1:
		_ensure_bt_tab_panel(tab_contents, game_manager, panel)
	for i in range(tab_contents.size()):
		var content: Variant = tab_contents[i]
		if content is Control and is_instance_valid(content):
			(content as Control).visible = (i == active_idx)
	UIStyle.apply_tab_style(tab_buttons[0], active_idx == 0)
	UIStyle.apply_tab_style(tab_buttons[1], active_idx == 1)
	if active_idx == 1:
		var bt_ui: GDScript = _bt_ui()
		if bt_ui != null:
			bt_ui.call("ensure_signals_connected", game_manager, panel)
			bt_ui.call("refresh_panel", game_manager, panel)
		if game_manager and game_manager.network:
			game_manager.network.get_brother_tower_list()
			game_manager.network.get_brother_tower_status()

static func create_fullscreen(game_manager, target_floor: int = -1) -> Control:
	print("[TowerHubUI] rev=v9_207 create_fullscreen")
	var panel: Panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", UIStyle.create_panel_style())

	var infinite_tab_btn: Button = Button.new()
	infinite_tab_btn.text = "无限天关"
	infinite_tab_btn.custom_minimum_size = Vector2(120, 40)
	infinite_tab_btn.add_theme_font_size_override("font_size", 16)

	var brother_tab_btn: Button = Button.new()
	brother_tab_btn.text = "兄弟天关"
	brother_tab_btn.custom_minimum_size = Vector2(120, 40)
	brother_tab_btn.add_theme_font_size_override("font_size", 16)

	var infinite_content: Control = TowerUI.create_fullscreen(game_manager, target_floor)
	if infinite_content == null or not is_instance_valid(infinite_content):
		push_error("[TowerHubUI] 无限天关页创建失败")
		var err_lbl: = Label.new()
		err_lbl.text = "天关界面加载失败，请返回重试"
		err_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		err_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		err_lbl.offset_top = 52
		panel.add_child(err_lbl)
		return panel
	infinite_content.name = "infinite_tower_content"
	infinite_content.offset_top = 52
	panel.add_child(infinite_content)


	var tab_contents: Array = [infinite_content, null]

	var tab_hbox: HBoxContainer = HBoxContainer.new()
	tab_hbox.anchor_left = 0.0
	tab_hbox.anchor_right = 1.0
	tab_hbox.anchor_top = 0.0
	tab_hbox.offset_top = 8
	tab_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_hbox.add_theme_constant_override("separation", 20)
	tab_hbox.add_child(infinite_tab_btn)
	tab_hbox.add_child(brother_tab_btn)
	panel.add_child(tab_hbox)

	var tab_buttons: Array = [infinite_tab_btn, brother_tab_btn]

	infinite_tab_btn.pressed.connect( func(): _switch_tower_tab(tab_contents, tab_buttons, game_manager, panel, 0))
	brother_tab_btn.pressed.connect( func(): _switch_tower_tab(tab_contents, tab_buttons, game_manager, panel, 1))

	_switch_tower_tab(tab_contents, tab_buttons, game_manager, panel, 0)
	return panel
