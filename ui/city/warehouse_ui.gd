extends RefCounted

const GameData = preload("res://scripts/game_data.gd")
const UIStyle = preload("res://scripts/ui_style.gd")
const AssetManager = preload("res://scripts/asset_manager.gd")
const SuitDatabaseDetailed = preload("res://scripts/data/suit_database_detailed.gd")
const SuitEquipmentEnhance = preload("res://scripts/suit/suit_equipment_enhance.gd")
const PetEquipmentEnhance = preload("res://scripts/pet_equipment/pet_equipment_enhance.gd")
const FabaoBagPanel = preload("res://scripts/ui/fabao/fabao_bag_panel.gd")
const FabaoIcons = preload("res://scripts/fabao/fabao_icons.gd")

static func create_fullscreen(game_manager, embedded: bool = false) -> Control:
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	if embedded:
		# 嵌进背包分页时不要再套一层带边框的卡片，也不要再写一遍标题。
		# 但要留一层很淡的深色底衬：仓库空的时候整页只有两行字，
		# 不铺底会直接透出主城的楼阁，看着像界面没画完。
		var flat := StyleBoxFlat.new()
		flat.bg_color = Color(0.039, 0.048, 0.051, 0.55)
		flat.set_corner_radius_all(0)
		flat.content_margin_left = 12.0
		flat.content_margin_right = 12.0
		flat.content_margin_top = 8.0
		flat.content_margin_bottom = 8.0
		panel.add_theme_stylebox_override("panel", flat)
	else:
		panel.add_theme_stylebox_override("panel", UIStyle.create_panel_style())

	var vbox = UIStyle.create_base_vbox()
	panel.add_child(vbox)

	if not embedded:
		var title = UIStyle.create_title_label("📦 物品仓库")
		vbox.add_child(title)

	var stats_label = Label.new()
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 20)
	stats_label.add_theme_color_override("font_color", Color(0.734, 0.714, 0.657))
	vbox.add_child(stats_label)

	var category_container = HBoxContainer.new()
	category_container.add_theme_constant_override("separation", 12)
	category_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(category_container)

	var current_category = {"value": "all"}
	var category_btns = []

	var categories = [
		{"id": "all", "name": "全部"}, 
		{"id": "equipment", "name": "装备"}, 
		{"id": "pet_equipment", "name": "宠物装备"}, 
		{"id": "material", "name": "材料"}, 
		{"id": "item", "name": "道具"}
	]

	for cat in categories:
		var cat_btn = Button.new()
		cat_btn.text = cat.name
		# 二级页筛选是这一屏最好按的东西，别再做成 80×35 的小标签：
		# 高度给到 62、字号 24，横向均分整行，手指点哪儿都落在按钮上。
		cat_btn.custom_minimum_size = Vector2(0, 62)
		cat_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cat_btn.add_theme_font_size_override("font_size", 24)
		UIStyle.apply_tab_style(cat_btn, cat.id == current_category.value)
		cat_btn.pressed.connect( func():
			current_category.value = cat.id
			for btn in category_btns:
				UIStyle.apply_tab_style(btn, btn.text == cat.name)
			_refresh_items_fullscreen(vbox, game_manager, current_category.value, 
				stats_label, panel)
		)
		category_container.add_child(cat_btn)
		category_btns.append(cat_btn)

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

	var items_container = VBoxContainer.new()
	items_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	items_container.offset_left = 10
	items_container.offset_top = 10
	items_container.offset_right = -10
	items_container.offset_bottom = -10
	items_container.add_theme_constant_override("separation", 6)
	items_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	items_container.name = "ItemsContainer"
	scroll.add_child(items_container)


	var cat_holder: Dictionary = current_category
	panel.tree_entered.connect( func():
		_warehouse_refresh_after_layout(panel, vbox, game_manager, cat_holder, stats_label)
	, CONNECT_ONE_SHOT)
	if not bool(panel.get_meta("_wh_resized_bound", false)):
		panel.set_meta("_wh_resized_bound", true)
		panel.resized.connect( func():
			_on_warehouse_panel_resized(panel, vbox, game_manager, cat_holder, stats_label)
		)
	if game_manager and game_manager.fabao_manager:
		game_manager.fabao_manager.fabao_changed.connect( func():
			if is_instance_valid(panel) and is_instance_valid(vbox) and is_instance_valid(stats_label):
				_refresh_items_fullscreen(vbox, game_manager, current_category.value, stats_label, panel)
		)

	return panel

static func _on_warehouse_panel_resized(panel: Control, vbox: VBoxContainer, game_manager, current_category: Dictionary, stats_label: Label) -> void :
	if not is_instance_valid(panel) or not is_instance_valid(vbox) or not is_instance_valid(stats_label):
		return
	var w: = _warehouse_panel_usable_width(panel)
	var last_w: = float(panel.get_meta("_wh_last_w", 0.0))
	if w < 80.0:
		return
	if last_w > 80.0 and absf(w - last_w) < 8.0:
		return
	var cat: = str(current_category.get("value", "all"))
	_refresh_items_fullscreen(vbox, game_manager, cat, stats_label, panel)

static func _warehouse_refresh_after_layout(panel: Control, vbox: VBoxContainer, game_manager, current_category: Dictionary, stats_label: Label) -> void :
	if not is_instance_valid(panel) or panel.get_tree() == null:
		return
	var tries: = 0
	while tries < 12:
		await panel.get_tree().process_frame
		if not is_instance_valid(panel):
			return
		if _warehouse_panel_usable_width(panel) >= 80.0:
			break
		tries += 1
	if not is_instance_valid(panel) or not is_instance_valid(vbox) or not is_instance_valid(stats_label):
		return
	var cat: = str(current_category.get("value", "all"))
	_refresh_items_fullscreen(vbox, game_manager, cat, stats_label, panel)

static func _warehouse_panel_usable_width(panel: Control) -> float:
	if panel == null:
		return 0.0
	if panel.size.x > 80.0:
		return panel.size.x
	var parent_n: = panel.get_parent()
	if parent_n is Control and (parent_n as Control).size.x > 80.0:
		return (parent_n as Control).size.x
	return 0.0

static func _warehouse_scroll_width(scroll: Control, panel: Control) -> float:

	var allocated: = _warehouse_panel_usable_width(panel)
	if allocated < 80.0 and scroll != null:
		var p: = scroll.get_parent()
		if p is Control and (p as Control).size.x > 80.0:
			allocated = (p as Control).size.x
	if allocated >= 80.0:
		return maxf(allocated - 32.0, 200.0)

	return 480.0

static func _refresh_items_fullscreen(vbox: VBoxContainer, game_manager, 
		category: String, stats_label: Label, panel: Control):

	var content_container = null
	for child in vbox.get_children():
		if child is VBoxContainer:
			content_container = child
			break

	if content_container == null:
		return

	var scroll = content_container.get_node_or_null("ScrollContainer")
	if scroll == null:
		return

	var items_container = scroll.get_node_or_null("ItemsContainer")
	if items_container == null:
		return

	for child in items_container.get_children():
		child.queue_free()

	TouchScrollUtils.configure_scroll(scroll)
	items_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var inventory_manager = game_manager.inventory_manager
	if inventory_manager == null:
		_add_warehouse_empty_label(items_container, "背包系统未初始化")
		return

	var scroll_w: = _warehouse_scroll_width(scroll, panel)
	if panel != null:
		panel.set_meta("_wh_last_w", _warehouse_panel_usable_width(panel))
	var side: = InventoryGridCell.calc_cell_side(scroll_w, 8)


	if category == "equipment":

		var equip_warehouse = inventory_manager.get_equipment_warehouse()
		var sealed_in_wh: Array = []
		for w in inventory_manager.warehouse_items:
			if w != null and w.item_type == "sealed_suit":
				sealed_in_wh.append(w)

		stats_label.text = "人物装备 %d / %d ｜ 封印套装 %d 件（道具仓 %d / %d）" % [
			equip_warehouse.size(), InventoryManager.MAX_EQUIPMENT_WAREHOUSE_SIZE, 
			sealed_in_wh.size(), 
			inventory_manager.warehouse_items.size(), InventoryManager.MAX_WAREHOUSE_SIZE
		]

		if equip_warehouse.is_empty() and sealed_in_wh.is_empty() and _fabao_warehouse_list(game_manager).is_empty():
			_add_warehouse_empty_label(items_container, "装备分页暂无物品\n人物装备、封印套装与法宝皆可在此查看")
			return

		var grid: = _ensure_warehouse_grid(items_container)
		for equip in InventoryBagSort.sort_character_equipments(equip_warehouse):
			grid.add_child(_make_warehouse_equipment_cell(side, equip, game_manager, stats_label, category, panel, vbox))
		for item in InventoryBagSort.sort_and_filter_items(sealed_in_wh, "all"):
			grid.add_child(_make_warehouse_item_cell(side, item, game_manager, stats_label, category, panel, vbox))
		for fb in _fabao_warehouse_list(game_manager):
			if fb is Dictionary:
				grid.add_child(_make_warehouse_fabao_cell(side, fb))
	elif category == "pet_equipment":

		var pet_equip_warehouse = inventory_manager.get_pet_equipment_warehouse()

		stats_label.text = "宠物装备仓库: %d / %d" % [
			pet_equip_warehouse.size(), InventoryManager.MAX_PET_EQUIPMENT_WAREHOUSE
		]

		if pet_equip_warehouse.is_empty():
			_add_warehouse_empty_label(items_container, "宠物装备仓库暂无物品\n可从背包存入宠物装备")
			return

		var grid: = _ensure_warehouse_grid(items_container)
		for equip in InventoryBagSort.sort_pet_equipments(pet_equip_warehouse):
			grid.add_child(_make_warehouse_pet_equipment_cell(side, equip, game_manager, stats_label, category, panel, vbox))
	elif category == "material":

		var items: Array = []
		for item in inventory_manager.warehouse_items:
			if item == null:
				continue
			if inventory_manager.resolve_bag_category(item.name, item.item_type, item.custom_data) == "material":
				items.append(item)
		items = InventoryBagSort.sort_and_filter_materials(items, "all")

		var total_count = 0
		for item in items:
			total_count += int(item.count)

		stats_label.text = "材料仓库: %d 个物品" % total_count

		if items.is_empty():
			_add_warehouse_empty_label(items_container, "材料仓库暂无物品\n可从背包存入材料")
			return

		var grid: = _ensure_warehouse_grid(items_container)
		for item in items:
			grid.add_child(_make_warehouse_item_cell(side, item, game_manager, stats_label, category, panel, vbox))
	elif category == "item":

		var items: Array = []
		for item in inventory_manager.warehouse_items:
			if item == null:
				continue
			if inventory_manager.resolve_bag_category(item.name, item.item_type, item.custom_data) == "item":
				items.append(item)
		items = InventoryBagSort.sort_and_filter_items(items, "all")

		var total_count = 0
		for item in items:
			total_count += item.count

		stats_label.text = "道具仓库: %d 个物品" % total_count

		if items.is_empty():
			_add_warehouse_empty_label(items_container, "道具仓库暂无物品\n可从背包存入道具")
			return

		var grid: = _ensure_warehouse_grid(items_container)
		for item in items:
			grid.add_child(_make_warehouse_item_cell(side, item, game_manager, stats_label, category, panel, vbox))
	else:
		var items = InventoryBagSort.sort_warehouse_bag_items(inventory_manager.warehouse_items.duplicate())
		var equip_warehouse = InventoryBagSort.sort_character_equipments(inventory_manager.get_equipment_warehouse())
		var pet_equip_warehouse = InventoryBagSort.sort_pet_equipments(inventory_manager.get_pet_equipment_warehouse())

		stats_label.text = "仓库: %d 道具 + %d 装备 + %d 宠物装备" % [
			inventory_manager.warehouse_items.size(), equip_warehouse.size(), pet_equip_warehouse.size()
		]

		if items.is_empty() and equip_warehouse.is_empty() and pet_equip_warehouse.is_empty() and _fabao_warehouse_list(game_manager).is_empty():
			_add_warehouse_empty_label(items_container, "仓库暂无物品\n可从背包存入物品")
			return

		var grid: = _ensure_warehouse_grid(items_container)
		for equip in equip_warehouse:
			grid.add_child(_make_warehouse_equipment_cell(side, equip, game_manager, stats_label, category, panel, vbox))
		for fb in _fabao_warehouse_list(game_manager):
			if fb is Dictionary:
				grid.add_child(_make_warehouse_fabao_cell(side, fb))
		for equip in pet_equip_warehouse:
			grid.add_child(_make_warehouse_pet_equipment_cell(side, equip, game_manager, stats_label, category, panel, vbox))
		for item in items:
			grid.add_child(_make_warehouse_item_cell(side, item, game_manager, stats_label, category, panel, vbox))

static func _fabao_warehouse_list(game_manager) -> Array:
	if game_manager == null or game_manager.fabao_manager == null:
		return []
	var out: Array = []
	for inst in game_manager.fabao_manager.fabao_warehouse:
		if inst is Dictionary:
			out.append(inst)
	return out

static func _make_warehouse_fabao_cell(side: int, inst: Dictionary) -> Control:
	var tex: = FabaoIcons.tex_for_tier(str(inst.get("tier", "normal")), false)
	var cap: = inst.duplicate(true)
	return InventoryGridCell.make_filled(
		side, tex, str(inst.get("name", "法宝")), 0, Color(0.85, 0.65, 0.25), 
		func(): FabaoBagPanel.show_detail(cap, false, "warehouse"), 
		Color.WHITE, false
	)

static func _ensure_warehouse_grid(items_container: Control) -> GridContainer:

	var grid: = InventoryGridCell.make_grid(8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_container.add_child(grid)
	return grid

static func _add_warehouse_empty_label(items_container: Control, text: String) -> void :
	var empty_label = Label.new()
	empty_label.text = text
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.add_theme_color_override("font_color", Color(0.631, 0.611, 0.564))
	empty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	items_container.add_child(empty_label)

static func _warehouse_item_display_name(item) -> String:
	var item_data = GameData.ALL_ITEMS.get(item.name, {})
	var item_name = item_data.get("name", item.name)
	if item.item_type == "sealed_suit":
		var cd: Dictionary = item.custom_data if item.custom_data is Dictionary else {}
		var nm: = str(cd.get("name", "")).strip_edges()
		if not nm.is_empty():
			item_name = nm
		else:
			var suit_level: = int(cd.get("suit_level", 0))
			var slot: = str(cd.get("slot", ""))
			if suit_level > 0 and not slot.is_empty():
				item_name = SuitDatabaseDetailed.get_sealed_suit_display_name(suit_level, slot)
			else:
				item_name = "封印套装"
	return str(item_name)

static func _make_warehouse_item_cell(side: int, item, game_manager, stats_label: Label, category: String, panel: Control, vbox: VBoxContainer) -> Control:
	var display_name: = _warehouse_item_display_name(item)
	var rarity: = "common"
	if "rarity" in item:
		rarity = str(item.rarity)
	else:
		var item_data = GameData.ALL_ITEMS.get(item.name, {})
		if item_data is Dictionary:
			rarity = str(item_data.get("rarity", "common"))
	var tex: = InventoryIconHelper.category_icon_for_inventory_item(item)
	if item.item_type == "sealed_suit":
		var cd: Dictionary = item.custom_data if item.custom_data is Dictionary else {}
		var suit_lv: = int(cd.get("suit_level", cd.get("suit_id", 0)))
		var slot: = str(cd.get("slot", "weapon"))
		tex = InventoryIconHelper.suit_equip_icon(suit_lv, slot)
		if tex == null:
			tex = InventoryIconHelper.normal_equip_icon(slot)
	var border: = InventoryIconHelper.rarity_border_color(rarity)
	var mod: = InventoryIconHelper.sealed_modulate() if InventoryIconHelper.is_equipment_sealed(item) else Color.WHITE
	var badge: = InventoryIconHelper.badge_for_inventory_item(item)
	var captured = item
	return InventoryGridCell.make_filled(
		side, tex, display_name, int(item.count), border, 
		func(): _open_warehouse_item_detail(game_manager, captured, vbox, stats_label, category, panel), 
		mod, true, "", false, badge
	)

static func _make_warehouse_equipment_cell(side: int, equip, game_manager, stats_label: Label, category: String, panel: Control, vbox: VBoxContainer) -> Control:
	var rarity: = "common"
	var display_name: = "装备"
	var equip_id: = ""
	if equip is Dictionary:
		rarity = str(equip.get("rarity", "common"))
		display_name = str(equip.get("name", "装备"))
		equip_id = str(equip.get("id", ""))
	else:
		if "rarity" in equip:
			rarity = str(equip.rarity)
		if "name" in equip:
			display_name = str(equip.name)
		if "id" in equip:
			equip_id = str(equip.id)
	var tex: = InventoryIconHelper.resolve_equipment_icon(equip)
	var border: = InventoryIconHelper.rarity_border_color(rarity)
	var mod: = InventoryIconHelper.sealed_modulate() if InventoryIconHelper.is_equipment_sealed(equip) else Color.WHITE
	return InventoryGridCell.make_filled(
		side, tex, display_name, 0, border, 
		func(): _open_warehouse_equipment_detail(game_manager, equip, equip_id, vbox, stats_label, category, panel), 
		mod, false
	)

static func _make_warehouse_pet_equipment_cell(side: int, equip, game_manager, stats_label: Label, category: String, panel: Control, vbox: VBoxContainer) -> Control:
	var rarity: = str(_get_pet_equip_value(equip, "rarity"))
	var name: = str(_get_pet_equip_value(equip, "name"))
	var equip_id: = str(_get_pet_equip_value(equip, "id"))
	var tex: = InventoryIconHelper.resolve_equipment_icon(equip)
	var border: = InventoryIconHelper.rarity_border_color(rarity)
	return InventoryGridCell.make_filled(
		side, tex, name, 0, border, 
		func(): _open_warehouse_pet_equipment_detail(game_manager, equip, equip_id, vbox, stats_label, category, panel), 
		Color.WHITE, false
	)

static func _open_warehouse_item_detail(game_manager, item, vbox: VBoxContainer, stats_label: Label, category: String, panel: Control) -> void :
	var main_ui = _find_main_ui(game_manager)
	var item_id: = str(item.id) if item != null and "id" in item else ""
	var on_retrieve: = func():
		_withdraw_warehouse_entry(game_manager, item_id, "item", vbox, stats_label, category, panel)
	if main_ui and main_ui.has_method("_show_warehouse_item_retrieve_popup"):
		main_ui.call("_show_warehouse_item_retrieve_popup", item, on_retrieve)
	else:
		_withdraw_warehouse_entry(game_manager, item_id, "item", vbox, stats_label, category, panel)

static func _open_warehouse_equipment_detail(game_manager, equip, equip_id: String, vbox: VBoxContainer, stats_label: Label, category: String, panel: Control) -> void :
	var main_ui = _find_main_ui(game_manager)
	var on_retrieve: = func():
		_withdraw_warehouse_entry(game_manager, equip_id, "equipment", vbox, stats_label, category, panel)
	if main_ui and main_ui.has_method("_show_warehouse_equipment_retrieve_popup"):
		main_ui.call("_show_warehouse_equipment_retrieve_popup", equip, on_retrieve)
	else:
		_withdraw_warehouse_entry(game_manager, equip_id, "equipment", vbox, stats_label, category, panel)

static func _open_warehouse_pet_equipment_detail(game_manager, equip, equip_id: String, vbox: VBoxContainer, stats_label: Label, category: String, panel: Control) -> void :
	var main_ui = _find_main_ui(game_manager)
	var on_done: = func():
		_refresh_items_fullscreen(vbox, game_manager, category, stats_label, panel)
	if main_ui and main_ui.has_method("_show_pet_equipment_action_popup"):

		main_ui.call("_show_pet_equipment_action_popup", equip, "warehouse", false, on_done)
	else:
		_withdraw_pet_equipment_entry(game_manager, equip_id, vbox, stats_label, category, panel)

static func _withdraw_warehouse_entry(game_manager, item_id: String, kind: String, vbox: VBoxContainer, stats_label: Label, category: String, panel: Control) -> void :
	if game_manager == null or game_manager.network == null or not game_manager.network.is_logged_in():
		return
	var op_id: = "warehouse_take_%s_%s_%d_%d" % [kind, item_id, Time.get_unix_time_from_system(), Time.get_ticks_msec()]
	var state: = {"done": false, "ok": false, "message": ""}
	var on_success = func(data: Dictionary):
		state.done = true
		state.ok = true
		state.message = str(data.get("message", "已从仓库取出"))
		if game_manager and data.has("saveData") and data.get("saveData") is Dictionary:
			game_manager.apply_cloud_save(data.get("saveData"), {"authoritative_equipment_inventory": true})
	var on_failed = func(error: String):
		state.done = true
		state.ok = false
		state.message = error
	game_manager.network.equipment_retrieve_warehouse_success.connect(on_success, CONNECT_ONE_SHOT)
	game_manager.network.equipment_retrieve_warehouse_failed.connect(on_failed, CONNECT_ONE_SHOT)
	game_manager.network.request_equipment_retrieve_warehouse(item_id, kind, op_id)
	var deadline: = Time.get_ticks_msec() + 15000
	while not bool(state.done) and Time.get_ticks_msec() < deadline and game_manager.is_inside_tree():
		await game_manager.get_tree().process_frame
	if game_manager.network.equipment_retrieve_warehouse_success.is_connected(on_success):
		game_manager.network.equipment_retrieve_warehouse_success.disconnect(on_success)
	if game_manager.network.equipment_retrieve_warehouse_failed.is_connected(on_failed):
		game_manager.network.equipment_retrieve_warehouse_failed.disconnect(on_failed)
	if bool(state.done):
		if bool(state.ok):
			_refresh_items_fullscreen(vbox, game_manager, category, stats_label, panel)
		else:
			_show_game_style_dialog(game_manager, "取出失败", state.message if not String(state.message).is_empty() else "取出失败")
	else:
		_show_game_style_dialog(game_manager, "取出失败", "服务器响应超时，请稍后重试。")

static func _withdraw_pet_equipment_entry(game_manager, equip_id: String, vbox: VBoxContainer, stats_label: Label, category: String, panel: Control) -> void :
	if game_manager == null or game_manager.network == null or not game_manager.network.is_logged_in():
		return
	var op_id: = "warehouse_take_pet_equipment_%s_%d_%d" % [equip_id, Time.get_unix_time_from_system(), Time.get_ticks_msec()]
	var state: = {"done": false, "ok": false, "message": ""}
	var on_success = func(data: Dictionary):
		state.done = true
		state.ok = true
		state.message = str(data.get("message", "已从宠装仓库取出"))
		if game_manager and data.has("saveData") and data.get("saveData") is Dictionary:
			game_manager.apply_cloud_save(data.get("saveData"), {"authoritative_equipment_inventory": true})
	var on_failed = func(error: String):
		state.done = true
		state.ok = false
		state.message = error
	game_manager.network.pet_equipment_retrieve_warehouse_success.connect(on_success, CONNECT_ONE_SHOT)
	game_manager.network.pet_equipment_retrieve_warehouse_failed.connect(on_failed, CONNECT_ONE_SHOT)
	game_manager.network.request_pet_equipment_retrieve_warehouse(equip_id, op_id)
	var deadline: = Time.get_ticks_msec() + 15000
	while not bool(state.done) and Time.get_ticks_msec() < deadline and game_manager.is_inside_tree():
		await game_manager.get_tree().process_frame
	if game_manager.network.pet_equipment_retrieve_warehouse_success.is_connected(on_success):
		game_manager.network.pet_equipment_retrieve_warehouse_success.disconnect(on_success)
	if game_manager.network.pet_equipment_retrieve_warehouse_failed.is_connected(on_failed):
		game_manager.network.pet_equipment_retrieve_warehouse_failed.disconnect(on_failed)
	if bool(state.done) and bool(state.ok):
		_refresh_items_fullscreen(vbox, game_manager, category, stats_label, panel)
	elif bool(state.done) and not bool(state.ok):
		_show_game_style_dialog(game_manager, "取出失败", state.message if not String(state.message).is_empty() else "取出失败")

static func _create_limit_material_aggregate_row_fullscreen(container: VBoxContainer, aggregate: Dictionary, game_manager, 
		stats_label: Label, category: String, panel: Control):
	var item_panel = Panel.new()
	item_panel.custom_minimum_size = Vector2(0, 60)
	item_panel.add_theme_stylebox_override("panel", UIStyle.create_item_style())
	container.add_child(item_panel)

	var item_hbox = HBoxContainer.new()
	item_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	item_hbox.offset_left = 10
	item_hbox.offset_top = 5
	item_hbox.offset_right = -10
	item_hbox.offset_bottom = -5
	item_panel.add_child(item_hbox)

	var item_name: = str(aggregate.get("name", "极限材料"))
	var item_count: = int(aggregate.get("count", 0))

	var name_label = Label.new()
	name_label.text = item_name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.25))
	item_hbox.add_child(name_label)

	var count_label = Label.new()
	count_label.text = "x%d" % item_count
	count_label.add_theme_font_size_override("font_size", 16)
	count_label.add_theme_color_override("font_color", Color(0.894, 0.864, 0.803))
	item_hbox.add_child(count_label)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_hbox.add_child(spacer)

	var detail_btn = Button.new()
	detail_btn.text = "操作"
	detail_btn.custom_minimum_size = Vector2(70, 40)
	detail_btn.add_theme_font_size_override("font_size", 16)
	UIStyle.apply_button_style(detail_btn)
	detail_btn.pressed.connect( func():
		if game_manager == null:
			return
		var main_ui = null
		if "main_ui" in game_manager:
			main_ui = game_manager.main_ui
		if main_ui and main_ui.has_method("_show_limit_material_aggregate_popup"):
			main_ui._show_limit_material_aggregate_popup(aggregate)
	)
	item_hbox.add_child(detail_btn)

static func _create_item_row_fullscreen(container: VBoxContainer, item, game_manager, 
		stats_label: Label, category: String, panel: Control):

	var item_panel = Panel.new()
	item_panel.custom_minimum_size = Vector2(0, 60)
	item_panel.add_theme_stylebox_override("panel", UIStyle.create_item_style())
	container.add_child(item_panel)

	var item_hbox = HBoxContainer.new()
	item_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	item_hbox.offset_left = 10
	item_hbox.offset_top = 5
	item_hbox.offset_right = -10
	item_hbox.offset_bottom = -5
	item_panel.add_child(item_hbox)

	var item_data = GameData.ALL_ITEMS.get(item.name, {})
	var item_name = item_data.get("name", item.name)


	if item.item_type == "sealed_suit":
		var cd: Dictionary = item.custom_data if item.custom_data is Dictionary else {}
		var nm: = str(cd.get("name", "")).strip_edges()
		if not nm.is_empty():
			item_name = nm
		else:
			var suit_level: = int(cd.get("suit_level", 0))
			var slot: = str(cd.get("slot", ""))
			if suit_level > 0 and not slot.is_empty():
				item_name = SuitDatabaseDetailed.get_sealed_suit_display_name(suit_level, slot)
			else:
				item_name = "封印套装"

	var name_label = Label.new()
	name_label.text = item_name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
	item_hbox.add_child(name_label)

	var count_label = Label.new()
	count_label.text = "x%d" % item.count
	count_label.add_theme_font_size_override("font_size", 16)
	count_label.add_theme_color_override("font_color", Color(0.734, 0.714, 0.657))
	item_hbox.add_child(count_label)


	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_hbox.add_child(spacer)

	var take_btn = Button.new()
	take_btn.text = "取出"
	take_btn.custom_minimum_size = Vector2(70, 40)
	take_btn.add_theme_font_size_override("font_size", 16)
	UIStyle.apply_button_style(take_btn)
	take_btn.pressed.connect( func():
		if game_manager == null or game_manager.network == null or not game_manager.network.is_logged_in():
			return
		take_btn.disabled = true
		var op_id: = "warehouse_take_item_%s_%d_%d" % [str(item.id), Time.get_unix_time_from_system(), Time.get_ticks_msec()]
		var state: = {"done": false, "ok": false, "message": ""}
		var on_success = func(data: Dictionary):
			state.done = true
			state.ok = true
			state.message = str(data.get("message", "已从仓库取出"))
			if game_manager and data.has("saveData") and data.get("saveData") is Dictionary:
				game_manager.apply_cloud_save(data.get("saveData"), {"authoritative_equipment_inventory": true})
		var on_failed = func(error: String):
			state.done = true
			state.ok = false
			state.message = error
		game_manager.network.equipment_retrieve_warehouse_success.connect(on_success, CONNECT_ONE_SHOT)
		game_manager.network.equipment_retrieve_warehouse_failed.connect(on_failed, CONNECT_ONE_SHOT)
		game_manager.network.request_equipment_retrieve_warehouse(str(item.id), "item", op_id)
		var deadline: = Time.get_ticks_msec() + 15000
		while not bool(state.done) and Time.get_ticks_msec() < deadline and game_manager.is_inside_tree():
			await game_manager.get_tree().process_frame
		if game_manager.network.equipment_retrieve_warehouse_success.is_connected(on_success):
			game_manager.network.equipment_retrieve_warehouse_success.disconnect(on_success)
		if game_manager.network.equipment_retrieve_warehouse_failed.is_connected(on_failed):
			game_manager.network.equipment_retrieve_warehouse_failed.disconnect(on_failed)
		take_btn.disabled = false
		if bool(state.done):
			if bool(state.ok):
				_refresh_items_fullscreen(container.get_parent().get_parent().get_parent(), 
					game_manager, category, stats_label, panel)
			else:
				_show_game_style_dialog(game_manager, "取出失败", state.message if not String(state.message).is_empty() else "取出失败")
		else:
			_show_game_style_dialog(game_manager, "取出失败", "服务器响应超时，请稍后重试。")
	)
	item_hbox.add_child(take_btn)

static func _create_equipment_row_fullscreen(container: VBoxContainer, equip: Dictionary, game_manager, 
		stats_label: Label, category: String, panel: Control):

	var item_panel = Panel.new()
	item_panel.custom_minimum_size = Vector2(0, 80)
	item_panel.add_theme_stylebox_override("panel", UIStyle.create_item_style())
	container.add_child(item_panel)

	var item_hbox = HBoxContainer.new()
	item_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	item_hbox.offset_left = 10
	item_hbox.offset_top = 5
	item_hbox.offset_right = -10
	item_hbox.offset_bottom = -5
	item_panel.add_child(item_hbox)


	var rarity_colors = {
		"common": Color(0.925, 0.898, 0.840), 
		"uncommon": Color(0.440, 0.740, 0.560), 
		"rare": Color(0.490, 0.700, 0.870), 
		"epic": Color(0.700, 0.540, 0.800), 
		"legendary": Color(0.960, 0.760, 0.390), 
		"mythic": Color(0.900, 0.520, 0.440)
	}


	var icon_names = {
		"weapon": "武器", 
		"armor": "防具", 
		"helmet": "帽子", 
		"boots": "鞋子", 
		"accessory": "饰品"
	}
	var icon_name = icon_names.get(equip.slot, "")
	var icon_texture = AssetManager.get_instance().get_item(icon_name) if not icon_name.is_empty() else null

	var icon
	if icon_texture:
		icon = TextureRect.new()
		icon.texture = icon_texture
		icon.custom_minimum_size = Vector2(50, 50)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	else:
		icon = ColorRect.new()
		icon.custom_minimum_size = Vector2(50, 50)
		icon.color = rarity_colors.get(equip.rarity, Color(0.7, 0.7, 0.7))
	item_hbox.add_child(icon)


	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 3)

	var name_label = Label.new()
	name_label.text = equip.name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", rarity_colors.get(equip.rarity, Color(0.945, 0.912, 0.850)))
	info_vbox.add_child(name_label)

	var stats_text = ""
	if bool(equip.get("is_suit", false)) and not bool(equip.get("is_sealed", false)):
		stats_text = SuitEquipmentEnhance.format_equipment_stats_line(equip)
	else:
		if int(equip.get("attack", 0)) > 0:
			stats_text += "攻击+%d " % int(equip.get("attack", 0))
		if int(equip.get("defense", 0)) > 0:
			stats_text += "防御+%d " % int(equip.get("defense", 0))
		if int(equip.get("hp", 0)) > 0:
			stats_text += "生命+%d " % int(equip.get("hp", 0))
		if int(equip.get("mp", 0)) > 0:
			stats_text += "内力+%d " % int(equip.get("mp", 0))
		if int(equip.get("agility", 0)) > 0:
			stats_text += "敏捷+%d " % int(equip.get("agility", 0))

	var stats_label2 = Label.new()
	stats_label2.text = stats_text
	stats_label2.add_theme_font_size_override("font_size", 16)
	stats_label2.add_theme_color_override("font_color", Color(0.734, 0.714, 0.657))
	info_vbox.add_child(stats_label2)

	item_hbox.add_child(info_vbox)


	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_hbox.add_child(spacer)


	var take_btn = Button.new()
	take_btn.text = "取出"
	take_btn.custom_minimum_size = Vector2(70, 40)
	take_btn.add_theme_font_size_override("font_size", 16)
	UIStyle.apply_button_style(take_btn)
	take_btn.pressed.connect( func():
		if game_manager == null or game_manager.network == null or not game_manager.network.is_logged_in():
			return
		take_btn.disabled = true
		var op_id: = "warehouse_take_equipment_%s_%d_%d" % [str(equip.id), Time.get_unix_time_from_system(), Time.get_ticks_msec()]
		var state: = {"done": false, "ok": false, "message": ""}
		var on_success = func(data: Dictionary):
			state.done = true
			state.ok = true
			state.message = str(data.get("message", "已从仓库取出"))
			if game_manager and data.has("saveData") and data.get("saveData") is Dictionary:
				game_manager.apply_cloud_save(data.get("saveData"), {"authoritative_equipment_inventory": true})
		var on_failed = func(error: String):
			state.done = true
			state.ok = false
			state.message = error
		game_manager.network.equipment_retrieve_warehouse_success.connect(on_success, CONNECT_ONE_SHOT)
		game_manager.network.equipment_retrieve_warehouse_failed.connect(on_failed, CONNECT_ONE_SHOT)
		game_manager.network.request_equipment_retrieve_warehouse(str(equip.id), "equipment", op_id)
		var deadline: = Time.get_ticks_msec() + 15000
		while not bool(state.done) and Time.get_ticks_msec() < deadline and game_manager.is_inside_tree():
			await game_manager.get_tree().process_frame
		if game_manager.network.equipment_retrieve_warehouse_success.is_connected(on_success):
			game_manager.network.equipment_retrieve_warehouse_success.disconnect(on_success)
		if game_manager.network.equipment_retrieve_warehouse_failed.is_connected(on_failed):
			game_manager.network.equipment_retrieve_warehouse_failed.disconnect(on_failed)
		take_btn.disabled = false
		if bool(state.done):
			if bool(state.ok):
				_refresh_items_fullscreen(container.get_parent().get_parent().get_parent(), 
					game_manager, category, stats_label, panel)
			else:
				_show_game_style_dialog(game_manager, "取出失败", state.message if not String(state.message).is_empty() else "取出失败")
		else:
			_show_game_style_dialog(game_manager, "取出失败", "服务器响应超时，请稍后重试。")
	)
	item_hbox.add_child(take_btn)

static func _create_pet_equipment_row_fullscreen(container: VBoxContainer, equip: Dictionary, game_manager, 
		stats_label: Label, category: String, panel: Control):

	var item_panel = Panel.new()
	item_panel.custom_minimum_size = Vector2(0, 80)
	item_panel.add_theme_stylebox_override("panel", UIStyle.create_item_style())
	container.add_child(item_panel)

	var item_hbox = HBoxContainer.new()
	item_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	item_hbox.offset_left = 10
	item_hbox.offset_top = 5
	item_hbox.offset_right = -10
	item_hbox.offset_bottom = -5
	item_panel.add_child(item_hbox)

	var rarity_colors = {
		"common": Color(0.925, 0.898, 0.840), 
		"uncommon": Color(0.440, 0.740, 0.560), 
		"rare": Color(0.490, 0.700, 0.870), 
		"epic": Color(0.700, 0.540, 0.800), 
		"legendary": Color(0.960, 0.760, 0.390), 
		"mythic": Color(0.900, 0.520, 0.440), 
		"divine": Color(1.000, 0.860, 0.400), 
		"suit": Color(0.960, 0.760, 0.390)
	}

	var equip_rarity = _get_pet_equip_value(equip, "rarity")
	var equip_name = _get_pet_equip_value(equip, "name")
	var equip_slot = _get_pet_equip_value(equip, "slot")
	var equip_attack = _get_pet_equip_value(equip, "attack")
	var equip_defense = _get_pet_equip_value(equip, "defense")
	var equip_hp = _get_pet_equip_value(equip, "hp")
	var equip_agility = _get_pet_equip_value(equip, "agility")
	var equip_id = _get_pet_equip_value(equip, "id")

	var icon_names = {
		"weapon": "武器", 
		"armor": "防具", 
		"helmet": "帽子", 
		"boots": "鞋子", 
		"accessory": "饰品"
	}
	var icon_name = icon_names.get(equip_slot, "")
	var icon_texture = AssetManager.get_instance().get_item(icon_name) if not icon_name.is_empty() else null

	var icon
	if icon_texture:
		icon = TextureRect.new()
		icon.texture = icon_texture
		icon.custom_minimum_size = Vector2(50, 50)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	else:
		icon = ColorRect.new()
		icon.custom_minimum_size = Vector2(50, 50)
		icon.color = rarity_colors.get(equip_rarity, Color(0.7, 0.7, 0.7))
	item_hbox.add_child(icon)

	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 3)

	var name_label = Label.new()
	name_label.text = equip_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", rarity_colors.get(equip_rarity, Color(0.945, 0.912, 0.850)))
	info_vbox.add_child(name_label)

	var slot_names = {
		"weapon": "武器", 
		"armor": "防具", 
		"helmet": "头盔", 
		"accessory": "饰品"
	}
	var slot_label = Label.new()
	slot_label.text = "部位: %s" % slot_names.get(equip_slot, equip_slot)
	slot_label.add_theme_font_size_override("font_size", 14)
	info_vbox.add_child(slot_label)

	var stats_text: = PetEquipmentEnhance.format_effective_stats_line(equip)

	var stats_label2 = Label.new()
	stats_label2.text = stats_text
	stats_label2.add_theme_font_size_override("font_size", 14)
	stats_label2.add_theme_color_override("font_color", Color(0.734, 0.714, 0.657))
	info_vbox.add_child(stats_label2)

	item_hbox.add_child(info_vbox)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_hbox.add_child(spacer)

	var take_btn = Button.new()
	take_btn.text = "取出"
	take_btn.custom_minimum_size = Vector2(70, 40)
	take_btn.add_theme_font_size_override("font_size", 16)
	UIStyle.apply_button_style(take_btn)
	take_btn.pressed.connect( func():
		if game_manager == null or game_manager.network == null or not game_manager.network.is_logged_in():
			return
		take_btn.disabled = true
		var op_id: = "warehouse_take_pet_equipment_%s_%d_%d" % [str(equip_id), Time.get_unix_time_from_system(), Time.get_ticks_msec()]
		var state: = {"done": false, "ok": false, "message": ""}
		var on_success = func(data: Dictionary):
			state.done = true
			state.ok = true
			state.message = str(data.get("message", "已从宠装仓库取出"))
			if game_manager and data.has("saveData") and data.get("saveData") is Dictionary:
				game_manager.apply_cloud_save(data.get("saveData"), {"authoritative_equipment_inventory": true})
		var on_failed = func(error: String):
			state.done = true
			state.ok = false
			state.message = error
		game_manager.network.pet_equipment_retrieve_warehouse_success.connect(on_success, CONNECT_ONE_SHOT)
		game_manager.network.pet_equipment_retrieve_warehouse_failed.connect(on_failed, CONNECT_ONE_SHOT)
		game_manager.network.request_pet_equipment_retrieve_warehouse(str(equip_id), op_id)
		var deadline: = Time.get_ticks_msec() + 15000
		while not bool(state.done) and Time.get_ticks_msec() < deadline and game_manager.is_inside_tree():
			await game_manager.get_tree().process_frame
		if game_manager.network.pet_equipment_retrieve_warehouse_success.is_connected(on_success):
			game_manager.network.pet_equipment_retrieve_warehouse_success.disconnect(on_success)
		if game_manager.network.pet_equipment_retrieve_warehouse_failed.is_connected(on_failed):
			game_manager.network.pet_equipment_retrieve_warehouse_failed.disconnect(on_failed)
		take_btn.disabled = false
		if bool(state.done) and bool(state.ok):
			_refresh_items_fullscreen(container.get_parent().get_parent().get_parent(), 
				game_manager, category, stats_label, panel)
	)
	item_hbox.add_child(take_btn)

static func _setup_mouse_filter(container: Control):
	for child in container.get_children():
		if child is Control:
			if child is Button:
				child.mouse_filter = Control.MOUSE_FILTER_STOP
			else:
				child.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if child is Container:
				_setup_mouse_filter(child)

static func _find_main_ui(game_manager) -> Control:
	if game_manager == null or game_manager.get_tree() == null:
		return null
	var root: Window = game_manager.get_tree().root
	if root == null:
		return null
	var main_ui = root.get_node_or_null("MainUI")
	if main_ui:
		return main_ui
	var main = root.get_node_or_null("Main")
	if main:
		main_ui = main.get_node_or_null("MainUI")
		if main_ui:
			return main_ui
		var canvas_layer = main.get_node_or_null("MainCanvasLayer")
		if canvas_layer:
			main_ui = canvas_layer.get_node_or_null("MainUI")
			if main_ui:
				return main_ui
	for child in root.get_children():
		if child.name == "MainUI":
			return child
		if child.has_node("MainUI"):
			return child.get_node("MainUI")
		if child.name == "MainCanvasLayer":
			main_ui = child.get_node_or_null("MainUI")
			if main_ui:
				return main_ui
	return null

static func _show_game_style_dialog(game_manager, title: String, message: String) -> void :
	var main_ui = _find_main_ui(game_manager)
	if main_ui and main_ui.has_method("_show_simple_dialog"):
		main_ui.call("_show_simple_dialog", title, message)
		return
	var tree: = Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var root: = tree.current_scene if tree.current_scene != null else tree.root
	if root == null:
		return
	var dialog: = Window.new()
	dialog.title = ""
	dialog.size = Vector2i(450, 260)
	dialog.transparent = true
	dialog.borderless = true
	dialog.unresizable = true
	dialog.close_requested.connect( func():
		if is_instance_valid(dialog):
			dialog.queue_free()
	)
	var main_panel: = Panel.new()
	main_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_panel.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	dialog.add_child(main_panel)
	var vbox: = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 25
	vbox.offset_top = 25
	vbox.offset_right = -25
	vbox.offset_bottom = -25
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	main_panel.add_child(vbox)
	var title_label: = Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(title_label)
	var msg_label: = Label.new()
	msg_label.text = message
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_label.add_theme_font_size_override("font_size", 18)
	msg_label.add_theme_color_override("font_color", Color(0.894, 0.864, 0.803))
	vbox.add_child(msg_label)
	var ok_btn: = Button.new()
	ok_btn.text = "确定"
	UIStyle.style_popup_button(ok_btn, true)
	ok_btn.pressed.connect( func():
		if is_instance_valid(dialog):
			dialog.queue_free()
	)
	vbox.add_child(ok_btn)
	root.add_child(dialog)
	dialog.popup_centered()

static func _get_pet_equip_value(equipment, key: String) -> Variant:
	if equipment is Dictionary:
		var val = equipment.get(key, null)
		if val != null:
			return val
		match key:
			"id", "name", "slot", "rarity": return ""
			_: return 0
	elif equipment is Object:
		match key:
			"id": return equipment.id
			"name": return equipment.name
			"slot": return equipment.slot
			"rarity": return equipment.rarity
			"attack": return equipment.attack
			"defense": return equipment.defense
			"hp": return equipment.hp
			"mp": return equipment.mp
			"agility": return equipment.agility
			_: return 0
	else:
		match key:
			"id", "name", "slot", "rarity": return ""
			_: return 0
