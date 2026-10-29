extends RefCounted
class_name FabaoBagPanel

const FabaoConfigRef = preload("res://scripts/fabao/fabao_config.gd")
const FabaoIconsRef = preload("res://scripts/fabao/fabao_icons.gd")
const FabaoApiRef = preload("res://scripts/fabao/fabao_api.gd")
const TouchScrollUtils = preload("res://scripts/ui/touch_scroll_utils.gd")
const WindowHost = preload("res://scripts/ui/window_host.gd")
const InventoryGridCell = preload("res://scripts/ui/inventory_grid_cell.gd")


static func open() -> void :
	var tree: = Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var win: = Window.new()
	win.title = ""
	win.borderless = true
	win.transparent = true
	var screen: = DisplayServer.window_get_size()
	win.size = Vector2i(mini(640, screen.x - 40), mini(780, screen.y - 80))
	win.close_requested.connect( func(): win.queue_free())
	var panel: = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var st: = StyleBoxFlat.new()
	st.bg_color = Color(0.08, 0.1, 0.15, 0.98)
	st.border_color = Color(0.4, 0.55, 0.85)
	st.set_border_width_all(2)
	st.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", st)
	win.add_child(panel)
	var vbox: = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 16
	vbox.offset_top = 16
	vbox.offset_right = -16
	vbox.offset_bottom = -16
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	var title_bar: = HBoxContainer.new()
	vbox.add_child(title_bar)
	var title: = Label.new()
	title.text = "法宝"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	title_bar.add_child(title)
	var close_btn: = Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(80, 40)
	close_btn.pressed.connect( func(): win.emit_signal("close_requested"))
	title_bar.add_child(close_btn)
	var hint: = Label.new()
	hint.text = "碎片请在背包材料里点开详情合成。未穿戴的法宝在人物装备格子里。"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 15)
	vbox.add_child(hint)
	var scroll: = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	TouchScrollUtils.configure_scroll(scroll)
	vbox.add_child(scroll)
	var content: = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)
	TouchScrollUtils.bind_content_touch_scroll(scroll, content)
	_fill_content(content)
	var host: = tree.current_scene
	if host is Control:
		WindowHost.attach_window_and_popup_centered(win, host)
	else:
		WindowHost.attach_window_to_scene_root(win, tree)


static func _fill_content(content: VBoxContainer) -> void :
	var gm = GameManager.instance
	var inv_mgr = gm.inventory_manager if gm else null
	var fm = gm.fabao_manager if gm else null
	var frag_title: = Label.new()
	frag_title.text = "碎片"
	frag_title.add_theme_font_size_override("font_size", 18)
	content.add_child(frag_title)
	for tid in FabaoConfigRef.all_template_ids():
		var fname: = FabaoConfigRef.fragment_item_name(tid)
		var cnt: = 0
		if inv_mgr:
			cnt = int(inv_mgr.get_item_count(fname)) if inv_mgr.has_method("get_item_count") else _count_item(inv_mgr, fname)
		var row: = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var icon: = TextureRect.new()
		icon.custom_minimum_size = Vector2(48, 48)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = FabaoIconsRef.tex_for_tier(tid, true)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
		var lab: = Label.new()
		lab.text = "%s  %d/%d" % [fname, cnt, FabaoConfigRef.SYNTH_FRAGMENT_COUNT]
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lab.add_theme_font_size_override("font_size", 16)
		row.add_child(lab)
		content.add_child(row)
	var bag_title: = Label.new()
	bag_title.text = "已有法宝"
	bag_title.add_theme_font_size_override("font_size", 18)
	content.add_child(bag_title)
	if fm and fm.equipped_fabao is Dictionary:
		content.add_child(_fabao_row(fm.equipped_fabao, true))
	if fm:
		for inst in fm.fabao_inventory:
			if inst is Dictionary:
				content.add_child(_fabao_row(inst, false))
	var uneq: = Button.new()
	uneq.text = "卸下法宝"
	uneq.custom_minimum_size = Vector2(0, 44)
	TouchScrollUtils.bind_tap(uneq, func():
		FabaoApiRef.unequip()
	)
	content.add_child(uneq)


static func _count_item(inv_mgr, item_name: String) -> int:
	var n: = 0
	if inv_mgr == null:
		return 0
	if "items" in inv_mgr:
		for it in inv_mgr.items:
			if it and str(it.name) == item_name:
				n += int(it.count) if "count" in it else 1
	return n


static func _fabao_row(inst: Dictionary, equipped: bool) -> Control:
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var icon: = TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = FabaoIconsRef.tex_for_tier(str(inst.get("tier", "normal")), false)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var lab: = Label.new()
	var nm: = str(inst.get("name", "法宝"))
	lab.text = ("[穿] " if equipped else "") + nm
	lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lab.add_theme_font_size_override("font_size", 16)
	row.add_child(lab)
	var look: = Button.new()
	look.text = "详情"
	look.custom_minimum_size = Vector2(72, 44)
	var cap: = inst.duplicate(true)
	TouchScrollUtils.bind_tap(look, func():
		show_detail(cap, equipped)
	)
	row.add_child(look)
	if not equipped:
		var eq: = Button.new()
		eq.text = "装备"
		eq.custom_minimum_size = Vector2(72, 44)
		var fid: = str(inst.get("id", ""))
		TouchScrollUtils.bind_tap(eq, func():
			FabaoApiRef.equip(fid)
		)
		row.add_child(eq)
	return row


static func show_detail(inst: Dictionary, equipped: bool, location: String = "") -> void :
	var loc: = location.strip_edges()
	if loc.is_empty():
		loc = "equipped" if equipped else "bag"
	var gm = GameManager.instance
	if gm == null or not gm.has_method("_find_main_ui_node"):
		return
	var ui = gm._find_main_ui_node()
	if ui and ui.has_method("_show_fabao_action_popup"):
		ui._show_fabao_action_popup(inst, loc)


static func affix_group_name(g: String) -> String:
	var names: = {
		"player_atk": "人物攻击", 
		"pet_atk": "出战宠物攻击", 
		"player_def": "人物防御", 
		"pet_def": "出战宠物防御", 
		"player_agi": "人物敏捷", 
		"pet_agi": "出战宠物敏捷", 
		"player_hp": "人物生命", 
		"pet_hp": "出战宠物生命", 
		"player_crit_rate": "人物暴击率", 
		"pet_crit_rate": "出战宠物暴击率", 
		"player_crit_dmg": "人物暴击伤害", 
		"pet_crit_dmg": "出战宠物暴击伤害", 
		"evolve_mutate": "进化变异几率", 
		"player_element": "人物五行", 
		"armor_pierce_rate": "出战宠物破甲几率", 
	}
	return str(names.get(g, g))


static func affix_cap_text(tier_id: String, group: String) -> String:
	if group == "evolve_mutate":
		return "1"
	if group == "armor_pierce_rate":
		return str(FabaoConfigRef.SPECIAL_ARMOR_PIERCE_CAP)
	if group == "player_element":
		return "-"
	if group == "player_crit_rate" or group == "pet_crit_rate":
		return str(FabaoConfigRef.crit_rate_cap(tier_id))
	return str(FabaoConfigRef.combat_cap(tier_id))


static func is_rare_group(g: String) -> bool:
	return g == "evolve_mutate" or g == "player_element" or g == "armor_pierce_rate"


static func element_color(el: String) -> Color:
	match el:
		"金":
			return Color(1.0, 0.84, 0.2)
		"木":
			return Color(0.35, 0.85, 0.4)
		"水":
			return Color(0.35, 0.65, 1.0)
		"火":
			return Color(1.0, 0.38, 0.28)
		"土":
			return Color(0.78, 0.55, 0.28)
		_:
			return Color(0.7, 0.75, 0.95)


static func sorted_affixes(inst: Dictionary) -> Array:
	var common: Array = []
	var rare: Array = []
	for aff in inst.get("affixes", []):
		if not (aff is Dictionary):
			continue
		if is_rare_group(str(aff.get("group", ""))):
			rare.append(aff)
		else:
			common.append(aff)
	return common + rare


static func _affix_text(aff: Dictionary) -> String:
	var g: = str(aff.get("group", ""))
	var label: = affix_group_name(g)
	if g == "evolve_mutate":
		return "%s +1%%" % label
	if g == "player_element":
		return "%s变为%s" % [label, str(aff.get("element", ""))]
	return "%s +%d%%" % [label, int(aff.get("value", 0))]
