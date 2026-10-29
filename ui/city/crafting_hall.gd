extends RefCounted

const GameData = preload("res://scripts/game_data.gd")
const UIStyle = preload("res://scripts/ui_style.gd")
const EvolutionData = preload("res://scripts/evolution_data.gd")
const _PET_REFINE_RPC_WAIT_MS: int = 60000

static func create_fullscreen(game_manager) -> Control:
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", UIStyle.create_panel_style())

	var vbox = UIStyle.create_base_vbox()
	panel.add_child(vbox)


	var title = UIStyle.create_title_label("乾坤炉")
	vbox.add_child(title)


	var info_label = Label.new()
	info_label.text = "炼化宠物、转换套装、炼制丹药"
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 16)
	info_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(info_label)


	var tab_hbox = HBoxContainer.new()
	tab_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(tab_hbox)

	var pet_refine_tab_btn = Button.new()
	pet_refine_tab_btn.text = "宠物炼化"
	pet_refine_tab_btn.custom_minimum_size = Vector2(120, 40)
	pet_refine_tab_btn.add_theme_font_size_override("font_size", 16)
	UIStyle.apply_tab_style(pet_refine_tab_btn, true)
	tab_hbox.add_child(pet_refine_tab_btn)

	var equip_tab_btn = Button.new()
	equip_tab_btn.text = "套装转换"
	equip_tab_btn.custom_minimum_size = Vector2(120, 40)
	equip_tab_btn.add_theme_font_size_override("font_size", 16)
	UIStyle.apply_tab_style(equip_tab_btn, false)
	tab_hbox.add_child(equip_tab_btn)

	var pill_tab_btn = Button.new()
	pill_tab_btn.text = "丹药炼制"
	pill_tab_btn.custom_minimum_size = Vector2(120, 40)
	pill_tab_btn.add_theme_font_size_override("font_size", 16)
	UIStyle.apply_tab_style(pill_tab_btn, false)
	tab_hbox.add_child(pill_tab_btn)


	var content_container = VBoxContainer.new()
	content_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_container.add_theme_constant_override("separation", 10)
	vbox.add_child(content_container)


	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.scroll_deadzone = 20
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.name = "ScrollContainer"
	content_container.add_child(scroll)

	var scroll_content = VBoxContainer.new()
	scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_content.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	scroll_content.offset_left = 10
	scroll_content.offset_top = 10
	scroll_content.offset_right = -10
	scroll_content.offset_bottom = -10
	scroll_content.add_theme_constant_override("separation", 15)
	scroll_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll_content.name = "ScrollContent"
	scroll.add_child(scroll_content)


	panel.set_meta("content_container", content_container)
	panel.set_meta("scroll_content", scroll_content)
	panel.set_meta("game_manager", game_manager)
	panel.set_meta("current_tab", "pet_refine")
	panel.set_meta("equip_tab_btn", equip_tab_btn)
	panel.set_meta("pill_tab_btn", pill_tab_btn)
	panel.set_meta("pet_refine_tab_btn", pet_refine_tab_btn)


	_build_craft_view_adapted(panel, scroll_content, game_manager)

	equip_tab_btn.pressed.connect( func():
		_switch_tab(panel, "suit_convert")
	)
	pill_tab_btn.pressed.connect( func():
		_switch_tab(panel, "pill")
	)
	pet_refine_tab_btn.pressed.connect( func():
		_switch_tab(panel, "pet_refine")
	)

	return panel

static func _build_craft_view_adapted(panel: Control, scroll_content: VBoxContainer, game_manager):
	if not game_manager or not game_manager.player:
		var no_player_label = Label.new()
		no_player_label.text = "No player data"
		no_player_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		scroll_content.add_child(no_player_label)
		return

	var player = game_manager.player

	var current_tab = panel.get_meta("current_tab")
	match current_tab:
		"pill":
			_build_pill_tab(panel, scroll_content, player, game_manager)
		"pet_refine":
			_build_pet_refine_tab(panel, scroll_content, game_manager)
		"suit_convert":
			_build_suit_convert_tab(panel, scroll_content, game_manager)

	_setup_mouse_filter(scroll_content)

static func _switch_tab(panel: Control, tab: String):
	panel.set_meta("current_tab", tab)
	_refresh_tab_button_styles(panel)
	_rebuild_craft_view(panel, panel.get_meta("game_manager"))

static func _refresh_tab_button_styles(panel: Control):
	var equip_tab_btn = panel.get_meta("equip_tab_btn") as Button
	var pill_tab_btn = panel.get_meta("pill_tab_btn") as Button
	var pet_refine_tab_btn = panel.get_meta("pet_refine_tab_btn") as Button
	var current_tab = panel.get_meta("current_tab")
	UIStyle.apply_tab_style(equip_tab_btn, current_tab == "suit_convert")
	UIStyle.apply_tab_style(pill_tab_btn, current_tab == "pill")
	UIStyle.apply_tab_style(pet_refine_tab_btn, current_tab == "pet_refine")

static func _build_suit_convert_tab(panel: Control, scroll_content: VBoxContainer, game_manager):
	var section = _create_section_vbox("套装转换")
	scroll_content.add_child(section)
	if not game_manager or not game_manager.equipment_manager:
		var no_data_label = Label.new()
		no_data_label.text = "装备系统未初始化"
		no_data_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		section.add_child(no_data_label)
		return
	if not panel.has_meta("suit_convert_selected_ids"):
		panel.set_meta("suit_convert_selected_ids", [])
	var selected = _get_selected_suit_convert_pieces(panel, game_manager)
	var desc = Label.new()
	desc.text = "放入3件同名、已解封、未强化、未锁定的套装。转换后消耗这3件，随机获得1件同名新套装（部位随机，数值为该部位的90%～110%）。"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	section.add_child(desc)
	var preview = Label.new()
	var suit_name: = _suit_convert_group_name(selected)
	preview.text = "当前材料：%d/3  %s" % [selected.size(), suit_name if suit_name != "" else "未选择套装"]
	preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview.add_theme_font_size_override("font_size", 18)
	preview.add_theme_color_override("font_color", Color(1, 0.84, 0))
	section.add_child(preview)
	var slot_row = HBoxContainer.new()
	slot_row.alignment = BoxContainer.ALIGNMENT_CENTER
	slot_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slot_row.add_theme_constant_override("separation", 8)
	section.add_child(slot_row)
	for i in range(3):
		var slot_panel = Panel.new()
		slot_panel.custom_minimum_size = Vector2(120, 148)
		slot_panel.add_theme_stylebox_override("panel", UIStyle.create_item_style())
		slot_row.add_child(slot_panel)
		var slot_vbox = VBoxContainer.new()
		slot_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		slot_vbox.offset_left = 6
		slot_vbox.offset_top = 6
		slot_vbox.offset_right = -6
		slot_vbox.offset_bottom = -6
		slot_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		slot_panel.add_child(slot_vbox)
		var slot_label = Label.new()
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_label.add_theme_font_size_override("font_size", 14)
		slot_label.add_theme_color_override("font_color", Color(0.631, 0.611, 0.564))
		slot_vbox.add_child(slot_label)
		var name_label = Label.new()
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.add_theme_font_size_override("font_size", 14)
		slot_vbox.add_child(name_label)
		var stat_label = Label.new()
		stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stat_label.add_theme_font_size_override("font_size", 14)
		stat_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
		slot_vbox.add_child(stat_label)
		if i < selected.size():
			var piece = selected[i]
			var piece_icon: = _suit_piece_icon(piece)
			if piece_icon:
				slot_label.visible = false
				var icon_rect: = _make_icon_rect(piece_icon, 48)
				slot_vbox.add_child(icon_rect)
				slot_vbox.move_child(icon_rect, 0)
			else:
				slot_label.text = "材料%d" % (i + 1)
			name_label.text = str(piece.name)
			stat_label.text = _suit_piece_stat_text(piece)
		else:
			slot_label.text = "空槽"
			name_label.text = "待放入"
			stat_label.text = ""
	var convert_btn = Button.new()
	convert_btn.text = "开始转换"
	convert_btn.custom_minimum_size = Vector2(140, 48)
	convert_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	convert_btn.add_theme_font_size_override("font_size", 18)
	UIStyle.apply_golden_button_style(convert_btn)
	convert_btn.disabled = not _suit_convert_selection_ready(selected)
	convert_btn.pressed.connect( func():
		_on_suit_convert_pressed(panel, game_manager, convert_btn)
	)
	section.add_child(convert_btn)
	var action_row = HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	action_row.add_theme_constant_override("separation", 10)
	section.add_child(action_row)
	var auto_fill_btn = Button.new()
	auto_fill_btn.text = "一键放入"
	auto_fill_btn.custom_minimum_size = Vector2(120, 40)
	auto_fill_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UIStyle.apply_button_style(auto_fill_btn)
	auto_fill_btn.pressed.connect( func():
		_auto_fill_suit_convert(panel, game_manager)
	)
	action_row.add_child(auto_fill_btn)
	var clear_btn = Button.new()
	clear_btn.text = "清空材料"
	clear_btn.custom_minimum_size = Vector2(120, 40)
	clear_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UIStyle.apply_button_style(clear_btn)
	clear_btn.disabled = selected.is_empty()
	clear_btn.pressed.connect( func():
		panel.set_meta("suit_convert_selected_ids", [])
		_rebuild_craft_view(panel, game_manager)
	)
	action_row.add_child(clear_btn)
	var list_title = Label.new()
	list_title.text = "可选材料（装备背包中已解封、未强化、未锁定、未穿戴）"
	list_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	list_title.add_theme_font_size_override("font_size", 16)
	list_title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
	section.add_child(list_title)
	var material_scroll = ScrollContainer.new()
	material_scroll.custom_minimum_size = Vector2(0, 260)
	material_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	material_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	TouchScrollUtils.configure_scroll(material_scroll)
	section.add_child(material_scroll)
	var list_vbox = VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 8)
	material_scroll.add_child(list_vbox)
	TouchScrollUtils.bind_content_touch_scroll(material_scroll, list_vbox)
	var selectable = _get_suit_convert_selectable(game_manager)
	if selectable.is_empty():
		var empty_label = Label.new()
		empty_label.text = "没有可转换的套装"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		list_vbox.add_child(empty_label)
	else:
		var selected_ids = panel.get_meta("suit_convert_selected_ids") as Array
		var locked_suit_id: = _suit_convert_selected_suit_id(selected)
		for piece in selectable:
			list_vbox.add_child(_create_suit_convert_item(panel, piece, selected_ids, locked_suit_id, game_manager))

static func _create_suit_convert_item(panel: Control, piece, selected_ids: Array, locked_suit_id: int, game_manager) -> Panel:
	var item_panel = Panel.new()
	item_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_panel.custom_minimum_size = Vector2(0, 70)
	item_panel.add_theme_stylebox_override("panel", UIStyle.create_item_style())
	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 10
	hbox.offset_top = 8
	hbox.offset_right = -10
	hbox.offset_bottom = -8
	hbox.add_theme_constant_override("separation", 10)
	item_panel.add_child(hbox)
	var piece_icon: = _suit_piece_icon(piece)
	if piece_icon:
		hbox.add_child(_make_icon_rect(piece_icon, 48))
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(info_vbox)
	var name_label = Label.new()
	name_label.text = str(piece.name)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	info_vbox.add_child(name_label)
	var stat_label = Label.new()
	stat_label.text = _suit_piece_stat_text(piece)
	stat_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stat_label.add_theme_font_size_override("font_size", 15)
	stat_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
	info_vbox.add_child(stat_label)
	var piece_id: = str(piece.id)
	var selected = selected_ids.has(piece_id)
	var toggle_btn = Button.new()
	toggle_btn.text = "移除" if selected else "加入"
	toggle_btn.custom_minimum_size = Vector2(90, 36)
	toggle_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UIStyle.apply_button_style(toggle_btn)
	var same_suit: = locked_suit_id <= 0 or _suit_convert_piece_suit_id(piece) == locked_suit_id
	if not selected and (selected_ids.size() >= 3 or not same_suit):
		toggle_btn.disabled = true
	TouchScrollUtils.bind_tap(toggle_btn, func():
		if toggle_btn.disabled:
			return
		var ids = panel.get_meta("suit_convert_selected_ids") as Array
		if ids.has(piece_id):
			ids.erase(piece_id)
		else:
			if ids.size() >= 3:
				_show_craft_message(panel, "材料已满3件，请先移除后再添加")
				return
			var current_suit: = _suit_convert_selected_suit_id(_get_selected_suit_convert_pieces(panel, game_manager))
			if current_suit > 0 and _suit_convert_piece_suit_id(piece) != current_suit:
				_show_craft_message(panel, "只能放入同一套装")
				return
			ids.append(piece_id)
		panel.set_meta("suit_convert_selected_ids", ids)
		_rebuild_craft_view(panel, game_manager)
	)
	hbox.add_child(toggle_btn)
	return item_panel

static func _auto_fill_suit_convert(panel: Control, game_manager) -> void :
	var selectable = _get_suit_convert_selectable(game_manager)
	var ids = panel.get_meta("suit_convert_selected_ids") as Array
	var target_suit: = 0
	if not ids.is_empty():
		target_suit = _suit_convert_selected_suit_id(_get_selected_suit_convert_pieces(panel, game_manager))
	else:
		var counts: = {}
		for piece in selectable:
			var sid: = _suit_convert_piece_suit_id(piece)
			if sid <= 0:
				continue
			counts[sid] = int(counts.get(sid, 0)) + 1
		var best_n: = 0
		for sid in counts.keys():
			var n: = int(counts[sid])
			var sid_n: = int(sid)
			if n > best_n or (n == best_n and (target_suit == 0 or sid_n < target_suit)):
				best_n = n
				target_suit = sid_n
	if target_suit <= 0:
		_show_craft_message(panel, "没有可转换的套装")
		return
	var existing: = {}
	for pid in ids:
		existing[str(pid)] = true
	for piece in selectable:
		if ids.size() >= 3:
			break
		if _suit_convert_piece_suit_id(piece) != target_suit:
			continue
		var piece_id: = str(piece.id)
		if existing.has(piece_id):
			continue
		ids.append(piece_id)
		existing[piece_id] = true
	panel.set_meta("suit_convert_selected_ids", ids)
	_rebuild_craft_view(panel, game_manager)

static func _get_suit_convert_selectable(game_manager) -> Array:
	var result: = []
	if not game_manager or not game_manager.equipment_manager:
		return result
	for piece in game_manager.equipment_manager.inventory:
		if piece == null:
			continue
		if not _is_suit_convert_material(piece):
			continue
		result.append(piece)
	result.sort_custom( func(a, b):
		var sa: = _suit_convert_piece_suit_id(a)
		var sb: = _suit_convert_piece_suit_id(b)
		if sa != sb:
			return sa < sb
		return str(a.name) < str(b.name)
	)
	return result

static func _is_suit_convert_material(piece) -> bool:
	if piece == null:
		return false
	if not bool(piece.is_suit) or bool(piece.is_sealed) or bool(piece.is_pet_equipment):
		return false
	if bool(piece.locked) or bool(piece.equipped):
		return false
	if int(piece.suit_enhance_level) != 0:
		return false
	var rolls = piece.suit_enhance_rolls
	if rolls is Array and (rolls as Array).size() > 0:
		return false
	if str(piece.id).strip_edges().is_empty():
		return false
	return _suit_convert_piece_suit_id(piece) > 0

static func _suit_convert_piece_suit_id(piece) -> int:
	if piece == null:
		return 0
	return int(piece.suit_id)

static func _get_selected_suit_convert_pieces(panel: Control, game_manager) -> Array:
	var selected_ids = panel.get_meta("suit_convert_selected_ids") as Array
	var selectable = _get_suit_convert_selectable(game_manager)
	var selectable_map: = {}
	for piece in selectable:
		selectable_map[str(piece.id)] = piece
	var selected: = []
	var cleaned: = []
	for pid in selected_ids:
		var key: = str(pid)
		if selectable_map.has(key):
			selected.append(selectable_map[key])
			cleaned.append(key)
	if cleaned.size() != selected_ids.size():
		panel.set_meta("suit_convert_selected_ids", cleaned)
	return selected

static func _suit_convert_selected_suit_id(selected: Array) -> int:
	if selected.is_empty():
		return 0
	return _suit_convert_piece_suit_id(selected[0])

static func _suit_convert_selection_ready(selected: Array) -> bool:
	if selected.size() != 3:
		return false
	var suit_id: = _suit_convert_selected_suit_id(selected)
	if suit_id <= 0:
		return false
	for piece in selected:
		if _suit_convert_piece_suit_id(piece) != suit_id:
			return false
	return true

static func _suit_convert_group_name(selected: Array) -> String:
	if selected.is_empty():
		return ""
	var suit_id: = _suit_convert_selected_suit_id(selected)
	if suit_id <= 0:
		return ""
	return SuitDatabaseDetailed.get_suit_name(suit_id)

static func _suit_piece_stat_text(piece) -> String:
	if piece == null:
		return ""
	var slot_name: = SuitDatabaseDetailed.get_slot_name(str(piece.suit_slot if str(piece.suit_slot) != "" else piece.slot))
	if int(piece.attack) > 0:
		return "%s  攻击 %d" % [slot_name, int(piece.attack)]
	if int(piece.defense) > 0:
		return "%s  防御 %d" % [slot_name, int(piece.defense)]
	if int(piece.hp) > 0:
		return "%s  生命 %d" % [slot_name, int(piece.hp)]
	if int(piece.agility) > 0:
		return "%s  敏捷 %d" % [slot_name, int(piece.agility)]
	if int(piece.mp) > 0:
		return "%s  内力 %d" % [slot_name, int(piece.mp)]
	return slot_name

static func _make_icon_rect(tex: Texture2D, side: int) -> TextureRect:
	var icon: = TextureRect.new()
	icon.custom_minimum_size = Vector2(side, side)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = tex
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon

static func _suit_piece_slot(piece) -> String:
	if piece == null:
		return ""
	var suit_slot: = str(piece.suit_slot).strip_edges()
	if suit_slot != "":
		return suit_slot
	return str(piece.slot).strip_edges()

static func _suit_piece_icon(piece) -> Texture2D:
	if piece == null:
		return null
	return InventoryIconHelper.suit_equip_icon(int(piece.suit_id), _suit_piece_slot(piece))

static func _suit_icon_from_dict(data: Dictionary) -> Texture2D:
	if data.is_empty():
		return null
	var slot: = str(data.get("suit_slot", data.get("slot", ""))).strip_edges()
	return InventoryIconHelper.suit_equip_icon(int(data.get("suit_id", 0)), slot)

static func _pet_portrait(pet) -> Texture2D:
	if pet == null:
		return null
	return _pet_texture_by_id(str(pet.pet_id))

static func _pet_texture_by_id(pet_id: String) -> Texture2D:
	var pid: = pet_id.strip_edges()
	if pid.is_empty():
		return null
	var am = AssetManager.get_instance()
	if am == null:
		return null
	return am.get_pet_texture(pid)

static func _pet_portrait_from_granted(granted: Dictionary) -> Texture2D:
	if granted.is_empty():
		return null
	var pid: = str(granted.get("pet_id", granted.get("petId", ""))).strip_edges()
	if pid.is_empty():
		var pet_name: = str(granted.get("name", "")).strip_edges()
		if pet_name != "":
			for key in GameData.PET_DATA.keys():
				var row = GameData.PET_DATA[key]
				if row is Dictionary and str(row.get("name", "")).strip_edges() == pet_name:
					pid = str(key)
					break
	return _pet_texture_by_id(pid)

static func _pet_mutation_count(pet) -> int:
	if pet == null or not ("mutation_count" in pet):
		return 0
	return clampi(int(pet.mutation_count), 0, 2)

static func _pet_name_quality_color(pet) -> Color:
	if _pet_mutation_count(pet) > 0:
		return Color(0.072, 0.080, 0.079)
	if pet != null and bool(pet.is_elite):
		return Color(1, 0.84, 0)
	return Color(0.9, 0.9, 0.9)

static func _pet_quality_bracket(pet) -> String:
	var mc: = _pet_mutation_count(pet)
	if mc > 0:
		return "[变异%d]" % mc
	if pet != null and bool(pet.is_elite):
		return "[极]"
	return "[普]"

static func _growth_color(growth: float) -> Color:
	if growth >= 10.0:
		return Color(1.0, 0.6, 0.0)
	if growth >= 7.0:
		return Color(0.072, 0.080, 0.079)
	if growth >= 6.0:
		return Color(0.072, 0.080, 0.079)
	if growth >= 5.0:
		return Color(0.2, 0.8, 0.2)
	return Color(1, 1, 1)

static func _pill_icon(recipe_id: String) -> Texture2D:
	var recipe = GameData.CRAFTING_RECIPES.get(recipe_id, {})
	var pill_name: = ""
	if recipe is Dictionary:
		pill_name = str(recipe.get("result", recipe.get("name", ""))).strip_edges()
	return InventoryIconHelper.category_icon_for_inventory_item({
		"name": pill_name, 
		"item_type": "cultivation_pill", 
	})

static func _suit_stat_text_from_dict(data: Dictionary) -> String:
	var slot_name: = SuitDatabaseDetailed.get_slot_name(str(data.get("suit_slot", data.get("slot", ""))))
	if int(data.get("attack", 0)) > 0:
		return "%s  攻击 %d" % [slot_name, int(data.get("attack", 0))]
	if int(data.get("defense", 0)) > 0:
		return "%s  防御 %d" % [slot_name, int(data.get("defense", 0))]
	if int(data.get("hp", 0)) > 0:
		return "%s  生命 %d" % [slot_name, int(data.get("hp", 0))]
	if int(data.get("agility", 0)) > 0:
		return "%s  敏捷 %d" % [slot_name, int(data.get("agility", 0))]
	if int(data.get("mp", 0)) > 0:
		return "%s  内力 %d" % [slot_name, int(data.get("mp", 0))]
	return slot_name

static func _await_suit_convert(panel: Control, game_manager, operation_id: String, equipment_ids: Array) -> Dictionary:
	var net = game_manager.network if game_manager else null
	if net == null:
		return {"ok": false, "error": "网络未初始化"}
	var state: = {"done": false, "ok": false, "data": {}, "error": ""}
	var on_ok = func(data: Dictionary):
		state["done"] = true
		state["ok"] = true
		state["data"] = data
	var on_fail = func(error: String):
		state["done"] = true
		state["ok"] = false
		state["error"] = error
	net.equipment_suit_convert_success.connect(on_ok, CONNECT_ONE_SHOT)
	net.equipment_suit_convert_failed.connect(on_fail, CONNECT_ONE_SHOT)
	net.request_equipment_suit_convert(equipment_ids, operation_id)
	var waited: = 0
	while not bool(state["done"]) and waited < 60000:
		if not is_instance_valid(panel):
			return {"ok": false, "error": "界面已关闭"}
		await panel.get_tree().create_timer(0.05).timeout
		waited += 50
	if not bool(state["done"]):
		return {"ok": false, "error": "转换超时，请稍后查看装备背包"}
	return {"ok": bool(state["ok"]), "data": state["data"], "error": str(state["error"])}

static func _on_suit_convert_pressed(panel: Control, game_manager, trigger_btn: Button = null) -> void :
	var selected = _get_selected_suit_convert_pieces(panel, game_manager)
	if not _suit_convert_selection_ready(selected):
		_show_craft_message(panel, "需要放入3件同名已解封套装才能转换")
		return
	if not game_manager.network or not game_manager.network.is_logged_in():
		_show_craft_message(panel, "当前网络不可用，转换已阻止。\n套装转换需联网，由服务器确认后才会扣除材料。")
		return
	if trigger_btn:
		trigger_btn.disabled = true
	var equipment_ids: Array = []
	for piece in selected:
		equipment_ids.append(str(piece.id))
	var op_id: = "suit_convert_%s_%s" % [str(Time.get_unix_time_from_system()), str(randi())]
	var er: Dictionary = await _await_suit_convert(panel, game_manager, op_id, equipment_ids)
	if not is_instance_valid(panel):
		return
	if trigger_btn and is_instance_valid(trigger_btn):
		trigger_btn.disabled = false
	if not bool(er.get("ok", false)):
		_show_craft_message(panel, "转换失败：\n%s" % str(er.get("error", "转换失败，请稍后重试")))
		_rebuild_craft_view(panel, game_manager)
		return
	var data: Dictionary = er.get("data", {}) if er.get("data") is Dictionary else {}
	if data.has("saveRevision"):
		var srv_rev: = int(data.get("saveRevision", -1))
		if srv_rev >= 0 and game_manager.has_method("_set_cloud_save_revision"):
			game_manager._set_cloud_save_revision(srv_rev)
	var save_var: Variant = data.get("saveData", null)
	if save_var is Dictionary and (save_var as Dictionary).has("equipmentData"):
		game_manager.apply_cloud_save(save_var, {"authoritative_equipment_inventory": true})
	elif bool(data.get("duplicate", false)):
		panel.set_meta("suit_convert_selected_ids", [])
		_show_craft_message(panel, "转换请求已处理过，请查看装备背包")
		_rebuild_craft_view(panel, game_manager)
		return
	else:
		panel.set_meta("suit_convert_selected_ids", [])
		_show_craft_message(panel, "转换结果未同步，请重新登录后再看装备背包")
		_rebuild_craft_view(panel, game_manager)
		return
	var result: Dictionary = data.get("result", {}) if data.get("result") is Dictionary else {}
	var granted: Dictionary = result.get("equipment", {}) if result.get("equipment") is Dictionary else {}
	panel.set_meta("suit_convert_selected_ids", [])
	if granted.is_empty():
		_show_craft_message(panel, str(data.get("message", "转换完成，请查看装备背包")))
	else:
		_show_craft_message(panel, "%s\n%s" % [str(data.get("message", "转换成功")), _suit_stat_text_from_dict(granted)], _suit_icon_from_dict(granted), 96)
	_rebuild_craft_view(panel, game_manager)

static func _build_pill_tab(panel: Control, scroll_content: VBoxContainer, player, game_manager):
	var pill_section = _create_section_vbox("丹药炼制")
	scroll_content.add_child(pill_section)
	_add_craft_recipe_ui_adapted(panel, pill_section, "juling_pill", "聚灵丹 (+100修为)", player.realm, player.level, player.cultivation, game_manager)
	_add_craft_recipe_ui_adapted(panel, pill_section, "ningshen_pill", "凝神丹 (+200修为)", player.realm, player.level, player.cultivation, game_manager)
	_add_craft_recipe_ui_adapted(panel, pill_section, "wudao_pill", "悟道仙丹 (+500修为)", player.realm, player.level, player.cultivation, game_manager)

static func _build_pet_refine_tab(panel: Control, scroll_content: VBoxContainer, game_manager):
	var section = _create_section_vbox("宠物炼化")
	scroll_content.add_child(section)

	if not game_manager or not game_manager.pet_manager:
		var no_data_label = Label.new()
		no_data_label.text = "宠物系统未初始化"
		no_data_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		section.add_child(no_data_label)
		return

	if not panel.has_meta("pet_refine_selected_ids"):
		panel.set_meta("pet_refine_selected_ids", [])

	var selected_pets = _get_selected_refine_pets(panel, game_manager)

	var desc = Label.new()
	desc.text = "放入8只1级宠物进行炼化，随机产出1只新宠（成长=8只平均值，每次消耗1000万金币）"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	section.add_child(desc)

	var pool_desc = Label.new()
	var _pw = GameData.PET_REFINE_POOL_WEIGHTS
	pool_desc.text = "概率：普通池%d%%（不可进化） | 稀有池%d%%（可进化，不含极稀有链） | 极稀有池%d%%（水晶儿/梦晶儿/阿弟达斯链）" % [_pw.common, _pw.rare, _pw.ultra_rare]
	pool_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pool_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pool_desc.add_theme_font_size_override("font_size", 14)
	pool_desc.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
	section.add_child(pool_desc)

	var growth_preview = Label.new()
	var avg_growth = _calc_refine_avg_growth(selected_pets)
	growth_preview.text = "当前材料：%d/8  平均成长：%.3f" % [selected_pets.size(), avg_growth]
	growth_preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	growth_preview.add_theme_font_size_override("font_size", 18)
	growth_preview.add_theme_color_override("font_color", Color(1, 0.84, 0))
	section.add_child(growth_preview)

	var bagua_grid = GridContainer.new()
	bagua_grid.columns = 3
	bagua_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bagua_grid.add_theme_constant_override("h_separation", 8)
	bagua_grid.add_theme_constant_override("v_separation", 8)
	section.add_child(bagua_grid)

	var selected_index = 0
	for i in range(9):
		if i == 4:
			var refine_btn = Button.new()
			refine_btn.text = "开始炼化"
			refine_btn.custom_minimum_size = Vector2(120, 148)
			refine_btn.add_theme_font_size_override("font_size", 20)
			UIStyle.apply_golden_button_style(refine_btn)
			refine_btn.disabled = selected_pets.size() != 8
			refine_btn.pressed.connect( func():
				_on_pet_refine_pressed(panel, game_manager, refine_btn)
			)
			bagua_grid.add_child(refine_btn)
			continue

		var slot_panel = Panel.new()
		slot_panel.custom_minimum_size = Vector2(120, 148)
		slot_panel.add_theme_stylebox_override("panel", UIStyle.create_item_style())
		bagua_grid.add_child(slot_panel)

		var slot_vbox = VBoxContainer.new()
		slot_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		slot_vbox.offset_left = 6
		slot_vbox.offset_top = 6
		slot_vbox.offset_right = -6
		slot_vbox.offset_bottom = -6
		slot_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		slot_panel.add_child(slot_vbox)

		var slot_label = Label.new()
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_label.add_theme_font_size_override("font_size", 14)
		slot_label.add_theme_color_override("font_color", Color(0.631, 0.611, 0.564))
		slot_vbox.add_child(slot_label)

		var name_label = Label.new()
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.add_theme_font_size_override("font_size", 15)
		slot_vbox.add_child(name_label)

		var growth_label = Label.new()
		growth_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		growth_label.add_theme_font_size_override("font_size", 14)
		growth_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
		slot_vbox.add_child(growth_label)

		if selected_index < selected_pets.size():
			var pet = selected_pets[selected_index]
			var portrait: = _pet_portrait(pet)
			if portrait:
				slot_label.visible = false
				var icon_rect: = _make_icon_rect(portrait, 48)
				slot_vbox.add_child(icon_rect)
				slot_vbox.move_child(icon_rect, 0)
			else:
				slot_label.text = "材料%d" % (selected_index + 1)
			name_label.text = "%s%s" % [pet.pet_name, _pet_quality_bracket(pet)]
			name_label.add_theme_color_override("font_color", _pet_name_quality_color(pet))
			growth_label.text = "成长 %.3f" % pet.total_growth
			growth_label.add_theme_color_override("font_color", _growth_color(pet.total_growth))
			selected_index += 1
		else:
			slot_label.text = "空槽"
			name_label.text = "待放入"
			growth_label.text = ""

	var action_row = HBoxContainer.new()
	action_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	action_row.add_theme_constant_override("separation", 10)
	section.add_child(action_row)

	var auto_fill_btn = Button.new()
	auto_fill_btn.text = "一键放入"
	auto_fill_btn.custom_minimum_size = Vector2(120, 40)
	UIStyle.apply_button_style(auto_fill_btn)
	auto_fill_btn.pressed.connect( func():
		var selectable = _get_refine_selectable_pets(game_manager)
		var ids = panel.get_meta("pet_refine_selected_ids") as Array
		var existing: = {}
		for pid in ids:
			existing[pid] = true
		for pet in selectable:
			if ids.size() >= 8:
				break
			if existing.has(pet.id):
				continue
			ids.append(pet.id)
			existing[pet.id] = true
		panel.set_meta("pet_refine_selected_ids", ids)
		_rebuild_craft_view(panel, game_manager)
	)
	action_row.add_child(auto_fill_btn)

	var clear_btn = Button.new()
	clear_btn.text = "清空材料"
	clear_btn.custom_minimum_size = Vector2(120, 40)
	UIStyle.apply_button_style(clear_btn)
	clear_btn.disabled = selected_pets.is_empty()
	clear_btn.pressed.connect( func():
		panel.set_meta("pet_refine_selected_ids", [])
		_rebuild_craft_view(panel, game_manager)
	)
	action_row.add_child(clear_btn)

	var list_title = Label.new()
	list_title.text = "可选材料（仅显示1级、0代；可进化宠需幼年；未锁定、非出战）"
	list_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list_title.add_theme_font_size_override("font_size", 16)
	list_title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
	section.add_child(list_title)

	var material_scroll = ScrollContainer.new()
	material_scroll.custom_minimum_size = Vector2(0, 260)
	material_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	material_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	TouchScrollUtils.configure_scroll(material_scroll)
	section.add_child(material_scroll)

	var list_vbox = VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 8)
	material_scroll.add_child(list_vbox)
	TouchScrollUtils.bind_content_touch_scroll(material_scroll, list_vbox)

	var selectable_pets = _get_refine_selectable_pets(game_manager)
	if selectable_pets.is_empty():
		var empty_label = Label.new()
		empty_label.text = "没有可用的1级宠物"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		list_vbox.add_child(empty_label)
	else:
		var selected_ids = panel.get_meta("pet_refine_selected_ids") as Array
		for pet in selectable_pets:
			list_vbox.add_child(_create_refine_pet_item(panel, pet, selected_ids, game_manager))

static func _create_refine_pet_item(panel: Control, pet, selected_ids: Array, game_manager) -> Panel:
	var item_panel = Panel.new()
	item_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_panel.custom_minimum_size = Vector2(0, 70)
	item_panel.add_theme_stylebox_override("panel", UIStyle.create_item_style())

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 10
	hbox.offset_top = 8
	hbox.offset_right = -10
	hbox.offset_bottom = -8
	hbox.add_theme_constant_override("separation", 10)
	item_panel.add_child(hbox)
	var portrait: = _pet_portrait(pet)
	if portrait:
		hbox.add_child(_make_icon_rect(portrait, 48))

	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(info_vbox)
	var name_label = Label.new()
	name_label.text = "%s%s" % [pet.pet_name, _pet_quality_bracket(pet)]
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", _pet_name_quality_color(pet))
	info_vbox.add_child(name_label)
	var growth_label = Label.new()
	growth_label.text = "成长:%.3f  五行:%s" % [pet.total_growth, pet.element]
	growth_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	growth_label.add_theme_font_size_override("font_size", 15)
	growth_label.add_theme_color_override("font_color", _growth_color(pet.total_growth))
	info_vbox.add_child(growth_label)

	var selected = selected_ids.has(pet.id)
	var toggle_btn = Button.new()
	toggle_btn.text = "移除" if selected else "加入"
	toggle_btn.custom_minimum_size = Vector2(90, 36)
	UIStyle.apply_button_style(toggle_btn)

	if not selected and selected_ids.size() >= 8:
		toggle_btn.disabled = true

	TouchScrollUtils.bind_tap(toggle_btn, func():
		if toggle_btn.disabled:
			return
		var ids = panel.get_meta("pet_refine_selected_ids") as Array
		if ids.has(pet.id):
			ids.erase(pet.id)
		else:
			if ids.size() >= 8:
				_show_craft_message(panel, "材料已满8只，请先移除后再添加")
				return
			ids.append(pet.id)
		panel.set_meta("pet_refine_selected_ids", ids)
		_rebuild_craft_view(panel, game_manager)
	)
	hbox.add_child(toggle_btn)

	return item_panel

static func _get_refine_selectable_pets(game_manager) -> Array:
	var result: = []
	if not game_manager or not game_manager.pet_manager:
		return result
	var pm = game_manager.pet_manager
	var active_pet = pm.active_pet

	for pet in pm.get_all_pets():
		if pet.level != 1:
			continue
		if int(pet.generation) != 0:
			continue
		if EvolutionData.is_evolution_pet(pet.pet_id):
			var form_text: = str(pet.form).strip_edges()
			if form_text != "" and form_text != "幼年":
				continue
			if form_text == "" and int(pet.evolution_stage) > 0:
				continue
		if pet.locked:
			continue
		if active_pet and active_pet.id == pet.id:
			continue
		result.append(pet)
	return result

static func _get_selected_refine_pets(panel: Control, game_manager) -> Array:
	var selected_ids = panel.get_meta("pet_refine_selected_ids") as Array
	var selectable = _get_refine_selectable_pets(game_manager)
	var selectable_map: = {}
	for pet in selectable:
		selectable_map[pet.id] = pet
	var selected_pets: = []
	var cleaned_ids: = []
	for pid in selected_ids:
		if selectable_map.has(pid):
			selected_pets.append(selectable_map[pid])
			cleaned_ids.append(pid)
	if cleaned_ids.size() != selected_ids.size():
		panel.set_meta("pet_refine_selected_ids", cleaned_ids)
	return selected_pets

static func _calc_refine_avg_growth(selected_pets: Array) -> float:
	if selected_pets.is_empty():
		return 0.0
	var sum: = 0.0
	for pet in selected_pets:
		sum += pet.total_growth
	return snapped(sum / float(selected_pets.size()), 0.001)

static func _await_pet_refine_validate(game_manager, material_ids: Array) -> Dictionary:
	var net = game_manager.network if game_manager else null
	if net == null:
		return {"ok": false, "error": "网络未初始化"}
	var state: = {"done": false, "data": {}}
	var on_done = func(d: Dictionary):
		state["done"] = true
		state["data"] = d
	net.pet_refine_validate_done.connect(on_done, CONNECT_ONE_SHOT)
	net.pet_refine_validate(material_ids)
	var start_ms: = Time.get_ticks_msec()
	while not bool(state.get("done", false)):
		if Time.get_ticks_msec() - start_ms > _PET_REFINE_RPC_WAIT_MS:
			if net.pet_refine_validate_done.is_connected(on_done):
				net.pet_refine_validate_done.disconnect(on_done)
			return {"ok": false, "error": "炼化材料校验超时，请稍后重试"}
		await game_manager.get_tree().process_frame
	var data: Dictionary = state.get("data", {})
	if not bool(data.get("success", false)):
		return {"ok": false, "error": str(data.get("error", "炼化材料校验失败"))}
	return {"ok": true, "data": data}

static func _await_pet_roster_sync(game_manager, op_id: String, pets_roster: Array, active_pet_id: String, save_revision: int) -> Dictionary:
	var net = game_manager.network if game_manager else null
	if net == null:
		return {"ok": false, "error": "网络未初始化"}
	var state: = {"done": false, "ok": false, "data": {}, "error": ""}
	var on_ok = func(d: Dictionary):
		state["done"] = true
		state["ok"] = true
		state["data"] = d
	var on_fail = func(err: String):
		state["done"] = true
		state["ok"] = false
		state["error"] = err
	net.pet_roster_sync_success.connect(on_ok, CONNECT_ONE_SHOT)
	net.pet_roster_sync_failed.connect(on_fail, CONNECT_ONE_SHOT)
	net.pet_roster_sync(op_id, pets_roster, active_pet_id, save_revision)
	var start_ms: = Time.get_ticks_msec()
	while not bool(state.get("done", false)):
		if Time.get_ticks_msec() - start_ms > _PET_REFINE_RPC_WAIT_MS:
			if net.pet_roster_sync_success.is_connected(on_ok):
				net.pet_roster_sync_success.disconnect(on_ok)
			if net.pet_roster_sync_failed.is_connected(on_fail):
				net.pet_roster_sync_failed.disconnect(on_fail)
			return {"ok": false, "error": "主战栏同步超时，请稍后重试"}
		await game_manager.get_tree().process_frame
	if bool(state.get("ok", false)):
		return {"ok": true, "data": state.get("data", {})}
	return {"ok": false, "error": str(state.get("error", "主战栏同步失败"))}

static func _await_pet_refine_rpc(game_manager, op_id: String, material_ids: Array) -> Dictionary:
	var net = game_manager.network if game_manager else null
	if net == null:
		return {"ok": false, "error": "网络未初始化"}
	var state: = {"done": false, "ok": false, "data": {}, "error": ""}
	var on_ok = func(d: Dictionary):
		state["done"] = true
		state["ok"] = true
		state["data"] = d
	var on_fail = func(err: String):
		state["done"] = true
		state["ok"] = false
		state["error"] = err
	net.pet_refine_success.connect(on_ok, CONNECT_ONE_SHOT)
	net.pet_refine_failed.connect(on_fail, CONNECT_ONE_SHOT)
	net.pet_refine(op_id, material_ids)
	var start_ms: = Time.get_ticks_msec()
	while not bool(state.get("done", false)):
		if Time.get_ticks_msec() - start_ms > _PET_REFINE_RPC_WAIT_MS:
			if net.pet_refine_success.is_connected(on_ok):
				net.pet_refine_success.disconnect(on_ok)
			if net.pet_refine_failed.is_connected(on_fail):
				net.pet_refine_failed.disconnect(on_fail)
			return {"ok": false, "error": "炼化请求超时，请稍后查看宠物栏或邮箱"}
		await game_manager.get_tree().process_frame
	if bool(state.get("ok", false)):
		return {"ok": true, "data": state.get("data", {})}
	return {"ok": false, "error": str(state.get("error", "炼化失败，请稍后重试"))}

static func _build_roster_sync_pets(game_manager) -> Array:
	var out: Array = []
	if not game_manager or not game_manager.pet_manager:
		return out
	for pet in game_manager.pet_manager.get_all_pets():
		if pet:
			out.append(pet.to_dict())
	return out

static func _format_refine_validate_error(data: Dictionary) -> String:
	if not bool(data.get("goldOk", true)):
		return "金币不足，需要10,000,000金币。"
	var invalid_var: Variant = data.get("invalidIds", {})
	if invalid_var is Dictionary:
		var invalid_ids: Dictionary = invalid_var
		for key in invalid_ids.keys():
			return str(invalid_ids.get(key, "材料宠物不符合炼化条件"))
	var missing_var: Variant = data.get("missingIds", [])
	if missing_var is Array and (missing_var as Array).size() > 0:
		return "部分材料宠物尚未同步到云端"
	return "材料宠物不符合炼化条件"

static func _on_pet_refine_pressed(panel: Control, game_manager, trigger_btn: Button = null):
	var selected_pets = _get_selected_refine_pets(panel, game_manager)
	if selected_pets.size() != 8:
		_show_craft_message(panel, "需要放入8只1级宠物才能炼化")
		return
	if not game_manager.network or not game_manager.network.is_logged_in():
		_show_craft_message(panel, "当前网络不可用，炼化已阻止。\n为防止断网SL，乾坤炉炼化需联网并完成云端确认。")
		return
	if trigger_btn:
		trigger_btn.disabled = true

	var anim_overlay = _show_refine_animation(panel)
	var anim_label = anim_overlay.get_meta("anim_label") as Label
	var desc_label = anim_overlay.get_meta("desc_label") as Label

	if anim_label and desc_label:
		anim_label.text = "乾坤炉炼化中·"
		desc_label.text = "炉火初燃，八宠归位..."
	await panel.get_tree().create_timer(0.6).timeout

	if anim_label and desc_label and is_instance_valid(anim_overlay):
		anim_label.text = "乾坤炉炼化中··"
		desc_label.text = "阴阳流转，灵力交汇..."
	await panel.get_tree().create_timer(0.6).timeout

	if anim_label and desc_label and is_instance_valid(anim_overlay):
		anim_label.text = "乾坤炉炼化中···"
		desc_label.text = "天机已定，新宠将现..."
	await panel.get_tree().create_timer(0.6).timeout

	if is_instance_valid(anim_overlay):
		anim_overlay.queue_free()

	var material_ids: Array = []
	for pet in selected_pets:
		if pet:
			material_ids.append(str(pet.id))

	var validate_res: Dictionary = await _await_pet_refine_validate(game_manager, material_ids)
	if not bool(validate_res.get("ok", false)):
		if trigger_btn:
			trigger_btn.disabled = false
		_show_craft_message(panel, "炼化失败：\n%s" % str(validate_res.get("error", "材料校验失败")))
		_rebuild_craft_view(panel, game_manager)
		return

	var validate_data: Dictionary = validate_res.get("data", {})
	if not bool(validate_data.get("valid", false)):
		var missing_var: Variant = validate_data.get("missingIds", [])
		var has_missing: = missing_var is Array and (missing_var as Array).size() > 0
		if has_missing:
			var sync_op_id: = "pet_roster_sync_%s_%s" % [str(Time.get_unix_time_from_system()), str(randi())]
			var active_id: = ""
			if game_manager.pet_manager and game_manager.pet_manager.active_pet:
				active_id = str(game_manager.pet_manager.active_pet.id)
			var save_rev: = int(game_manager._cloud_save_revision) if "_cloud_save_revision" in game_manager else 0
			var sync_res: Dictionary = await _await_pet_roster_sync(
				game_manager, 
				sync_op_id, 
				_build_roster_sync_pets(game_manager), 
				active_id, 
				save_rev, 
			)
			if not bool(sync_res.get("ok", false)):
				if trigger_btn:
					trigger_btn.disabled = false
				_show_craft_message(panel, "炼化失败：\n%s" % str(sync_res.get("error", "主战栏同步失败")))
				_rebuild_craft_view(panel, game_manager)
				return
			var sync_data: Dictionary = sync_res.get("data", {})
			if sync_data.has("saveRevision"):
				var srv_rev: = int(sync_data.get("saveRevision", -1))
				if srv_rev >= 0:
					game_manager._set_cloud_save_revision(srv_rev)
			var save_var: Variant = sync_data.get("saveData", null)
			if save_var is Dictionary and not (save_var as Dictionary).is_empty():
				game_manager.apply_cloud_save(save_var, {"pets_authoritative": true})
			validate_res = await _await_pet_refine_validate(game_manager, material_ids)
			if not bool(validate_res.get("ok", false)):
				if trigger_btn:
					trigger_btn.disabled = false
				_show_craft_message(panel, "炼化失败：\n%s" % str(validate_res.get("error", "材料校验失败")))
				_rebuild_craft_view(panel, game_manager)
				return
			validate_data = validate_res.get("data", {})
		if not bool(validate_data.get("valid", false)):
			if trigger_btn:
				trigger_btn.disabled = false
			_show_craft_message(panel, "炼化失败：\n%s" % _format_refine_validate_error(validate_data))
			_rebuild_craft_view(panel, game_manager)
			return

	var snapshot = game_manager.create_secure_op_snapshot()
	var op_id: = "pet_refine_%s_%s" % [str(Time.get_unix_time_from_system()), str(randi())]
	var er: Dictionary = await _await_pet_refine_rpc(game_manager, op_id, material_ids)
	if trigger_btn:
		trigger_btn.disabled = false

	if not bool(er.get("ok", false)):
		game_manager.restore_secure_op_snapshot(snapshot)
		panel.set_meta("pet_refine_selected_ids", [])
		var er_msg: = str(er.get("error", "炼化失败，请稍后重试"))
		_show_craft_message(panel, "炼化失败：\n%s" % er_msg)
		_rebuild_craft_view(panel, game_manager)
		return

	var er_data: Dictionary = er.get("data", {})
	if er_data.has("saveRevision"):
		var srv_rev: = int(er_data.get("saveRevision", -1))
		if srv_rev >= 0:
			game_manager._set_cloud_save_revision(srv_rev)
	if game_manager.player and er_data.has("newGold"):
		game_manager.player.gold = int(er_data.get("newGold", game_manager.player.gold))
		game_manager.gold_changed.emit(game_manager.player.gold)
	var save_var: Variant = er_data.get("saveData", null)
	if save_var is Dictionary and not (save_var as Dictionary).is_empty():
		game_manager.apply_cloud_save(save_var, {"pets_authoritative": true})
	elif bool(er_data.get("duplicate", false)):
		panel.set_meta("pet_refine_selected_ids", [])
		_show_craft_message(panel, "炼化请求已处理过，请查看宠物栏或邮箱")
		_rebuild_craft_view(panel, game_manager)
		return
	else:
		game_manager.restore_secure_op_snapshot(snapshot)
		panel.set_meta("pet_refine_selected_ids", [])
		_show_craft_message(panel, "炼化失败：服务端未返回宠物数据")
		_rebuild_craft_view(panel, game_manager)
		return

	var result_var: Variant = er_data.get("result", {})
	var pool_type: = ""
	var avg_growth: = 0.0
	var pet_display_name: = "未知宠物"
	var granted_pet: Dictionary = {}
	if result_var is Dictionary:
		var result: Dictionary = result_var
		pool_type = str(result.get("poolType", ""))
		avg_growth = float(result.get("avgGrowth", 0.0))
		var granted: Variant = result.get("grantedPets", [])
		if granted is Array and granted.size() > 0 and granted[0] is Dictionary:
			granted_pet = granted[0]
			pet_display_name = str(granted_pet.get("name", pet_display_name))

	var msg: = str(er_data.get("message", "炼化成功"))
	if pool_type == "rare" or pool_type == "ultra_rare":
		var player_name = ""
		if game_manager.player:
			player_name = game_manager.player.player_name
		var pool_name = _get_pool_display_name(pool_type)
		var announce_msg = "☯ 恭喜玩家【%s】在乾坤炉中炼化出[%s]宠物【%s】！" % [
			player_name, 
			pool_name, 
			pet_display_name
		]
		game_manager.broadcast_event("pet_refine", player_name, {
			"pool_type": pool_type, 
			"pet_name": pet_display_name
		}, announce_msg)

	panel.set_meta("pet_refine_selected_ids", [])
	_show_craft_message(panel, "%s\n池子：%s" % [msg, _get_pool_display_name(pool_type)], _pet_portrait_from_granted(granted_pet), 96)
	_rebuild_craft_view(panel, game_manager)

static func _resolve_refine_broadcast_pet_name(result: Dictionary) -> String:
	var pid: = str(result.get("new_pet_id", "")).strip_edges()
	if pid != "":
		var pdata: Dictionary = GameData.PET_DATA.get(pid, {})
		var table_name: = str(pdata.get("name", "")).strip_edges()
		if table_name != "":
			return table_name
	var new_pet = result.get("new_pet")
	if new_pet:
		var live_name: = str(new_pet.pet_name).strip_edges()
		if live_name != "" and live_name != "未知宠物":
			return live_name
	return pid if pid != "" else "未知宠物"

static func _get_pool_display_name(pool_type: String) -> String:
	match pool_type:
		"common":
			return "普通池"
		"rare":
			return "稀有池"
		"ultra_rare":
			return "极稀有池"
		_:
			return "未知"

static func _show_refine_animation(panel: Control) -> Control:
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.6)
	panel.add_child(overlay)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var anim_panel = Panel.new()
	anim_panel.custom_minimum_size = Vector2(460, 260)
	anim_panel.add_theme_stylebox_override("panel", UIStyle.create_panel_style())
	center.add_child(anim_panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	anim_panel.add_child(vbox)

	var title = Label.new()
	title.text = "☯ 乾坤炉"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1, 0.84, 0.2))
	vbox.add_child(title)

	var anim_label = Label.new()
	anim_label.text = "乾坤炉炼化中..."
	anim_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	anim_label.add_theme_font_size_override("font_size", 24)
	anim_label.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
	vbox.add_child(anim_label)

	var desc_label = Label.new()
	desc_label.text = "灵力凝聚中..."
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 17)
	desc_label.add_theme_color_override("font_color", Color(0.734, 0.714, 0.657))
	vbox.add_child(desc_label)

	overlay.set_meta("anim_label", anim_label)
	overlay.set_meta("desc_label", desc_label)
	return overlay

static func _add_craft_recipe_ui_adapted(panel: Control, section_vbox: VBoxContainer, recipe_id: String, display_name: String, realm: String, player_level: int, cultivation: int, game_manager):
	var recipe = GameData.CRAFTING_RECIPES.get(recipe_id, null)
	if recipe == null:
		return

	var is_pill: = recipe_id.ends_with("_pill")
	var recipe_panel = Panel.new()
	recipe_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recipe_panel.custom_minimum_size = Vector2(0, 148 if is_pill else 110)
	recipe_panel.add_theme_stylebox_override("panel", UIStyle.create_item_style())
	section_vbox.add_child(recipe_panel)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 15
	hbox.offset_top = 12
	hbox.offset_right = -15
	hbox.offset_bottom = -12
	recipe_panel.add_child(hbox)
	if is_pill:
		var pill_tex: = _pill_icon(recipe_id)
		if pill_tex:
			hbox.add_child(_make_icon_rect(pill_tex, 48))

	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 6)
	hbox.add_child(info_vbox)

	var name_label = Label.new()
	name_label.text = display_name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	info_vbox.add_child(name_label)

	if is_pill:
		var materials_rich = RichTextLabel.new()
		materials_rich.bbcode_enabled = true
		materials_rich.fit_content = true
		materials_rich.scroll_active = false
		materials_rich.selection_enabled = false
		materials_rich.mouse_filter = Control.MOUSE_FILTER_IGNORE
		materials_rich.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		materials_rich.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		materials_rich.add_theme_font_size_override("normal_font_size", 18)
		materials_rich.add_theme_color_override("default_color", Color(0.7, 0.7, 0.7))
		var parts: PackedStringArray = []
		for mat_name in recipe.materials:
			var mat_count: = int(recipe.materials[mat_name])
			var have: = 0
			if game_manager != null and game_manager.crafting_manager != null:
				have = int(game_manager.crafting_manager.get_bag_material_count(str(mat_name)))
			if have < mat_count:
				parts.append("%s x%d（已有 [color=#ff6b6b]%d[/color]）" % [mat_name, mat_count, have])
			else:
				parts.append("%s x%d（已有 %d）" % [mat_name, mat_count, have])
		materials_rich.text = "  ".join(parts)
		info_vbox.add_child(materials_rich)
	else:
		var materials_label = Label.new()
		var materials_text = ""
		for mat_name in recipe.materials:
			var mat_count = recipe.materials[mat_name]
			materials_text += "%s x%d  " % [mat_name, mat_count]
		materials_label.text = materials_text
		materials_label.add_theme_font_size_override("font_size", 18)
		materials_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		info_vbox.add_child(materials_label)

	var success_rate = recipe.get("success_rate", 0.5)
	var rate_label = Label.new()
	rate_label.text = "成功率: %d%%" % int(success_rate * 100)
	rate_label.add_theme_font_size_override("font_size", 18)
	rate_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
	info_vbox.add_child(rate_label)

	var btn_hbox = HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 8)
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(btn_hbox)

	var craft_btn = Button.new()
	craft_btn.text = "炼制" if recipe_id.ends_with("_pill") else "打造"
	craft_btn.custom_minimum_size = Vector2(100, 50)
	craft_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	craft_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	craft_btn.add_theme_font_size_override("font_size", 18)
	UIStyle.apply_button_style(craft_btn)

	craft_btn.pressed.connect( func():
		if craft_btn.disabled:
			return
		craft_btn.disabled = true
		panel.set_meta("pending_craft_button", craft_btn)
		if recipe_id.ends_with("_pill"):
			await _handle_pill_craft_pressed(panel, recipe_id, realm, game_manager, 1)
		else:
			await _handle_craft_recipe_pressed(panel, recipe_id, realm, player_level, cultivation, game_manager)
		if is_instance_valid(craft_btn):
			craft_btn.disabled = false
	)
	btn_hbox.add_child(craft_btn)

	if recipe_id.ends_with("_pill"):
		var batch_btn = Button.new()
		batch_btn.text = "批量炼制"
		batch_btn.custom_minimum_size = Vector2(110, 50)
		batch_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		batch_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		batch_btn.add_theme_font_size_override("font_size", 16)
		UIStyle.apply_button_style(batch_btn)
		batch_btn.pressed.connect( func():
			if batch_btn.disabled:
				return
			_show_batch_pill_craft_dialog(panel, recipe_id, display_name, realm, game_manager, batch_btn)
		)
		btn_hbox.add_child(batch_btn)

static func _handle_craft_recipe_pressed(panel: Control, recipe_id: String, realm: String, player_level: int, cultivation: int, game_manager) -> void :
	if recipe_id.ends_with("_pill"):
		await _handle_pill_craft_pressed(panel, recipe_id, realm, game_manager, 1)
		return
	if game_manager == null or game_manager.crafting_manager == null:
		_show_craft_message(panel, "打造失败：\n乾坤炉未初始化")
		return
	if not game_manager.network or not game_manager.network.is_logged_in():
		_show_craft_message(panel, "当前网络不可用，炼制需联网并完成云端确认，请登录后重试。")
		return
	var snapshot = game_manager.create_secure_op_snapshot()
	var result = game_manager.crafting_manager.craft(recipe_id, realm, player_level, cultivation)
	if not result.success:
		_show_craft_message(panel, "打造失败：\n" + str(result.message))
		return
	var sync_ok: = true
	if game_manager.has_method("force_cloud_upload_and_wait"):
		sync_ok = await game_manager.force_cloud_upload_and_wait("crafting_recipe:%s" % recipe_id, true, 60.0)
		if not sync_ok:
			await panel.get_tree().create_timer(2.5).timeout
			sync_ok = await game_manager.force_cloud_upload_and_wait("crafting_recipe_retry:%s" % recipe_id, true, 60.0)
	if not sync_ok:
		game_manager.restore_secure_op_snapshot(snapshot)
		_show_craft_message(panel, "云端确认失败，本次炼制结果已回滚显示。\n请检查网络后重试，或返回主城重新同步存档。")
		_rebuild_craft_view(panel, game_manager)
		return
	var item_name = ""
	if result.has("item") and result.item != null:
		if result.item is EquipmentManager.Equipment:
			var rarity_info = GameData.EQUIPMENT_RARITY.get(result.item.rarity, {})
			var rarity_name = rarity_info.get("name", "")
			item_name = "【%s】%s" % [rarity_name, result.item.name]
		else:
			item_name = result.item.name if "name" in result.item else str(result.item)
	else:
		item_name = str(result.get("message", "未知物品")).replace("打造成功！获得", "").strip_edges()
	_show_craft_message(panel, "打造成功！\n获得 " + item_name)
	_rebuild_craft_view(panel, game_manager)

static func _pill_blocked_message(game_manager, recipe_id: String, realm: String) -> String:
	var reason: = "材料不足"
	if game_manager != null and game_manager.crafting_manager != null:
		var can_result: Dictionary = game_manager.crafting_manager.can_craft(recipe_id, realm)
		var msg: = str(can_result.get("message", "")).strip_edges()
		if not msg.is_empty() and msg != "可以打造":
			reason = msg
	return "炼制失败：\n" + reason

static func _handle_pill_craft_pressed(panel: Control, recipe_id: String, realm: String, game_manager, batch_count: int) -> void :
	if game_manager == null or game_manager.crafting_manager == null:
		_show_craft_message(panel, "炼制失败：\n乾坤炉未初始化")
		return
	if not game_manager.network or not game_manager.network.is_logged_in():
		_show_craft_message(panel, "当前网络不可用，炼制需联网并由服务器确认，请登录后重试。")
		return
	var max_count: int = game_manager.crafting_manager.get_max_batch_craft_count(recipe_id, realm)
	if max_count <= 0:
		_show_craft_message(panel, _pill_blocked_message(game_manager, recipe_id, realm))
		return
	var count: = clampi(batch_count, 1, max_count)
	var op_id: = "pill_craft_%s_%d_%d_%d" % [recipe_id, count, Time.get_unix_time_from_system(), Time.get_ticks_msec()]
	var response: = await _await_pill_craft_request(panel, game_manager.network, recipe_id, count, op_id)
	if not response.get("success", false):
		_show_craft_message(panel, "炼制失败：\n" + str(response.get("message", "未知错误")))
		return
	var data: Dictionary = response.get("data", {})
	if game_manager.has_method("apply_cloud_save") and data.get("saveData") is Dictionary:
		var craft_result: Dictionary = {}
		if data.get("result") is Dictionary:
			craft_result = data.get("result", {})
		var reward_result: Dictionary = {
			"grantedItems": [{"name": str(craft_result.get("resultItemName", ""))}]
		}
		var apply_opts: Dictionary = game_manager.build_authority_reward_apply_opts(
			reward_result, 
			{"reward_inventory_slice": true, "currency_slice": true, "debug_tag": "pill_craft"}
		)
		game_manager.apply_cloud_save(data.get("saveData"), apply_opts)
	_rebuild_craft_view(panel, game_manager)
	_show_craft_message(panel, str(data.get("message", "炼制完成")), _pill_icon(recipe_id), 96)

static func _await_pill_craft_request(panel: Control, network, recipe_key: String, batch_count: int, operation_id: String) -> Dictionary:
	var state: = {"done": false, "ok": false, "data": {}, "err": ""}
	var on_ok = func(data: Dictionary):
		state.done = true
		state.ok = true
		state.data = data
	var on_fail = func(err: String):
		state.done = true
		state.ok = false
		state.err = err
	network.pill_craft_success.connect(on_ok, CONNECT_ONE_SHOT)
	network.pill_craft_failed.connect(on_fail, CONNECT_ONE_SHOT)
	network.request_pill_craft(recipe_key, batch_count, operation_id)
	while not state.done and is_instance_valid(panel):
		await panel.get_tree().process_frame
	if state.ok:
		return {"success": true, "data": state.data}
	return {"success": false, "message": state.err if not state.err.is_empty() else "炼制失败"}

static func _show_batch_pill_craft_dialog(panel: Control, recipe_id: String, display_name: String, realm: String, game_manager, batch_btn: Button) -> void :
	if game_manager == null or game_manager.crafting_manager == null:
		_show_craft_message(panel, "炼制失败：\n乾坤炉未初始化")
		return
	if not game_manager.network or not game_manager.network.is_logged_in():
		_show_craft_message(panel, "当前网络不可用，炼制需联网并由服务器确认，请登录后重试。")
		return
	var max_count: int = game_manager.crafting_manager.get_max_batch_craft_count(recipe_id, realm)
	if max_count <= 0:
		_show_craft_message(panel, _pill_blocked_message(game_manager, recipe_id, realm))
		return

	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.5)
	panel.add_child(overlay)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var popup = PanelContainer.new()
	popup.custom_minimum_size = Vector2(440, 0)
	popup.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	center.add_child(popup)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	popup.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var title_label = Label.new()
	title_label.text = "批量炼制 %s" % display_name
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color(1, 0.9, 0.45))
	vbox.add_child(title_label)

	var hint_label = Label.new()
	hint_label.text = "请输入炼制次数（1-%d），失败仍消耗材料。" % max_count
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.add_theme_font_size_override("font_size", 16)
	hint_label.add_theme_color_override("font_color", Color(0.791, 0.769, 0.708))
	vbox.add_child(hint_label)

	var count_edit = LineEdit.new()
	count_edit.text = str(max_count)
	count_edit.placeholder_text = "次数"
	count_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_edit.add_theme_font_size_override("font_size", 18)
	count_edit.custom_minimum_size = Vector2(120, 44)
	count_edit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(count_edit)

	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_row)

	var close_popup = func():
		if is_instance_valid(overlay):
			overlay.queue_free()

	var cancel_btn = Button.new()
	cancel_btn.text = "取消"
	cancel_btn.custom_minimum_size = Vector2(120, 44)
	UIStyle.apply_button_style(cancel_btn)
	cancel_btn.pressed.connect(close_popup)
	btn_row.add_child(cancel_btn)

	var confirm_btn = Button.new()
	confirm_btn.text = "确认炼制"
	confirm_btn.custom_minimum_size = Vector2(140, 44)
	UIStyle.apply_button_style(confirm_btn)
	confirm_btn.pressed.connect( func():
		if confirm_btn.disabled:
			return
		var parsed: = int(count_edit.text)
		parsed = clampi(parsed, 1, max_count)
		confirm_btn.disabled = true
		if is_instance_valid(batch_btn):
			batch_btn.disabled = true
		close_popup.call()
		await _handle_pill_craft_pressed(panel, recipe_id, realm, game_manager, parsed)
		if is_instance_valid(batch_btn):
			batch_btn.disabled = false
	)
	btn_row.add_child(confirm_btn)

static func _rebuild_craft_view(panel: Control, game_manager):
	var scroll_content = panel.get_meta("scroll_content") as VBoxContainer
	if not scroll_content:
		return
	for child in scroll_content.get_children():
		child.queue_free()
	_build_craft_view_adapted(panel, scroll_content, game_manager)

static func _show_craft_message(panel: Control, message: String, icon: Texture2D = null, icon_side: int = 72):

	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.5)
	panel.add_child(overlay)


	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)


	var popup = Panel.new()
	var popup_h: = 340
	if icon:
		popup_h = 420 + maxi(0, icon_side - 72)
	popup.custom_minimum_size = Vector2(400, popup_h)
	popup.add_theme_stylebox_override("panel", UIStyle.create_panel_style())
	center.add_child(popup)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 15)
	popup.add_child(vbox)


	var title_label = Label.new()
	title_label.text = "打造结果"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	vbox.add_child(title_label)
	if icon:
		var icon_box = CenterContainer.new()
		icon_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon_box.add_child(_make_icon_rect(icon, icon_side))
		vbox.add_child(icon_box)


	var label = Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(label)


	var btn_hbox = HBoxContainer.new()
	btn_hbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(btn_hbox)

	var ok_btn = Button.new()
	ok_btn.text = "确定"
	ok_btn.custom_minimum_size = Vector2(120, 45)
	ok_btn.add_theme_font_size_override("font_size", 18)
	UIStyle.apply_button_style(ok_btn)
	ok_btn.pressed.connect( func(): overlay.queue_free())
	btn_hbox.add_child(ok_btn)

static func _create_section_vbox(section_title: String) -> VBoxContainer:
	var section_vbox = VBoxContainer.new()
	section_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	section_vbox.add_theme_constant_override("separation", 8)


	var title_panel = Panel.new()
	title_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_panel.custom_minimum_size = Vector2(0, 35)
	title_panel.add_theme_stylebox_override("panel", UIStyle.create_item_style())
	section_vbox.add_child(title_panel)

	var title = Label.new()
	title.text = section_title
	title.set_anchors_preset(Control.PRESET_FULL_RECT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
	title_panel.add_child(title)

	return section_vbox

static func _setup_mouse_filter(container: Control):
	for child in container.get_children():
		if child is Control:
			if child is ScrollContainer:

				child.mouse_filter = Control.MOUSE_FILTER_PASS
			elif child is Button:
				child.mouse_filter = Control.MOUSE_FILTER_STOP
			else:
				child.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if child is Container:
				_setup_mouse_filter(child)
