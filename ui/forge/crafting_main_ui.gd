extends RefCounted



const LegacyForgeMainUI = preload("res://ui/forge/forge_main_ui.gd")
const PetEquipmentForgeUI = preload("res://ui/forge/pet_equipment_forge_ui.gd")
const SuitEquipmentForgeUI = preload("res://ui/forge/suit_equipment_forge_ui.gd")
const UIStyle = preload("res://scripts/ui_style.gd")

static func create_fullscreen(game_manager) -> Control:
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", UIStyle.create_panel_style())
	panel.set_meta("game_manager", game_manager)

	var vbox = UIStyle.create_base_vbox()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(vbox)

	var tab_hbox = HBoxContainer.new()
	tab_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(tab_hbox)

	var tab_forge = Button.new()
	tab_forge.text = "极限打造"
	tab_forge.custom_minimum_size = Vector2(120, 40)
	tab_forge.add_theme_font_size_override("font_size", 16)
	UIStyle.apply_tab_style(tab_forge, true)
	tab_hbox.add_child(tab_forge)

	var tab_pet = Button.new()
	tab_pet.text = "宠装强化"
	tab_pet.custom_minimum_size = Vector2(120, 40)
	tab_pet.add_theme_font_size_override("font_size", 16)
	UIStyle.apply_tab_style(tab_pet, false)
	tab_hbox.add_child(tab_pet)

	var tab_suit = Button.new()
	tab_suit.text = "套装强化"
	tab_suit.custom_minimum_size = Vector2(120, 40)
	tab_suit.add_theme_font_size_override("font_size", 16)
	UIStyle.apply_tab_style(tab_suit, false)
	tab_hbox.add_child(tab_suit)

	var stack = Control.new()
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(stack)

	var forge_root = LegacyForgeMainUI.create_fullscreen(game_manager)
	forge_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	stack.add_child(forge_root)

	var tab_contents: Array = [forge_root, null, null]
	var tab_keys: = ["forge", "pet", "suit"]
	var tab_buttons: = [tab_forge, tab_pet, tab_suit]

	var ensure_pet_root: = func() -> Control:
		var cached: Control = tab_contents[1]
		if cached != null and is_instance_valid(cached):
			return cached
		var pet_root: = PetEquipmentForgeUI.create_fullscreen(game_manager)
		pet_root.set_anchors_preset(Control.PRESET_FULL_RECT)
		pet_root.visible = false
		stack.add_child(pet_root)
		tab_contents[1] = pet_root
		return pet_root

	var ensure_suit_root: = func() -> Control:
		var cached: Control = tab_contents[2]
		if cached != null and is_instance_valid(cached):
			return cached
		var suit_root: = SuitEquipmentForgeUI.create_fullscreen(game_manager)
		suit_root.set_anchors_preset(Control.PRESET_FULL_RECT)
		suit_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		suit_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
		suit_root.visible = false
		stack.add_child(suit_root)
		tab_contents[2] = suit_root
		return suit_root

	var _apply_tab = func(active: String):
		var active_idx: = tab_keys.find(active)
		if active_idx < 0:
			active_idx = 0
		if active_idx == 1:
			ensure_pet_root.call()
		elif active_idx == 2:
			ensure_suit_root.call()
		for i in range(tab_contents.size()):
			var content: Control = tab_contents[i]
			if content != null and is_instance_valid(content):
				content.visible = (i == active_idx)
		for i in range(tab_buttons.size()):
			UIStyle.apply_tab_style(tab_buttons[i], i == active_idx)

	tab_forge.pressed.connect( func(): _apply_tab.call("forge"))
	tab_pet.pressed.connect( func(): _apply_tab.call("pet"))
	tab_suit.pressed.connect( func(): _apply_tab.call("suit"))

	return panel

static func on_equipment_selected(panel: Control, equipment: Dictionary, type: String):
	LegacyForgeMainUI.on_equipment_selected(panel, equipment, type)
