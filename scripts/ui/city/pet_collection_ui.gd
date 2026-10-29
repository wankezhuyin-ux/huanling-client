


extends RefCounted

const PetCollectionManager = preload("res://scripts/pet_collection/pet_collection_manager.gd")
const PetCollectionData = preload("res://scripts/pet_collection/pet_collection_data.gd")
const GameData = preload("res://scripts/game_data.gd")
const UIStyle = preload("res://scripts/ui_style.gd")
const PetIdleDisplay = preload("res://scripts/ui/pet_idle_display.gd")
const TouchScrollUtils = preload("res://scripts/ui/touch_scroll_utils.gd")
const WindowHost = preload("res://scripts/ui/window_host.gd")


const ELEMENTS = ["全部", "金", "木", "水", "火", "土"]
## 五行色：保留传统色相（金白、木青、水玄、火赤、土黄），只把亮度收到墨底上能读的区间。
const ELEMENT_COLORS = {
	"金": Color(0.900, 0.780, 0.440), 
	"木": Color(0.460, 0.700, 0.500), 
	"水": Color(0.480, 0.640, 0.800), 
	"火": Color(0.820, 0.400, 0.320), 
	"土": Color(0.700, 0.580, 0.400), 
	"天": Color(0.860, 0.760, 0.560), 
	"全部": Color(0.700, 0.680, 0.630)
}


const CARD_SIZE = Vector2(118, 158)
const CARD_MARGIN = 10
const GRID_COLUMNS = 5

static func create_fullscreen(game_manager, show_title: bool = true) -> Control:

	var vbox = VBoxContainer.new()
	vbox.name = "PetCollectionRoot"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)


	if show_title:
		var title = UIStyle.create_title_label("宠物图鉴")
		vbox.add_child(title)


	var bonus_label = Label.new()
	bonus_label.name = "BonusLabel"
	bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bonus_label.add_theme_font_size_override("font_size", 20)
	bonus_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(bonus_label)

	var tip_label = Label.new()
	tip_label.name = "TipLabel"
	tip_label.text = "【图鉴加成仅对出战宠物生效】"
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_label.add_theme_font_size_override("font_size", 18)
	tip_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))
	vbox.add_child(tip_label)

	var filter_hbox = HBoxContainer.new()
	filter_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	filter_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(filter_hbox)

	var current_filter = "全部"
	var filter_buttons = []

	for element in ELEMENTS:
		var btn = Button.new()
		btn.text = element
		btn.custom_minimum_size = Vector2(60, 35)
		btn.add_theme_font_size_override("font_size", 20)
		UIStyle.apply_tab_style(btn, element == "全部")
		filter_hbox.add_child(btn)
		filter_buttons.append({"btn": btn, "element": element})

		btn.pressed.connect( func():
			current_filter = element
			for fb in filter_buttons:
				UIStyle.apply_tab_style(fb.btn, fb.element == current_filter)
			_update_grid(vbox, current_filter)
		)


	var search_hbox = HBoxContainer.new()
	search_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	search_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(search_hbox)

	var search_label = Label.new()
	search_label.text = "搜索:"
	search_label.add_theme_font_size_override("font_size", 20)
	search_hbox.add_child(search_label)

	var search_edit = LineEdit.new()
	search_edit.name = "SearchEdit"
	search_edit.placeholder_text = "输入宠物名称..."
	search_edit.custom_minimum_size = Vector2(200, 30)
	search_edit.add_theme_font_size_override("font_size", 20)
	search_hbox.add_child(search_edit)

	var clear_btn = Button.new()
	clear_btn.text = "清除"
	clear_btn.custom_minimum_size = Vector2(60, 30)
	clear_btn.add_theme_font_size_override("font_size", 18)
	UIStyle.apply_button_style(clear_btn)
	clear_btn.pressed.connect( func():
		search_edit.text = ""
		_update_grid(vbox, current_filter)
	)
	search_hbox.add_child(clear_btn)


	var scroll = ScrollContainer.new()
	scroll.name = "ScrollContainer"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 500)
	TouchScrollUtils.configure_scroll(scroll, true)
	vbox.add_child(scroll)


	var center_hbox = HBoxContainer.new()
	center_hbox.name = "CenterHBox"
	center_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_hbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	center_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(center_hbox)


	var margin_container = MarginContainer.new()
	margin_container.name = "MarginContainer"
	margin_container.add_theme_constant_override("margin_bottom", 24)
	margin_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_hbox.add_child(margin_container)


	var grid = GridContainer.new()
	grid.name = "GridContainer"
	grid.columns = GRID_COLUMNS
	grid.add_theme_constant_override("h_separation", CARD_MARGIN)
	grid.add_theme_constant_override("v_separation", 16)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin_container.add_child(grid)


	vbox.set_meta("game_manager", game_manager)
	vbox.set_meta("current_filter", "全部")
	vbox.set_meta("collection_manager", game_manager.pet_collection_manager if game_manager else null)
	vbox.set_meta("grid_container", grid)
	vbox.set_meta("search_edit", search_edit)
	vbox.set_meta("bonus_label", bonus_label)
	vbox.set_meta("initialized", false)


	search_edit.text_changed.connect( func(_text):
		_update_grid(vbox, current_filter)
	)




	if game_manager and game_manager.pet_collection_manager:
		game_manager.pet_collection_manager.total_bonuses_updated.connect( func(_bonuses):
			_update_bonus_display(vbox)
		)

	return vbox

static func _update_grid(panel: Control, filter_element: String):
	if panel == null:
		print("[PetCollectionUI] _update_grid called with null panel!")
		return

	if not panel.has_meta("collection_manager"):
		print("[PetCollectionUI] panel missing collection_manager meta!")
		return

	var collection_manager = panel.get_meta("collection_manager")
	var game_manager = panel.get_meta("game_manager")
	var grid = panel.get_meta("grid_container")
	var search_edit = panel.get_meta("search_edit")

	if not collection_manager or not grid or not search_edit:
		return


	var search_text = ""
	if search_edit:
		search_text = search_edit.text.to_lower()


	var pet_ids = []
	if collection_manager.has_method("get_all_pet_ids"):
		pet_ids = collection_manager.get_all_pet_ids()
	else:
		return

	if pet_ids.is_empty():
		return

	var filtered_pets = []

	for pet_id in pet_ids:
		var pet_data = collection_manager.get_pet_base_data(pet_id)
		if pet_data.is_empty():
			continue


		if filter_element != "全部":
			var pet_element = pet_data.get("element", "")
			if pet_element != filter_element:
				continue


		if search_text != "":
			var pet_name = pet_data.get("name", "").to_lower()
			if search_text not in pet_name and search_text not in pet_id.to_lower():
				continue

		filtered_pets.append(pet_id)

	if filtered_pets.is_empty():
		return


	for child in grid.get_children():
		child.queue_free()


	for pet_id in filtered_pets:
		var card = _create_pet_card(panel, pet_id)
		if card:
			grid.add_child(card)


	grid.queue_sort()


static func initialize_grid(panel: Control):
	refresh_on_open(panel)


static func refresh_on_open(panel: Control):
	if panel == null:
		return
	var game_manager = panel.get_meta("game_manager") if panel.has_meta("game_manager") else null
	if game_manager and game_manager.has_method("refresh_pet_collection_for_ui"):
		game_manager.refresh_pet_collection_for_ui()
	if game_manager and game_manager.pet_collection_manager:
		panel.set_meta("collection_manager", game_manager.pet_collection_manager)
	var filter_element: String = str(panel.get_meta("current_filter", "全部"))
	_update_bonus_display(panel)
	_update_grid(panel, filter_element)
	panel.set_meta("initialized", true)


static func refresh_grid(panel: Control):
	var grid = panel.get_meta("grid_container")
	if grid:
		grid.queue_sort()

		for child in grid.get_children():
			child.queue_redraw()

static func _create_pet_card(panel: Control, pet_id: String) -> Control:
	var collection_manager = panel.get_meta("collection_manager")
	var game_manager = panel.get_meta("game_manager")

	if not collection_manager:
		return null

	var pet_data = collection_manager.get_pet_base_data(pet_id)
	var collection_info = collection_manager.get_collection_info(pet_id)
	var is_display_only = bool(pet_data.get("collection_disabled", false) or pet_data.get("collection_display_only", false))

	var card = Panel.new()
	card.custom_minimum_size = CARD_SIZE
	card.clip_contents = true


	var is_activated = collection_info.count > 0 or bool(collection_info.get("has_mutation", false))
	var has_mutation = bool(collection_info.get("has_mutation", false))
	var style = StyleBoxFlat.new()
	if has_mutation:
		style.bg_color = Color(0.072, 0.080, 0.079, 0.95)
		style.border_color = Color(0.915, 0.797, 0.502, 1)
	elif is_activated:
		style.bg_color = Color(0.072, 0.080, 0.079, 0.95)
		style.border_color = Color(0.788, 0.635, 0.294, 1)
	else:
		style.bg_color = Color(0.048, 0.057, 0.059, 0.8)
		style.border_color = Color(0.655, 0.531, 0.245, 0.5)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	card.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 4
	vbox.offset_top = 4
	vbox.offset_right = -4
	vbox.offset_bottom = -4
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vbox)


	var texture_rect = TextureRect.new()
	texture_rect.name = "PetImage"
	texture_rect.custom_minimum_size = Vector2(64, 64)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(texture_rect)


	var image_path = collection_manager.get_pet_image_path(pet_id)
	_load_image_async(texture_rect, image_path)


	var name_label = Label.new()
	name_label.text = pet_data.get("name", pet_id)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_activated:
		name_label.add_theme_color_override("font_color", Color(1, 1, 1))
	else:
		name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	vbox.add_child(name_label)


	var progress_label = Label.new()
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size", 14)
	progress_label.clip_text = true
	progress_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	progress_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if is_display_only:
		progress_label.text = "活动限定"
		progress_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))
	elif has_mutation:
		var mut_n = int(collection_info.get("mutation_count", 0))
		var mut_max = int(collection_info.get("mutation_max", PetCollectionData.MUTATION_MAX))
		if bool(collection_info.get("is_mutation_max", false)):
			progress_label.text = "MAX+变%d/%d" % [mut_n, mut_max]
		else:
			progress_label.text = "MAX+变%d/%d" % [mut_n, mut_max]
		progress_label.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
	elif bool(collection_info.get("is_normal_max", false)) or collection_info.count >= 50:
		progress_label.text = "MAX"
		progress_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	elif collection_info.count > 0:
		var stage_name = _get_stage_name(collection_info.count)
		progress_label.text = "%s Lv.%d/50" % [stage_name, collection_info.count]
		progress_label.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
	else:
		progress_label.text = "未激活"
		progress_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))

	vbox.add_child(progress_label)


	var bonus_label = Label.new()
	bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bonus_label.add_theme_font_size_override("font_size", 13)
	bonus_label.clip_text = true
	bonus_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	bonus_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bonus_text = "仅展示（不加成）" if is_display_only else "%s+%s%%" % [
		collection_info.bonus_type_name, 
		PetCollectionData.format_bonus_percent(collection_info.current_bonus)
	]
	bonus_label.text = bonus_text

	if is_display_only:
		bonus_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.35))
	elif has_mutation:
		bonus_label.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
	elif is_activated:
		bonus_label.add_theme_color_override("font_color", Color(0.8, 1, 0.8))
	else:
		bonus_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))

	vbox.add_child(bonus_label)


	var captured_pet_id: = str(pet_id)
	TouchScrollUtils.bind_tap(card, func():
		_show_pet_detail(panel, captured_pet_id)
	)

	return card

static func _create_pet_detail_image_row(display_size: Vector2) -> CenterContainer:
	var row: = CenterContainer.new()
	row.name = "PetImageRow"
	row.custom_minimum_size = Vector2(0, display_size.y)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return row

static func _add_pet_detail_image(row: CenterContainer, pet_id: String, collection_manager, display_size: Vector2) -> void :
	var widget: = PetIdleDisplay.create_avatar_widget(pet_id, display_size)
	row.add_child(widget)
	var static_img: TextureRect = null
	if widget != null:
		static_img = widget.find_child("PetStaticImage", true, false) as TextureRect
	if static_img != null and static_img.texture == null:
		var image_path = collection_manager.get_pet_image_path(pet_id)
		_load_image_async(static_img, image_path)

static func _load_image_async(texture_rect: TextureRect, image_path: String):

	if ResourceLoader.exists(image_path):
		var texture = ResourceLoader.load(image_path, "Texture2D", ResourceLoader.CACHE_MODE_REUSE)
		if texture:
			texture_rect.texture = texture
		else:

			_show_placeholder(texture_rect)
	else:
		_show_placeholder(texture_rect)

static func _show_placeholder(texture_rect: TextureRect):

	var placeholder = PlaceholderTexture2D.new()
	placeholder.size = Vector2(60, 60)
	texture_rect.texture = placeholder

static func _close_collection_detail_popups(from_node: Node) -> void :

	var n: Node = from_node
	while n != null:
		var kids: Array = n.get_children()
		for child in kids:
			if child != null and is_instance_valid(child) and str(child.name) == "DetailPopup":
				n.remove_child(child)
				child.queue_free()
		n = n.get_parent()
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return
	var host: Node = tree.root
	if from_node != null and from_node.is_inside_tree():
		var win = from_node.get_window()
		if win != null:
			host = win
	for child in host.get_children():
		if child != null and is_instance_valid(child) and str(child.name) == "DetailPopup":
			host.remove_child(child)
			child.queue_free()

static func _show_pet_detail(panel: Control, pet_id: String):
	var collection_manager = panel.get_meta("collection_manager")
	var game_manager = panel.get_meta("game_manager")

	if not collection_manager or not game_manager:
		return

	_close_collection_detail_popups(panel)

	var pet_data = collection_manager.get_pet_base_data(pet_id)
	var collection_info = collection_manager.get_collection_info(pet_id)
	var is_display_only = bool(pet_data.get("collection_disabled", false) or pet_data.get("collection_display_only", false))



	var dialog: = Window.new()
	dialog.name = "DetailPopup"
	dialog.title = ""
	dialog.size = Vector2i(400, 760)
	dialog.transparent = true
	dialog.borderless = true
	dialog.unresizable = true
	dialog.close_requested.connect( func(): dialog.queue_free())

	var popup = Panel.new()
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.add_theme_stylebox_override("panel", UIStyle.create_panel_style())
	dialog.add_child(popup)


	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 8)
	popup.add_child(vbox)


	var detail_image_size: = Vector2(120, 120)
	var image_row = _create_pet_detail_image_row(detail_image_size)
	vbox.add_child(image_row)
	_add_pet_detail_image(image_row, pet_id, collection_manager, detail_image_size)


	var name_label = Label.new()
	name_label.text = pet_data.get("name", pet_id)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	vbox.add_child(name_label)


	var element = pet_data.get("element", "未知")
	var element_label = Label.new()
	element_label.text = "五行: %s" % element
	element_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	element_label.add_theme_font_size_override("font_size", 20)
	element_label.add_theme_color_override("font_color", ELEMENT_COLORS.get(element, Color(0.7, 0.7, 0.7)))
	vbox.add_child(element_label)


	var pet_type = pet_data.get("type", "未知")
	var type_label = Label.new()
	type_label.text = "类型: %s" % pet_type
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.add_theme_font_size_override("font_size", 20)
	type_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(type_label)


	var ratio = pet_data.get("ratio", [33, 33, 34])
	var ratio_text = "攻%d%% 防%d%% 敏%d%%" % [ratio[0], ratio[1], ratio[2]]
	var ratio_label = Label.new()
	ratio_label.text = "属性比例: %s" % ratio_text
	ratio_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ratio_label.add_theme_font_size_override("font_size", 18)
	ratio_label.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
	vbox.add_child(ratio_label)


	var separator = HSeparator.new()
	vbox.add_child(separator)


	var stats_title = Label.new()
	stats_title.text = "1级属性"
	stats_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_title.add_theme_font_size_override("font_size", 21)
	stats_title.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
	vbox.add_child(stats_title)


	var stats_grid = GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 20)
	vbox.add_child(stats_grid)

	var stats = [
		["攻击", pet_data.get("attack", 0)], 
		["防御", pet_data.get("defense", 0)], 
		["敏捷", pet_data.get("agility", 0)], 
		["生命", pet_data.get("hp", 0)], 
		["成长", pet_data.get("growth", 0)], 
		["生命成长", pet_data.get("hp_growth", 0)]
	]

	for stat in stats:
		var label_name = Label.new()
		label_name.text = stat[0] + ":"
		label_name.add_theme_font_size_override("font_size", 18)
		label_name.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		stats_grid.add_child(label_name)

		var label_value = Label.new()
		label_value.text = str(stat[1])
		label_value.add_theme_font_size_override("font_size", 18)
		label_value.add_theme_color_override("font_color", Color(1, 1, 1))
		stats_grid.add_child(label_value)

	var flavor_text: String = str(pet_data.get("collection_flavor", "")).strip_edges()
	if flavor_text != "":
		var flavor_label = Label.new()
		flavor_label.text = flavor_text
		flavor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		flavor_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		flavor_label.custom_minimum_size = Vector2(320, 0)
		flavor_label.add_theme_font_size_override("font_size", 17)
		flavor_label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.55))
		vbox.add_child(flavor_label)


	var collection_separator = HSeparator.new()
	vbox.add_child(collection_separator)

	var collection_title = Label.new()
	collection_title.text = "图鉴进度"
	collection_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	collection_title.add_theme_font_size_override("font_size", 20)
	collection_title.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
	vbox.add_child(collection_title)

	var collection_label = Label.new()
	collection_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	collection_label.add_theme_font_size_override("font_size", 18)
	collection_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var collection_bonus_label: Label = null

	if is_display_only:
		collection_label.text = "活动限定：仅图鉴展示，不可投入激活"
		collection_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))
	elif bool(collection_info.get("has_mutation", false)):
		var mut_n = int(collection_info.get("mutation_count", 0))
		var mut_max = int(collection_info.get("mutation_max", PetCollectionData.MUTATION_MAX))

		collection_label.text = "普通+变异 (%d/50 + 变%d/%d)" % [
			collection_info.count, 
			mut_n, 
			mut_max
		]
		collection_label.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
		collection_bonus_label = Label.new()
		collection_bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		collection_bonus_label.add_theme_font_size_override("font_size", 18)
		collection_bonus_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var bonus_line: = "%s+%s%%" % [
			collection_info.bonus_type_name, 
			PetCollectionData.format_bonus_percent(collection_info.current_bonus)
		]
		if not bool(collection_info.get("is_mutation_max", false)):
			bonus_line += " (下级%s)" % PetCollectionData.format_bonus_percent_signed(collection_info.bonus_increase)
		collection_bonus_label.text = bonus_line
		collection_bonus_label.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
	elif bool(collection_info.get("is_normal_max", false)) or collection_info.count >= 50:
		collection_label.text = "已满级 (50/50) - %s+%s%%" % [
			collection_info.bonus_type_name, 
			PetCollectionData.format_bonus_percent(collection_info.current_bonus)
		]
		collection_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	elif collection_info.count > 0:
		var stage_name = _get_stage_name(collection_info.count)
		collection_label.text = "%s: %d/50 - %s+%s%% (下级%s)" % [
			stage_name, 
			collection_info.count, 
			collection_info.bonus_type_name, 
			PetCollectionData.format_bonus_percent(collection_info.current_bonus), 
			PetCollectionData.format_bonus_percent_signed(collection_info.bonus_increase)
		]
		collection_label.add_theme_color_override("font_color", Color(0.8, 1, 0.8))
	else:
		collection_label.text = "未激活 - 投入宠物可激活图鉴"
		collection_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))

	vbox.add_child(collection_label)
	if collection_bonus_label != null:
		vbox.add_child(collection_bonus_label)


	if not is_display_only:
		var collection_tip = Label.new()
		collection_tip.text = "（加成仅对出战宠物生效）"
		collection_tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		collection_tip.add_theme_font_size_override("font_size", 17)
		collection_tip.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))
		vbox.add_child(collection_tip)

	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_hbox)


	var close_btn = Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(100, 40)
	close_btn.add_theme_font_size_override("font_size", 20)
	UIStyle.apply_button_style(close_btn)
	close_btn.pressed.connect( func():
		dialog.queue_free()
	)
	btn_hbox.add_child(close_btn)

	if panel != null and is_instance_valid(panel) and panel.is_inside_tree():
		WindowHost.attach_window_and_popup_centered(dialog, panel)
	else:
		var tree: SceneTree = Engine.get_main_loop() as SceneTree
		if tree != null:
			WindowHost.attach_window_to_scene_root(dialog, tree)
		else:
			push_warning("[PetCollectionUI] 无法显示详情弹窗：无可用挂载点")
			dialog.queue_free()


static func _get_pet_ratio_text(pet_type: String) -> String:
	match pet_type:
		"攻血型":
			return "攻55% 防22% 敏23%"
		"攻敏型":
			return "攻50% 防17% 敏33%"
		"防血型":
			return "攻15% 防55% 敏30%"
		"防敏型":
			return "攻15% 防50% 敏35%"
		"血敏型":
			return "攻15% 防30% 敏55%"
		"攻防型":
			return "攻50% 防33% 敏17%"
		"敏攻型":
			return "攻45% 防17% 敏38%"
		"敏防型":
			return "攻17% 防45% 敏38%"
		"攻击型":
			return "攻55% 防22% 敏23%"
		"防御型":
			return "攻22% 防55% 敏23%"
		"敏捷型":
			return "攻22% 防23% 敏55%"
		"平均型":
			return "攻33% 防33% 敏34%"
		"平衡型":
			return "攻33% 防33% 敏34%"
		_:
			return "攻33% 防33% 敏34%"

static func _get_stage_name(count: int) -> String:
	if count <= 0:
		return "未激活"
	elif count <= 10:
		return "成长期"
	elif count <= 30:
		return "成熟期"
	else:
		return "完美期"

static func _update_bonus_display(panel: Control):
	if panel == null:
		print("[PetCollectionUI] _update_bonus_display called with null panel!")
		return

	if not panel.has_meta("collection_manager") or not panel.has_meta("bonus_label"):
		print("[PetCollectionUI] panel missing required meta data!")
		return

	var collection_manager = panel.get_meta("collection_manager")
	var bonus_label = panel.get_meta("bonus_label")

	if not collection_manager or not bonus_label:
		return

	var bonuses = collection_manager.get_total_bonuses()
	var text = "总加成: "
	var parts = []

	if bonuses.attack > 0:
		parts.append("攻击%s" % PetCollectionData.format_bonus_percent_signed(bonuses.attack))
	if bonuses.defense > 0:
		parts.append("防御%s" % PetCollectionData.format_bonus_percent_signed(bonuses.defense))
	if bonuses.agility > 0:
		parts.append("敏捷%s" % PetCollectionData.format_bonus_percent_signed(bonuses.agility))
	if bonuses.hp > 0:
		parts.append("生命%s" % PetCollectionData.format_bonus_percent_signed(bonuses.hp))

	if parts.size() > 0:
		text += " | ".join(parts)
	else:
		text += "暂无加成"

	bonus_label.text = text
