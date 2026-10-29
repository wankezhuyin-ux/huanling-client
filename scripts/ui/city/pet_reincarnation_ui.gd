extends RefCounted
class_name PetReincarnationUI

const PetReincarnationClass = preload("res://scripts/pet_reincarnation.gd")
const UIStyle = preload("res://scripts/ui_style.gd")
const WindowHost = preload("res://scripts/ui/window_host.gd")
const TouchScrollUtils = preload("res://scripts/ui/touch_scroll_utils.gd")
const PetIdleDisplay = preload("res://scripts/ui/pet_idle_display.gd")


const LIST_AVATAR_SIZE: = Vector2(64, 64)
const INHERIT_AVATAR_SIZE: = Vector2(48, 48)

static func _make_static_pet_avatar(pet_id: String, display_size: Vector2) -> Control:
	var tex: Texture2D = null
	var am = AssetManager.get_instance()
	if am:
		tex = am.get_pet_texture(str(pet_id))
	var avatar: = PetIdleDisplay.create_static_image(display_size, str(pet_id), tex)
	if avatar:
		avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		avatar.custom_minimum_size = display_size
		avatar.size = display_size
		avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return avatar

static func _attach_popup_window(dialog: Window, parent_control: Control) -> void :
	if parent_control != null and is_instance_valid(parent_control) and parent_control.is_inside_tree():
		WindowHost.attach_window_and_popup_centered(dialog, parent_control)
		return
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null:
		WindowHost.attach_window_to_scene_root(dialog, tree)
		return
	push_warning("[PetReincarnationUI] 无法显示弹窗：无可用挂载点")
	dialog.queue_free()

static func build_reincarnation_view_fullscreen(panel: Control):
	if not is_instance_valid(panel):
		return
	var content_container: = panel.get_meta("content_container") as VBoxContainer
	var game_manager: Object = panel.get_meta("game_manager")
	if not content_container or not game_manager:
		return
	for child in content_container.get_children():
		child.queue_free()

	var desc: = Label.new()
	desc.text = "三代及以上满级宠物，满足成长要求（可进化终极≥80、不可进化≥60）后，消耗对应五行转生令牌（天系宠可手动选用任意五行令牌）。每转生1次属性加成+1%，每满10次等级上限+50/100，单只上限50次。转生后等级保持不变（每满10次上限突破时等级+1），保留技能、勋章、代数、形态、血统。"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 18)
	desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_container.add_child(desc)

	var pm: PetManager = game_manager.pet_manager
	var all_pets: Array = pm.pets

	var eligible_pets: Array = []
	for pet in all_pets:
		if PetReincarnationClass.can_reincarnate(pet, pm).ok:
			eligible_pets.append(pet)

	if eligible_pets.is_empty():
		var empty_label: = Label.new()
		empty_label.text = "当前没有满足转生条件的宠物\n（需要3代满级、成长达标、非出战/锁定/宠物袋中）"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 20)
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content_container.add_child(empty_label)
		return

	eligible_pets.sort_custom( func(a, b): return a.reincarnation_count > b.reincarnation_count)

	var scroll: = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_container.add_child(scroll)
	TouchScrollUtils.configure_scroll(scroll)

	var list_vbox: = VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(list_vbox)

	for pet in eligible_pets:
		var card: = _build_pet_card(pet, game_manager, panel, false)
		list_vbox.add_child(card)
	TouchScrollUtils.enable_touch_drag_passthrough(list_vbox)

static func build_inheritance_view_fullscreen(panel: Control):
	if not is_instance_valid(panel):
		return
	var content_container: = panel.get_meta("content_container") as VBoxContainer
	var game_manager: Object = panel.get_meta("game_manager")
	if not content_container or not game_manager:
		return
	for child in content_container.get_children():
		child.queue_free()

	var cost_label: = Label.new()
	cost_label.text = "消耗：1000 元宝"
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 20)
	cost_label.add_theme_color_override("font_color", Color(0.5, 0.9, 1))
	content_container.add_child(cost_label)

	var inherit_rule: = Label.new()
	inherit_rule.text = "规则：源宠转生次数≥2且为偶数，目标宠转生次数=0。两只宠物需五行属性相同（天系可与任意五行互通）、进化类型一致。继承后目标获得源的一半转生次数（源清零），消耗1000元宝。"
	inherit_rule.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inherit_rule.add_theme_font_size_override("font_size", 17)
	inherit_rule.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	inherit_rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_container.add_child(inherit_rule)

	var pm = game_manager.pet_manager
	var normal_pets = pm.get_normal_pets()

	var source_pets: Array = []
	var target_pets: Array = []
	for pet in normal_pets:
		if pet.reincarnation_count >= 2 and pet.reincarnation_count % 2 == 0:
			source_pets.append(pet)
		if pet.reincarnation_count == 0 and PetReincarnationClass.can_reincarnate(pet, pm).ok:
			target_pets.append(pet)
	panel.set_meta("inherit_all_source", source_pets)
	panel.set_meta("inherit_all_target", target_pets)

	var panel_state: = {"source": null, "target": null}
	panel.set_meta("inherit_state", panel_state)

	var hbox: = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 10)
	content_container.add_child(hbox)


	var source_box: = _build_selection_panel("转生次数来源（≥2偶数）", source_pets, panel_state, "source", panel, game_manager)
	hbox.add_child(source_box)


	var target_box: = _build_selection_panel("接收转生次数（0转生）", target_pets, panel_state, "target", panel, game_manager)
	hbox.add_child(target_box)


	var preview_vbox: = VBoxContainer.new()
	preview_vbox.add_theme_constant_override("separation", 8)
	content_container.add_child(preview_vbox)

	var preview_label: = Label.new()
	preview_label.name = "inherit_preview"
	preview_label.text = "请选择源宠物和目标宠物"
	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_label.add_theme_font_size_override("font_size", 20)
	preview_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_vbox.add_child(preview_label)

	var inherit_btn: = Button.new()
	inherit_btn.text = "⚠ 确认继承（消耗1000元宝）"
	inherit_btn.custom_minimum_size = Vector2(280, 50)
	inherit_btn.add_theme_font_size_override("font_size", 21)
	UIStyle.apply_action_button_style(inherit_btn)
	inherit_btn.disabled = true
	inherit_btn.name = "inherit_btn"
	inherit_btn.pressed.connect( func():
		_on_inherit_pressed(panel, game_manager)
	)
	preview_vbox.add_child(inherit_btn)
	panel.set_meta("inherit_preview_label", preview_label)
	panel.set_meta("inherit_confirm_btn", inherit_btn)

static func _build_selection_panel(title_text: String, pets: Array, state: Dictionary, key: String, panel: Control, game_manager) -> Control:
	var vbox: = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var label: = Label.new()
	label.text = title_text
	label.add_theme_font_size_override("font_size", 19)
	label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	vbox.add_child(label)

	if pets.is_empty():
		var empty: = Label.new()
		empty.text = "无符合条件的宠物"
		empty.add_theme_font_size_override("font_size", 18)
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		vbox.add_child(empty)
		return vbox

	var scroll: = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	TouchScrollUtils.configure_scroll(scroll)

	var list: = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)

	for pet in pets:
		var btn: = Button.new()
		var display_name: String = pet.pet_name
		if pet.reincarnation_count > 0:
			display_name += "(%d)" % pet.reincarnation_count
		btn.text = "%s · %s · Lv%d · 成长%.1f" % [display_name, pet.element, pet.level, pet.total_growth]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 56)
		btn.add_theme_font_size_override("font_size", 18)
		UIStyle.apply_button_style(btn)
		var am = AssetManager.get_instance()
		if am:
			var tex: Texture2D = am.get_pet_texture(str(pet.pet_id))
			if tex:
				btn.icon = tex
				btn.expand_icon = true
				btn.add_theme_constant_override("icon_max_width", int(INHERIT_AVATAR_SIZE.x))

		var _sel = state.get(key)
		if _sel and _sel.id == pet.id:
			var sel_s: = StyleBoxFlat.new()
			sel_s.bg_color = Color(0.12, 0.55, 0.25)
			sel_s.set_corner_radius_all(6)
			btn.add_theme_stylebox_override("normal", sel_s)
		var _p = pet

		TouchScrollUtils.bind_tap(btn, func():
			state[key] = _p
			for child in list.get_children():
				if child is Button:
					UIStyle.apply_button_style(child)
			var sel_style: = StyleBoxFlat.new()
			sel_style.bg_color = Color(0.12, 0.55, 0.25)
			sel_style.set_corner_radius_all(6)
			btn.add_theme_stylebox_override("normal", sel_style)
			btn.add_theme_stylebox_override("hover", sel_style)
			_rebuild_other_inherit_panel(panel, game_manager, key)
			_update_inherit_preview(panel, game_manager)
		)
		list.add_child(btn)
	return vbox

static func _rebuild_other_inherit_panel(panel: Control, game_manager, selected_key: String):
	var state = panel.get_meta("inherit_state")
	if not state:
		return
	var selected = state.get(selected_key)
	if not selected:
		return
	var other_key: = "target" if selected_key == "source" else "source"
	var all_other: Array
	if selected_key == "source":
		all_other = panel.get_meta("inherit_all_target")
	else:
		all_other = panel.get_meta("inherit_all_source")
	var filtered: Array = []
	for pet in all_other:
		if PetReincarnationClass.elements_compatible_for_inherit(selected, pet) and pet.is_evolution_pet == selected.is_evolution_pet:
			filtered.append(pet)
	var content_container = panel.get_meta("content_container") as VBoxContainer
	if not content_container:
		return
	var hbox: HBoxContainer = null
	for child in content_container.get_children():
		if child is HBoxContainer:
			hbox = child
			break
	if not hbox:
		return
	var target_idx: = 1 if selected_key == "source" else 0
	var other_title: = "接收转生次数（0转生）" if other_key == "target" else "转生次数来源（≥2偶数）"
	if target_idx < hbox.get_child_count():
		var old_panel = hbox.get_child(target_idx)
		old_panel.queue_free()
		var new_panel: = _build_selection_panel(other_title, filtered, state, other_key, panel, game_manager)
		hbox.add_child(new_panel)
		hbox.move_child(new_panel, target_idx)

static func _update_inherit_preview(panel: Control, game_manager):
	var state = panel.get_meta("inherit_state")
	if not state:
		return
	var source = state.get("source")
	var target = state.get("target")
	var preview_label: Label = null
	var inherit_btn: Button = null
	preview_label = panel.get_meta("inherit_preview_label") as Label
	inherit_btn = panel.get_meta("inherit_confirm_btn") as Button

	if not source or not target:
		if preview_label:
			preview_label.text = "请选择源宠物和目标宠物"
		if inherit_btn:
			inherit_btn.disabled = true
		return

	var check = PetReincarnationClass.can_inherit(source, target, game_manager.pet_manager)
	if not check.ok:
		if preview_label:
			preview_label.text = check.reason
			preview_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
		if inherit_btn:
			inherit_btn.disabled = true
		return

	var inherited = PetReincarnationClass.get_inherited_count(source.reincarnation_count)
	if preview_label:
		var src_name: String = source.pet_name
		var tgt_name: String = target.pet_name
		preview_label.text = "%s（转生%d→0） → %s（转生0→%d）" % [src_name, source.reincarnation_count, tgt_name, inherited]
		preview_label.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
	if inherit_btn:
		inherit_btn.disabled = false

static func _on_inherit_pressed(panel: Control, game_manager):
	var state = panel.get_meta("inherit_state")
	if not state:
		return
	var source = state.get("source")
	var target = state.get("target")
	if not source or not target:
		return

	if game_manager.player.yuanbao_currency < 1000:
		_show_alert(panel, "元宝不足，需要1000元宝")
		return

	if not game_manager.network or not game_manager.network.is_logged_in():
		_show_alert(panel, "该操作需联网使用，请登录后重试")
		return

	var op_id: = "inherit_%d_%s" % [Time.get_unix_time_from_system(), str(randi())]
	game_manager.network.pet_reincarnation_inherit_success.connect( func(data: Dictionary):
		game_manager.apply_cloud_save(data.get("saveData", {}), {
			"preserve_local_pets_not_in_cloud": true, 
			"pets_authoritative": true, 
			"skip_pet_progress_merge": true, 
		})
		game_manager.save_game()
		var ok_msg: = str(data.get("message", "")).strip_edges()
		if ok_msg.is_empty():
			ok_msg = "继承成功！" if not bool(data.get("duplicate_resync", false)) else "操作已完成，已同步云端"
		_show_alert(panel, ok_msg)
		build_inheritance_view_fullscreen(panel), CONNECT_ONE_SHOT)
	game_manager.network.pet_reincarnation_inherit_failed.connect( func(err: String):
		_show_alert(panel, err), CONNECT_ONE_SHOT)
	game_manager.network.pet_reincarnate_inherit(source.id, target.id, op_id)

static func _build_pet_card(pet, game_manager, panel: Control, _is_selection: bool) -> Control:
	var card: = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style: = UIStyle.create_item_style()
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", style)

	var hbox: = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 10)
	card.add_child(hbox)

	var avatar: = _make_static_pet_avatar(str(pet.pet_id), LIST_AVATAR_SIZE)
	if avatar:
		hbox.add_child(avatar)


	var mid: = Control.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mid.custom_minimum_size = Vector2(0, 108)
	mid.clip_contents = true
	hbox.add_child(mid)

	var info_vbox: = VBoxContainer.new()
	info_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	info_vbox.add_theme_constant_override("separation", 2)
	mid.add_child(info_vbox)

	var display_name: String = pet.pet_name
	if pet.reincarnation_count > 0:
		display_name += "(%d)" % pet.reincarnation_count
	var name_label: = Label.new()
	name_label.text = "%s · %s · Lv%d/%d" % [display_name, pet.element, pet.level, pet.get_effective_max_level()]
	name_label.add_theme_font_size_override("font_size", 19)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var elem_color: = Color.WHITE
	match pet.element:
		"金": elem_color = Color(1, 0.84, 0)
		"木": elem_color = Color(0.13, 0.55, 0.13)
		"水": elem_color = Color(0, 0.75, 1)
		"火": elem_color = Color(1, 0.27, 0)
		"土": elem_color = Color(0.55, 0.27, 0.07)
		"天": elem_color = Color(0.45, 0.85, 1.0)
	name_label.add_theme_color_override("font_color", elem_color)
	info_vbox.add_child(name_label)

	var detail_label: = Label.new()
	detail_label.text = "成长%.3f · %s代 · %s · 转生%d/50 · 加成+%d%%" % [pet.total_growth, pet.generation, pet.form, pet.reincarnation_count, int(pet.get_reincarnation_bonus() * 100)]
	detail_label.add_theme_font_size_override("font_size", 17)
	detail_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_child(detail_label)

	var cost = PetReincarnationClass.get_cost(pet.reincarnation_count)
	var inv = game_manager.inventory_manager
	var cost_label: = Label.new()
	var tokens_ok: = false
	if PetReincarnationClass.is_sky_element(pet):
		var max_have: = 0
		if inv:
			for el in PetReincarnationClass.TOKEN_ELEMENTS:
				max_have = maxi(max_have, inv.get_item_count(PetReincarnationClass.get_token_name_for_element(el)))
		tokens_ok = max_have >= cost.tokens
		cost_label.text = "消耗: 任意五行令牌 x%d（点转生后选择）\n拥有最多%d · 金币 %d亿" % [cost.tokens, max_have, cost.gold / 100000000]
	else:
		var token_name = PetReincarnationClass.get_token_name(pet)
		var token_count: int = 0 if not inv else inv.get_item_count(token_name)
		tokens_ok = token_count >= cost.tokens
		cost_label.text = "消耗: %s x%d (拥有%d)\n金币 %d亿" % [token_name, cost.tokens, token_count, cost.gold / 100000000]
	cost_label.add_theme_font_size_override("font_size", 17)
	cost_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cost_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if tokens_ok and game_manager.player.gold >= cost.gold:
		cost_label.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
	else:
		cost_label.add_theme_color_override("font_color", Color(0.9, 0.5, 0.3))
	info_vbox.add_child(cost_label)

	var reinc_btn: = Button.new()
	reinc_btn.text = "⚡ 转生"
	reinc_btn.custom_minimum_size = Vector2(100, 38)
	reinc_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	reinc_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	reinc_btn.add_theme_font_size_override("font_size", 19)
	UIStyle.apply_action_button_style(reinc_btn)
	var pet_id: = str(pet.id)
	reinc_btn.pressed.connect( func():
		var live_pet = null
		if game_manager and game_manager.pet_manager:
			live_pet = game_manager.pet_manager.get_pet_by_stable_id(pet_id)
		_on_reincarnate_pressed(live_pet, game_manager, panel)
	)
	hbox.add_child(reinc_btn)

	return card

static func _resolve_pet_for_reincarnation(pet, game_manager) -> Pet:
	if pet != null and is_instance_valid(pet):
		return pet as Pet
	if game_manager == null or game_manager.pet_manager == null:
		return null
	var pet_id: = str(pet.id) if pet != null else ""
	if pet_id.is_empty():
		return null
	return game_manager.pet_manager.get_pet_by_stable_id(pet_id)

static func _on_reincarnate_pressed(pet, game_manager, panel: Control):
	pet = _resolve_pet_for_reincarnation(pet, game_manager)
	if pet == null:
		_show_alert(panel, "宠物数据已刷新，请关闭界面后重新打开再试")
		build_reincarnation_view_fullscreen(panel)
		return
	var cost = PetReincarnationClass.get_cost(pet.reincarnation_count)

	if game_manager.player.gold < cost.gold:
		_show_alert(panel, "金币不足，需要%d亿" % (cost.gold / 100000000))
		return
	if not game_manager.network or not game_manager.network.is_logged_in():
		_show_alert(panel, "该操作需联网使用，请登录后重试")
		return


	if PetReincarnationClass.is_sky_element(pet):
		_show_sky_token_picker(pet, game_manager, panel, cost)
		return

	var token_name = PetReincarnationClass.get_token_name(pet)
	if not game_manager.inventory_manager or game_manager.inventory_manager.get_item_count(token_name) < cost.tokens:
		_show_alert(panel, "%s不足，需要%d个" % [token_name, cost.tokens])
		return
	_confirm_and_request_reincarnate(pet, game_manager, panel, str(pet.element), token_name, cost)

static func _show_sky_token_picker(pet, game_manager, panel: Control, cost: Dictionary) -> void :
	var dialog: = Window.new()
	dialog.title = ""
	dialog.size = Vector2i(480, 420)
	dialog.transparent = true
	dialog.borderless = true
	dialog.unresizable = true
	dialog.close_requested.connect( func(): dialog.queue_free())

	var popup: = Panel.new()
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.add_theme_stylebox_override("panel", UIStyle.create_panel_style())
	dialog.add_child(popup)

	var vbox: = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_top = 16
	vbox.offset_right = -20
	vbox.offset_bottom = -16
	vbox.add_theme_constant_override("separation", 10)
	popup.add_child(vbox)

	var title: = Label.new()
	title.text = "天系转生：选择令牌"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.45, 0.85, 1.0))
	vbox.add_child(title)

	var hint: = Label.new()
	hint.text = "【%s】本次需要令牌 x%d，请选择消耗哪一种五行令牌" % [pet.pet_name, cost.tokens]
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 17)
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(hint)

	var inv = game_manager.inventory_manager
	var any_ok: = false
	for el in PetReincarnationClass.TOKEN_ELEMENTS:
		var token_name: String = PetReincarnationClass.get_token_name_for_element(el)
		var have: int = 0 if not inv else inv.get_item_count(token_name)
		var enough: bool = have >= cost.tokens
		if enough:
			any_ok = true
		var btn: = Button.new()
		btn.text = "%s  （拥有 %d / 需要 %d）" % [token_name, have, cost.tokens]
		btn.custom_minimum_size = Vector2(0, 42)
		btn.add_theme_font_size_override("font_size", 18)
		btn.disabled = not enough
		if enough:
			UIStyle.apply_action_button_style(btn)
		else:
			UIStyle.apply_button_style(btn)
		var chosen_el: = str(el)
		var chosen_name: = token_name
		btn.pressed.connect( func():
			dialog.queue_free()
			_confirm_and_request_reincarnate(pet, game_manager, panel, chosen_el, chosen_name, cost)
		)
		vbox.add_child(btn)

	if not any_ok:
		var warn: = Label.new()
		warn.text = "五种五行令牌均不足，无法转生"
		warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		warn.add_theme_font_size_override("font_size", 17)
		warn.add_theme_color_override("font_color", Color(0.9, 0.4, 0.3))
		vbox.add_child(warn)

	var cancel_btn: = Button.new()
	cancel_btn.text = "取消"
	cancel_btn.custom_minimum_size = Vector2(120, 40)
	cancel_btn.add_theme_font_size_override("font_size", 20)
	UIStyle.apply_button_style(cancel_btn)
	cancel_btn.pressed.connect( func(): dialog.queue_free())
	vbox.add_child(cancel_btn)

	_attach_popup_window(dialog, panel)

static func _confirm_and_request_reincarnate(pet, game_manager, panel: Control, token_element: String, token_name: String, cost: Dictionary) -> void :
	var new_rei: int = pet.reincarnation_count + 1
	var new_bonus: int = new_rei
	var eff_max: int = pet.get_effective_max_level()
	var new_bracket: int = new_rei / 10
	var new_eff_max: int = pet.max_level + new_bracket * (50 if pet.is_evolution_pet else 100)

	var confirm_msg: = "【%s】将进行第 %d 次转生\n\n" % [pet.pet_name, new_rei]
	confirm_msg += "消耗：%s x%d · %d亿金币\n\n" % [token_name, cost.tokens, cost.gold / 100000000]
	confirm_msg += "⚠ 转生后：\n"
	confirm_msg += "· 等级上限突破时等级 +1，其余保持不变\n"
	confirm_msg += "· 属性加成 +%d%% → +%d%%\n" % [pet.reincarnation_count, new_rei]
	if new_eff_max != eff_max:
		confirm_msg += "· 等级上限 %d → %d\n" % [eff_max, new_eff_max]
	confirm_msg += "· 技能、勋章、代数、形态保留\n"

	_show_confirm_popup(panel, "⚠ 宠物转生确认", confirm_msg, func():
		var op_id: = "reinc_%d_%s" % [Time.get_unix_time_from_system(), str(randi())]
		game_manager.network.pet_reincarnation_success.connect( func(data: Dictionary):
			game_manager.apply_cloud_save(data.get("saveData", {}), {
				"preserve_local_pets_not_in_cloud": true, 
				"pets_authoritative": true, 
				"skip_pet_progress_merge": true, 
			})
			game_manager.save_game()
			if not bool(data.get("duplicate_resync", false)):
				game_manager.broadcast_event("pet_reincarnation", game_manager.player.player_name, {
					"pet_name": pet.pet_name, 
					"reincarnation_count": new_rei, 
					"bonus_pct": new_bonus, 
					"effective_max_level": new_eff_max
				})
			var ok_msg: = ""
			if bool(data.get("duplicate_resync", false)):
				ok_msg = str(data.get("message", "")).strip_edges()
				if ok_msg.is_empty():
					ok_msg = "操作已完成，已同步云端"
			else:
				var rei_after: = new_rei
				var result_var: Variant = data.get("result", {})
				if result_var is Dictionary and result_var.has("reincarnationCount"):
					rei_after = int(result_var.get("reincarnationCount", new_rei))
				ok_msg = "转生成功！转生次数+%d" % rei_after
			_show_alert(panel, ok_msg)
			build_reincarnation_view_fullscreen(panel)
		, CONNECT_ONE_SHOT)
		game_manager.network.pet_reincarnation_failed.connect( func(err: String):
			_show_alert(panel, err)
		, CONNECT_ONE_SHOT)
		game_manager.track_event("pet_reincarnate", {"petId": pet.id, "petName": pet.pet_name, "tokenElement": token_element})
		game_manager.network.pet_reincarnate(pet.id, token_element, op_id)
	)

static func _show_confirm_popup(_parent: Control, title_text: String, message: String, on_confirm: Callable):
	var dialog: = Window.new()
	dialog.title = ""

	dialog.size = Vector2i(520, 520)
	dialog.transparent = true
	dialog.borderless = true
	dialog.unresizable = true
	dialog.close_requested.connect( func(): dialog.queue_free())

	var popup: = Panel.new()
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.add_theme_stylebox_override("panel", UIStyle.create_panel_style())
	dialog.add_child(popup)

	var vbox: = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 12)
	popup.add_child(vbox)

	var title: = Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.9, 0.6, 0.2))
	title.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	vbox.add_child(title)


	var scroll: = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var content: = Label.new()
	content.text = message
	content.add_theme_font_size_override("font_size", 20)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll.add_child(content)

	var btn_hbox: = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	btn_hbox.size_flags_vertical = Control.SIZE_SHRINK_END
	btn_hbox.custom_minimum_size = Vector2(0, 50)
	vbox.add_child(btn_hbox)

	var confirm_btn: = Button.new()
	confirm_btn.text = "确认"
	confirm_btn.custom_minimum_size = Vector2(120, 45)
	confirm_btn.add_theme_font_size_override("font_size", 21)
	UIStyle.apply_action_button_style(confirm_btn)
	confirm_btn.pressed.connect( func():
		dialog.queue_free()
		on_confirm.call()
	)
	btn_hbox.add_child(confirm_btn)

	var cancel_btn: = Button.new()
	cancel_btn.text = "取消"
	cancel_btn.custom_minimum_size = Vector2(120, 45)
	cancel_btn.add_theme_font_size_override("font_size", 21)
	UIStyle.apply_button_style(cancel_btn)
	cancel_btn.pressed.connect( func():
		dialog.queue_free()
	)
	btn_hbox.add_child(cancel_btn)

	_attach_popup_window(dialog, _parent)

static func _show_alert(_parent: Control, msg: String):
	var dialog: = Window.new()
	dialog.title = ""
	dialog.size = Vector2i(400, 180)
	dialog.transparent = true
	dialog.borderless = true
	dialog.unresizable = true
	dialog.close_requested.connect( func(): dialog.queue_free())

	var popup: = Panel.new()
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.add_theme_stylebox_override("panel", UIStyle.create_panel_style())
	dialog.add_child(popup)

	var vbox: = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 12)
	popup.add_child(vbox)

	var title: = Label.new()
	title.text = "提示"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.3))
	vbox.add_child(title)

	var content: = Label.new()
	content.text = msg
	content.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_theme_font_size_override("font_size", 20)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(content)

	var ok_btn: = Button.new()
	ok_btn.text = "确定"
	ok_btn.custom_minimum_size = Vector2(120, 40)
	ok_btn.add_theme_font_size_override("font_size", 20)
	UIStyle.apply_button_style(ok_btn)
	ok_btn.pressed.connect( func(): dialog.queue_free())
	vbox.add_child(ok_btn)

	_attach_popup_window(dialog, _parent)
