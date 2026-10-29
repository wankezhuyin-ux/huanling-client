extends RefCounted


const _PET_SERVER_RPC_WAIT_MS: int = 60000
## 进化后是否把等级重置为 1（预览页写的就是这条规则）。
## 服务端 /pet/evolve 不做重置，所以由客户端补；想关掉这个规则把它改成 false 即可。
const RESET_LEVEL_ON_EVOLVE: bool = true

static func _finish_pet_merge_guard(game_manager) -> void :
	if game_manager == null:
		return
	if game_manager.has_method("finish_pet_merge_operation"):
		game_manager.finish_pet_merge_operation()
	elif game_manager.has_method("clear_pet_merge_exp_block"):
		game_manager.clear_pet_merge_exp_block()

const GameData = preload("res://scripts/game_data.gd")
const PetDatabase = preload("res://scripts/pet_data_complete.gd")
const EvolutionDataClass = preload("res://scripts/evolution_data.gd")
const PetIdleDisplay = preload("res://scripts/ui/pet_idle_display.gd")
const UIStyle = preload("res://scripts/ui_style.gd")
const WindowHost = preload("res://scripts/ui/window_host.gd")
const PetCollectionUI = preload("res://scripts/ui/city/pet_collection_ui.gd")
const PetReincarnationUI = preload("res://scripts/ui/city/pet_reincarnation_ui.gd")
const TouchScrollUtils = preload("res://scripts/ui/touch_scroll_utils.gd")

const HUB_BG_TEX_PATH: = "res://assets/city/pet_park/pet_park_branch_bg.jpg"
const HUB_BTN_TEX_PATH: = "res://assets/city/pet_park/pet_park_branch_sign.png"


const FEATURE_PREVIEW_MAX: int = 256
const FEATURE_PREVIEW_SIDE: int = 200


const _MERGE_WEIGHTS_BY_TIER: Array = [
	{"A": 5, "B": 15, "C": 30, "D": 50}, 
	{"A": 15, "B": 20, "C": 30, "D": 35}, 
	{"A": 20, "B": 30, "C": 40, "D": 10}, 
	{"A": 30, "B": 60, "C": 10, "D": 0}, 
]


const _EVOLVE_LINEAGE_BASELINE: float = 6.0
const _EVOLVE_LINEAGE_COEFF: float = 0.25

static func _count_inventory_item_by_name(game_manager, item_name: String) -> int:
	if game_manager == null or game_manager.inventory_manager == null:
		return 0
	var target: = str(item_name).strip_edges()
	if target.is_empty():
		return 0
	var total: = 0
	for it in game_manager.inventory_manager.items:
		if it == null:
			continue
		if str(it.name).strip_edges() != target:
			continue
		total += int(it.count)
	return total

static func _create_placeholder_label(text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	return label



static func _add_width_safe_label(parent: Control, text: String, font_size: int, color: Color, min_height: float = 0.0) -> Control:
	var host: = Control.new()
	host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var line_h: float = float(font_size) * 1.4

	var lines: float = maxf(1.0, ceil(float(text.length()) / 18.0))
	var h: float = maxf(min_height if min_height > 0.0 else line_h, lines * line_h)
	host.custom_minimum_size = Vector2(0, h)
	host.clip_contents = true
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(host)
	var label: = Label.new()
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(label)
	return host

static func _clear_pet_park_content(content_container: Control) -> void :
	if content_container == null:
		return

	var kids: Array = content_container.get_children()
	for child in kids:
		content_container.remove_child(child)
		child.queue_free()

static func _create_section_vbox(title: String) -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)

	var title_label = Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	vbox.add_child(title_label)

	var separator = HSeparator.new()
	vbox.add_child(separator)

	return vbox


static func _make_pet_park_section_card(title: String, accent: Color = Color(0.072, 0.080, 0.079, 0.85)) -> PanelContainer:
	var panel: = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style: = StyleBoxFlat.new()
	style.bg_color = Color(0.060, 0.068, 0.069, 0.88)
	style.border_color = accent
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	var body: = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 8)
	panel.add_child(body)
	if not title.strip_edges().is_empty():
		var title_label: = Label.new()
		title_label.text = title
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_label.add_theme_font_size_override("font_size", 21)
		title_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
		body.add_child(title_label)
	panel.set_meta("body", body)
	return panel

static func _pet_park_section_body(card: PanelContainer) -> VBoxContainer:
	if card == null:
		return null
	return card.get_meta("body") as VBoxContainer

static func _get_growth_color(growth: float) -> Color:
	if growth >= 10.0:
		return Color(1.0, 0.6, 0.0)
	elif growth >= 7.0:
		return Color(0.072, 0.080, 0.079)
	elif growth >= 6.0:
		return Color(0.072, 0.080, 0.079)
	elif growth >= 5.0:
		return Color(0.2, 0.8, 0.2)
	else:
		return Color(1, 1, 1)

static func _get_element_color(element: String) -> Color:
	match element:
		"金": return Color(1, 0.84, 0)
		"木": return Color(0.2, 0.8, 0.2)
		"水": return Color(0.072, 0.080, 0.079)
		"火": return Color(1, 0.3, 0.2)
		"土": return Color(0.6, 0.4, 0.2)
		_: return Color(0.7, 0.7, 0.7)

static func _get_species_display_name(pet_id: String) -> String:
	var pid: = str(pet_id).strip_edges()
	if pid.is_empty():
		return "未知"
	var info: Dictionary = PetDatabase.PET_DATA.get(pid, {})
	var nm: = str(info.get("name", "")).strip_edges()
	return nm if not nm.is_empty() else pid

static func _feature_preview_size(_dual: bool = false) -> Vector2:

	var side: int = mini(FEATURE_PREVIEW_SIDE, FEATURE_PREVIEW_MAX)
	return Vector2(side, side)

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
	return avatar

static func _make_idle_pet_avatar(pet_id: String, display_size: Vector2) -> Control:
	var tex: Texture2D = null
	var am = AssetManager.get_instance()
	if am:
		tex = am.get_pet_texture(str(pet_id))
	var avatar: = PetIdleDisplay.create_avatar_widget(str(pet_id), display_size, tex)
	if avatar:
		avatar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_apply_viewport_when_visible(avatar)
	return avatar


static func _mount_feature_preview(parent: Control, pet_id: String, display_size: Vector2) -> Control:
	var slot: = Control.new()
	slot.name = "FeaturePreviewSlot"
	slot.custom_minimum_size = display_size
	slot.size = display_size
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	parent.add_child(slot)
	var static_av: = _make_static_pet_avatar(str(pet_id), display_size)
	if static_av:
		slot.add_child(static_av)
	_deferred_replace_preview_with_idle.call_deferred(slot, str(pet_id), display_size)
	return slot

static func _deferred_replace_preview_with_idle(slot: Control, pet_id: String, display_size: Vector2) -> void :
	if slot == null or not is_instance_valid(slot):
		return
	var idle: = _make_idle_pet_avatar(pet_id, display_size)
	if idle == null:
		return
	var kids: Array = slot.get_children()
	for child in kids:
		slot.remove_child(child)
		child.queue_free()
	slot.add_child(idle)

static func _apply_viewport_when_visible(node: Node) -> void :
	if node == null:
		return
	if node is SubViewport:
		(node as SubViewport).render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	for c in node.get_children():
		_apply_viewport_when_visible(c)


static func _resolve_evolve_preview_targets(pet, pet_manager) -> Dictionary:
	var out: = {
		"next_normal_id": "", 
		"next_mutant_id": "", 
		"can_mutate": false, 
		"next_form": "", 
	}
	if pet == null or pet_manager == null:
		return out
	var can_result: Dictionary = pet_manager.can_evolve(pet)
	out["can_mutate"] = bool(can_result.get("can_mutate", false))
	var origin_id: = ""
	if "evolution_origin" in pet and str(pet.evolution_origin).strip_edges() != "":
		origin_id = str(pet.evolution_origin).strip_edges()
	else:
		origin_id = str(pet.pet_id).strip_edges()
	var mc: = 0
	if "mutation_count" in pet:
		mc = int(pet.mutation_count)
	var is_mutant: = bool(pet.is_mutant) if "is_mutant" in pet else false
	var chain: Array = EvolutionDataClass.get_evolution_chain_by_origin(origin_id, is_mutant, mc)
	var stage: = chain.find(str(pet.pet_id))
	if stage < 0:
		var binding: Dictionary = EvolutionDataClass.find_pet_evolution_binding(str(pet.pet_id))
		if not binding.is_empty():
			origin_id = str(binding.get("origin", origin_id))
			is_mutant = bool(binding.get("is_mutant", is_mutant))
			chain = binding.get("chain", chain) as Array
			stage = int(binding.get("stage", -1))
	var form_idx = pet_manager.EVOLUTION_FORMS.find(pet.form)
	if form_idx >= 0 and form_idx < pet_manager.EVOLUTION_FORMS.size() - 1:
		out["next_form"] = str(pet_manager.EVOLUTION_FORMS[form_idx + 1])
	if bool(out["can_mutate"]):
		var evo_data: Dictionary = EvolutionDataClass.get_evolution_data(origin_id)
		var normal_chain: Array = evo_data.get("normal_evolution", [])
		var mutant_chain: Array = evo_data.get("mutant_evolution", [])
		if normal_chain.size() > 1:
			out["next_normal_id"] = str(normal_chain[1])
		if mutant_chain.size() > 1:
			out["next_mutant_id"] = str(mutant_chain[1])
	elif stage >= 0 and stage + 1 < chain.size():
		out["next_normal_id"] = str(chain[stage + 1])
	return out


static func _get_pet_mutation_count(pet) -> int:
	if pet == null:
		return 0
	if "mutation_count" in pet:
		return clampi(int(pet.mutation_count), 0, 2)
	return 0

static func _get_pet_quality_bracket_text(pet) -> String:
	var mc: = _get_pet_mutation_count(pet)
	if mc > 0:
		return "[变异%d]" % mc
	if pet != null and pet.is_elite:
		return "[极]"
	return "[普]"

static func _get_pet_name_quality_color(pet) -> Color:
	if _get_pet_mutation_count(pet) > 0:
		return Color(0.072, 0.080, 0.079)
	if pet != null and pet.is_elite:
		return Color(1, 0.84, 0)
	return Color(0.9, 0.9, 0.9)

static func _are_enemies(pet1, pet2) -> bool:
	var enemy_pairs = [
		["金", "木"], 
		["木", "金"], 
		["木", "土"], 
		["土", "木"], 
		["土", "水"], 
		["水", "土"], 
		["水", "火"], 
		["火", "水"], 
		["火", "金"], 
		["金", "火"]
	]
	return [pet1.element, pet2.element] in enemy_pairs

static func _make_hub_btn_style(tex: Texture2D, modulate: Color = Color.WHITE) -> StyleBoxTexture:
	var style: = StyleBoxTexture.new()
	style.texture = tex
	style.modulate_color = modulate
	style.texture_margin_left = 0
	style.texture_margin_top = 0
	style.texture_margin_right = 0
	style.texture_margin_bottom = 0
	return style


static func _hub_btn_size_for_texture(tex: Texture2D) -> Vector2:
	var aspect: = 0.85
	if tex != null and tex.get_height() > 0:
		aspect = float(tex.get_width()) / float(tex.get_height())

	var h: = 178.0
	var w: = snappedf(h * aspect, 1.0)
	w = clampf(w, 128.0, 198.0)
	h = snappedf(w / maxf(aspect, 0.2), 1.0)
	h = clampf(h, 155.0, 210.0)
	return Vector2(w, h)

static func _make_hub_entry_button(btn_name: String, text: String) -> Button:
	var btn: = Button.new()
	btn.name = btn_name
	btn.text = text
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", Color(1.0, 0.96, 0.82, 1))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.98, 0.9, 1))
	btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.9, 0.7, 1))
	btn.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.02, 0.95))
	btn.add_theme_constant_override("outline_size", 4)
	btn.clip_text = false

	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	var tex: Texture2D = load(HUB_BTN_TEX_PATH) as Texture2D
	if tex != null:
		var btn_size: = _hub_btn_size_for_texture(tex)
		btn.custom_minimum_size = btn_size
		btn.size = btn_size
		btn.pivot_offset = btn_size * 0.5
		var normal: = _make_hub_btn_style(tex)
		var hover: = _make_hub_btn_style(tex, Color(0.072, 0.080, 0.079, 1))
		var pressed: = _make_hub_btn_style(tex, Color(0.072, 0.080, 0.079, 1))
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", pressed)
		btn.add_theme_stylebox_override("focus", normal)
		btn.add_theme_stylebox_override("disabled", pressed)
	else:
		push_warning("[PetPark] 挂牌按钮图加载失败: %s" % HUB_BTN_TEX_PATH)
		btn.custom_minimum_size = Vector2(160, 185)
		btn.pivot_offset = Vector2(80, 92)
		UIStyle.apply_button_style(btn)
	return btn


static func _place_hanging_sign(parent: Control, btn: Button, nx: float, ny: float, rot_deg: float = 0.0) -> void :
	if parent == null or btn == null:
		return
	parent.add_child(btn)
	btn.anchor_left = nx
	btn.anchor_top = ny
	btn.anchor_right = nx
	btn.anchor_bottom = ny
	var sz: Vector2 = btn.custom_minimum_size
	if sz.x <= 0.0 or sz.y <= 0.0:
		sz = Vector2(140, 160)
	btn.offset_left = - sz.x * 0.5
	btn.offset_right = sz.x * 0.5
	btn.offset_top = - sz.y * 0.5
	btn.offset_bottom = sz.y * 0.5
	btn.rotation_degrees = rot_deg
	btn.pivot_offset = sz * 0.5

static func _show_pet_park_hub(panel: Control) -> void :
	if panel == null or not is_instance_valid(panel):
		return
	var hub_layer = panel.get_meta("hub_layer") as Control
	var feature_layer = panel.get_meta("feature_layer") as Control
	var content_container = panel.get_meta("content_container") as Control
	var root_title = panel.get_meta("root_title") as Label
	panel.set_meta("evolve_confirm_pet_id", "")
	panel.set_meta("current_tab", "hub")
	panel.set_meta("current_view", "hub")
	if root_title:
		root_title.text = "宠物园"
	if content_container:
		_clear_pet_park_content(content_container)
	if feature_layer:
		feature_layer.visible = false
	if hub_layer:
		hub_layer.visible = true

static func _open_pet_park_feature(panel: Control, tab_key: String, title_text: String) -> void :
	if panel == null or not is_instance_valid(panel):
		return
	var hub_layer = panel.get_meta("hub_layer") as Control
	var feature_layer = panel.get_meta("feature_layer") as Control
	var root_title = panel.get_meta("root_title") as Label
	if hub_layer:
		hub_layer.visible = false
	if feature_layer:
		feature_layer.visible = true
	if root_title:
		root_title.text = title_text
	panel.set_meta("current_tab", tab_key)
	panel.set_meta("current_view", tab_key)
	match tab_key:
		"evolve":
			_build_evolve_view_fullscreen(panel)
		"fusion":
			_build_fusion_view_fullscreen(panel)
		"reincarnate":
			PetReincarnationUI.build_reincarnation_view_fullscreen(panel)
		"inherit":
			PetReincarnationUI.build_inheritance_view_fullscreen(panel)
		"collection":
			_build_collection_view_fullscreen(panel)
		_:
			pass

static func create_fullscreen(game_manager) -> Control:
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.clip_contents = true
	panel.add_theme_stylebox_override("panel", UIStyle.create_panel_style())

	var vbox = UIStyle.create_base_vbox()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(vbox)

	var title = UIStyle.create_title_label("宠物园")
	title.name = "PetParkRootTitle"
	vbox.add_child(title)


	var hub_layer = Control.new()
	hub_layer.name = "HubLayer"
	hub_layer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hub_layer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hub_layer.clip_contents = true
	vbox.add_child(hub_layer)

	var tree_bg: = TextureRect.new()
	tree_bg.name = "PetParkTreeBg"
	tree_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	tree_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tree_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tree_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var bg_tex: Texture2D = load(HUB_BG_TEX_PATH) as Texture2D
	if bg_tex != null:
		tree_bg.texture = bg_tex
	else:
		push_warning("[PetPark] 大树背景加载失败: %s" % HUB_BG_TEX_PATH)
	hub_layer.add_child(tree_bg)

	var hub_hint = Label.new()
	hub_hint.text = "点击树枝上的牌子进入功能"
	hub_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hub_hint.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hub_hint.offset_top = 6
	hub_hint.offset_bottom = 34
	hub_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hub_hint.add_theme_font_size_override("font_size", 18)
	hub_hint.add_theme_color_override("font_color", Color(0.95, 0.9, 0.75))
	hub_hint.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.02, 0.9))
	hub_hint.add_theme_constant_override("outline_size", 3)
	hub_layer.add_child(hub_hint)


	var evolve_btn = _make_hub_entry_button("hub_btn_evolve", "宠物\n进化")
	var fusion_btn = _make_hub_entry_button("hub_btn_fusion", "宠物\n幻化")
	var reincarnate_btn = _make_hub_entry_button("hub_btn_reincarnate", "宠物\n转生")
	var inherit_btn = _make_hub_entry_button("hub_btn_inherit", "转生\n继承")
	var collection_btn = _make_hub_entry_button("hub_btn_collection", "宠物\n图鉴")
	_place_hanging_sign(hub_layer, evolve_btn, 0.12, 0.46, -4.0)
	_place_hanging_sign(hub_layer, fusion_btn, 0.31, 0.49, 3.0)
	_place_hanging_sign(hub_layer, reincarnate_btn, 0.5, 0.45, -2.0)
	_place_hanging_sign(hub_layer, inherit_btn, 0.69, 0.5, 4.0)
	_place_hanging_sign(hub_layer, collection_btn, 0.88, 0.47, -3.0)


	var feature_layer = VBoxContainer.new()
	feature_layer.name = "FeatureLayer"
	feature_layer.visible = false
	feature_layer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feature_layer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	feature_layer.add_theme_constant_override("separation", 8)
	vbox.add_child(feature_layer)


	var feature_header = HBoxContainer.new()
	feature_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feature_header.add_theme_constant_override("separation", 10)
	feature_layer.add_child(feature_header)

	var back_btn = Button.new()
	back_btn.name = "HubBackBtn"
	back_btn.text = "返回大厅"
	back_btn.custom_minimum_size = Vector2(110, 40)
	back_btn.add_theme_font_size_override("font_size", 20)
	UIStyle.apply_button_style(back_btn)
	feature_header.add_child(back_btn)

	var content_container = VBoxContainer.new()
	content_container.name = "FeatureContent"
	content_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_container.clip_contents = true
	content_container.add_theme_constant_override("separation", 8)
	feature_layer.add_child(content_container)

	panel.set_meta("game_manager", game_manager)
	panel.set_meta("root_title", title)
	panel.set_meta("hub_layer", hub_layer)
	panel.set_meta("feature_layer", feature_layer)
	panel.set_meta("content_container", content_container)
	panel.set_meta("current_tab", "hub")
	panel.set_meta("current_view", "hub")
	panel.set_meta("evolve_search_text", "")
	panel.set_meta("evolve_sort_mode", 2)
	panel.set_meta("fusion_search_text", "")
	panel.set_meta("fusion_sort_mode", 2)
	panel.set_meta("fusion_main_pet", null)
	panel.set_meta("fusion_sub_pet", null)
	panel.set_meta("fusion_inheritance", "growth")
	panel.set_meta("evolve_confirm_pet_id", "")
	panel.set_meta("_evolve_rebuild_queued", false)
	panel.set_meta("_fusion_rebuild_queued", false)

	back_btn.pressed.connect( func():
		_show_pet_park_hub(panel)
	)
	evolve_btn.pressed.connect( func():
		_open_pet_park_feature(panel, "evolve", "宠物进化")
	)
	fusion_btn.pressed.connect( func():
		_open_pet_park_feature(panel, "fusion", "宠物幻化")
	)
	reincarnate_btn.pressed.connect( func():
		_open_pet_park_feature(panel, "reincarnate", "宠物转生")
	)
	inherit_btn.pressed.connect( func():
		_open_pet_park_feature(panel, "inherit", "转生继承")
	)
	collection_btn.pressed.connect( func():
		_open_pet_park_feature(panel, "collection", "宠物图鉴")
	)

	return panel

static func _build_evolve_view_fullscreen(panel: Control):
	var content_container = panel.get_meta("content_container") as VBoxContainer
	var game_manager = panel.get_meta("game_manager")

	if not content_container:
		return

	_clear_pet_park_content(content_container)

	if not game_manager or not game_manager.pet_manager:
		var no_data_label = Label.new()
		no_data_label.text = "无宠物数据"
		no_data_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content_container.add_child(no_data_label)
		return

	var pet_manager = game_manager.pet_manager
	var confirm_id: = ""
	if panel.has_meta("evolve_confirm_pet_id"):
		confirm_id = str(panel.get_meta("evolve_confirm_pet_id")).strip_edges()
	if not confirm_id.is_empty():
		var confirm_pet = pet_manager.get_pet_by_stable_id(confirm_id)
		if confirm_pet != null and bool(pet_manager.can_evolve(confirm_pet).get("can", false)):
			_build_evolve_confirm_view_fullscreen(panel, confirm_pet)
			return
		panel.set_meta("evolve_confirm_pet_id", "")

	_add_width_safe_label(
		content_container, 
		"可进化宠物500级可进化；满级进化成长加成更高。点击「选择」查看下一形态预览。", 
		18, 
		Color(0.9, 0.9, 0.9), 
		40.0
	)
	_add_width_safe_label(
		content_container, 
		"进化形态: 初始 -> 一进 -> 二进 -> 终极", 
		20, 
		Color(0.7, 0.7, 0.7), 
		28.0
	)

	var search_row1 = HBoxContainer.new()
	search_row1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_row1.add_theme_constant_override("separation", 6)
	content_container.add_child(search_row1)

	var search_label = Label.new()
	search_label.text = "搜索"
	search_label.add_theme_font_size_override("font_size", 20)
	search_row1.add_child(search_label)

	var search_edit = LineEdit.new()
	search_edit.placeholder_text = "宠物名称..."
	search_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_edit.custom_minimum_size = Vector2(60, 32)
	search_edit.add_theme_font_size_override("font_size", 20)
	search_edit.text = panel.get_meta("evolve_search_text")
	search_edit.text_changed.connect( func(text):
		panel.set_meta("evolve_search_text", text)
		_refresh_evolve_view_fullscreen(panel)
	)
	search_row1.add_child(search_edit)

	var search_row2 = HBoxContainer.new()
	search_row2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_row2.add_theme_constant_override("separation", 6)
	content_container.add_child(search_row2)

	var sort_label = Label.new()
	sort_label.text = "排序"
	sort_label.add_theme_font_size_override("font_size", 20)
	search_row2.add_child(sort_label)

	var sort_items = ["等级降序", "等级升序", "成长降序", "成长升序", "代数降序", "代数升序"]
	var sort_btn = _create_dropdown_button_fullscreen(panel, sort_items, panel.get_meta("evolve_sort_mode"), func(idx):
		panel.set_meta("evolve_sort_mode", idx)
		_refresh_evolve_view_fullscreen(panel)
	)
	sort_btn.custom_minimum_size = Vector2(100, 32)
	sort_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_row2.add_child(sort_btn)

	var clear_btn = Button.new()
	clear_btn.text = "清除"
	clear_btn.custom_minimum_size = Vector2(64, 32)
	clear_btn.add_theme_font_size_override("font_size", 20)
	clear_btn.pressed.connect( func():
		panel.set_meta("evolve_search_text", "")
		panel.set_meta("evolve_sort_mode", 2)
		_refresh_evolve_view_fullscreen(panel)
	)
	search_row2.add_child(clear_btn)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.clip_contents = true
	content_container.add_child(scroll)
	TouchScrollUtils.configure_scroll(scroll)

	var list_vbox = VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	list_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(list_vbox)

	var evolve_pets = _get_filtered_pets_for_evolve_fullscreen(pet_manager, panel)
	for pet in evolve_pets:
		list_vbox.add_child(_create_evolve_item_ui_fullscreen(panel, pet))

	if evolve_pets.is_empty():
		list_vbox.add_child(_create_placeholder_label("没有可以进化的宠物 (仅限可进化宠物)"))
	TouchScrollUtils.enable_touch_drag_passthrough(list_vbox)

static func _get_filtered_pets_for_evolve_fullscreen(pet_manager, panel: Control) -> Array:
	var pets = []
	var search_text = panel.get_meta("evolve_search_text")
	var sort_mode = panel.get_meta("evolve_sort_mode")

	for i in range(pet_manager.get_pet_count()):
		var pet = pet_manager.get_pet(i)
		if not pet.is_evolution_pet:
			continue
		if search_text != "" and search_text.to_lower() not in pet.pet_name.to_lower():
			continue
		if pet.locked:
			continue
		if pet_manager.active_pet and pet.id == pet_manager.active_pet.id:
			continue
		var can_result = pet_manager.can_evolve(pet)
		if not can_result.can:
			continue
		pets.append(pet)

	match sort_mode:
		0:
			pets.sort_custom( func(a, b): return a.level > b.level)
		1:
			pets.sort_custom( func(a, b): return a.level < b.level)
		2:
			pets.sort_custom( func(a, b): return a.total_growth > b.total_growth)
		3:
			pets.sort_custom( func(a, b): return a.total_growth < b.total_growth)
		4:
			pets.sort_custom( func(a, b): return a.generation > b.generation)
		5:
			pets.sort_custom( func(a, b): return a.generation < b.generation)

	return pets

static func _create_evolve_item_ui_fullscreen(panel: Control, pet) -> Panel:
	var game_manager = panel.get_meta("game_manager")
	var pet_manager = game_manager.pet_manager

	var item_panel = Panel.new()
	item_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_panel.custom_minimum_size = Vector2(0, 108)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.072, 0.080, 0.079, 0.9)
	style.border_color = Color(0.655, 0.531, 0.245)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	item_panel.add_theme_stylebox_override("panel", style)


	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	item_panel.add_child(margin)

	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(row)

	var avatar = _make_static_pet_avatar(str(pet.pet_id), Vector2(56, 56))
	if avatar:
		avatar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(avatar)


	var mid = Control.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.custom_minimum_size = Vector2(0, 72)
	mid.clip_contents = true
	row.add_child(mid)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 2)
	mid.add_child(vbox)

	var quality_text = _get_pet_quality_bracket_text(pet)
	var name_label = Label.new()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.text = "%s%s Lv.%d" % [pet.pet_name, quality_text, pet.level]
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", _get_pet_name_quality_color(pet))
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	vbox.add_child(name_label)

	var stats_label = Label.new()
	stats_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_label.text = "[%s] %d代  成长:%.3f  五行:%s" % [
		pet.form, pet.generation, pet.total_growth, pet.element
	]
	if pet.reincarnation_count > 0:
		stats_label.text += "  转生:%d" % pet.reincarnation_count
	stats_label.add_theme_font_size_override("font_size", 18)
	stats_label.add_theme_color_override("font_color", Color(0.894, 0.864, 0.803))
	stats_label.clip_text = true
	stats_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	vbox.add_child(stats_label)

	var current_index = pet_manager.EVOLUTION_FORMS.find(pet.form)
	var next_form = pet_manager.EVOLUTION_FORMS[current_index + 1] if current_index >= 0 and current_index < pet_manager.EVOLUTION_FORMS.size() - 1 else ""
	var can_evolve_result = pet_manager.can_evolve(pet)
	var can_mutate = bool(can_evolve_result.get("can_mutate", false))

	var path_label = Label.new()
	path_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if can_mutate:
		path_label.text = "-> %s  可能变异" % next_form
		path_label.add_theme_color_override("font_color", Color(0.85, 0.5, 0.95))
	else:
		path_label.text = "-> %s" % next_form
		path_label.add_theme_color_override("font_color", Color(1, 0.6, 0.2))
	path_label.add_theme_font_size_override("font_size", 18)
	path_label.clip_text = true
	path_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	vbox.add_child(path_label)

	var select_btn = Button.new()
	select_btn.text = "选择"
	select_btn.custom_minimum_size = Vector2(72, 36)
	select_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	select_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	select_btn.add_theme_font_size_override("font_size", 18)
	UIStyle.apply_action_button_style(select_btn)
	var pet_stable_id: = String(pet.id)
	select_btn.pressed.connect( func():
		panel.set_meta("evolve_confirm_pet_id", pet_stable_id)
		_request_evolve_view_rebuild(panel)
	)
	row.add_child(select_btn)
	return item_panel

static func _build_evolve_confirm_view_fullscreen(panel: Control, pet) -> void :
	var content_container = panel.get_meta("content_container") as VBoxContainer
	var game_manager = panel.get_meta("game_manager")
	var pet_manager = game_manager.pet_manager
	var targets: Dictionary = _resolve_evolve_preview_targets(pet, pet_manager)
	var next_form: = str(targets.get("next_form", ""))
	var can_mutate: = bool(targets.get("can_mutate", false))
	var next_normal_id: = str(targets.get("next_normal_id", "")).strip_edges()
	var next_mutant_id: = str(targets.get("next_mutant_id", "")).strip_edges()

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_container.add_child(scroll)
	TouchScrollUtils.configure_scroll(scroll)

	var body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	scroll.add_child(body)


	var current_card: = _make_pet_park_section_card("当前宠物")
	var current_body: = _pet_park_section_body(current_card)
	var current_row = HBoxContainer.new()
	current_row.add_theme_constant_override("separation", 12)
	current_row.alignment = BoxContainer.ALIGNMENT_CENTER
	current_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cur_avatar = _make_static_pet_avatar(str(pet.pet_id), Vector2(88, 88))
	if cur_avatar:
		current_row.add_child(cur_avatar)
	var cur_info = Label.new()
	var quality_text = _get_pet_quality_bracket_text(pet)
	cur_info.text = "%s%s\nLv.%d  [%s]  %d代\n成长:%.3f  五行:%s" % [
		pet.pet_name, quality_text, pet.level, pet.form, pet.generation, pet.total_growth, pet.element
	]
	cur_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	cur_info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cur_info.add_theme_font_size_override("font_size", 21)
	cur_info.add_theme_color_override("font_color", _get_pet_name_quality_color(pet))
	current_row.add_child(cur_info)
	current_body.add_child(current_row)
	body.add_child(current_card)


	var form_card: = _make_pet_park_section_card("形态变化")
	var form_body: = _pet_park_section_body(form_card)
	var form_arrow = Label.new()
	form_arrow.text = "%s  →  %s" % [str(pet.form), next_form if not next_form.is_empty() else "？"]
	form_arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	form_arrow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form_arrow.add_theme_font_size_override("font_size", 22)
	form_arrow.add_theme_color_override("font_color", Color(1, 0.7, 0.35))
	form_body.add_child(form_arrow)
	body.add_child(form_card)


	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	btn_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(btn_row)

	var reselect_btn = Button.new()
	reselect_btn.text = "重选宠物"
	reselect_btn.custom_minimum_size = Vector2(120, 44)
	reselect_btn.add_theme_font_size_override("font_size", 21)
	UIStyle.apply_button_style(reselect_btn)
	reselect_btn.pressed.connect( func():
		panel.set_meta("evolve_confirm_pet_id", "")
		_request_evolve_view_rebuild(panel)
	)
	btn_row.add_child(reselect_btn)

	var evolve_btn = Button.new()
	evolve_btn.text = "开始进化"
	evolve_btn.custom_minimum_size = Vector2(140, 48)
	evolve_btn.add_theme_font_size_override("font_size", 22)
	UIStyle.apply_action_button_style(evolve_btn)
	evolve_btn.pressed.connect( func():
		var use_mutant = false
		var mutation_on = false
		if game_manager != null and game_manager.has_method("is_pet_mutation_feature_enabled"):
			mutation_on = bool(game_manager.is_pet_mutation_feature_enabled())
		if not mutation_on and can_mutate and randf() < 0.2:
			use_mutant = true
		_do_evolve_fullscreen(panel, pet, next_form, use_mutant, evolve_btn, can_mutate)
	)
	btn_row.add_child(evolve_btn)


	var preview_card: = _make_pet_park_section_card("可能进化出的下一形态")
	var preview_body: = _pet_park_section_body(preview_card)

	var preview_row = HBoxContainer.new()
	preview_row.alignment = BoxContainer.ALIGNMENT_CENTER
	preview_row.add_theme_constant_override("separation", 20)
	preview_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_body.add_child(preview_row)


	var dual_preview: = can_mutate and not next_normal_id.is_empty() and not next_mutant_id.is_empty()
	var preview_size: = _feature_preview_size(dual_preview)
	if dual_preview:
		var normal_col = VBoxContainer.new()
		normal_col.alignment = BoxContainer.ALIGNMENT_CENTER
		normal_col.add_theme_constant_override("separation", 6)
		var n_label = Label.new()
		n_label.text = "正常进化\n%s" % _get_species_display_name(next_normal_id)
		n_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n_label.add_theme_font_size_override("font_size", 19)
		n_label.add_theme_color_override("font_color", Color(0.75, 0.95, 0.75))
		normal_col.add_child(n_label)
		_mount_feature_preview(normal_col, next_normal_id, preview_size)
		preview_row.add_child(normal_col)

		var mutant_col = VBoxContainer.new()
		mutant_col.alignment = BoxContainer.ALIGNMENT_CENTER
		mutant_col.add_theme_constant_override("separation", 6)
		var m_label = Label.new()
		m_label.text = "可能变异出\n%s" % _get_species_display_name(next_mutant_id)
		m_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		m_label.add_theme_font_size_override("font_size", 19)
		m_label.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
		mutant_col.add_child(m_label)
		_mount_feature_preview(mutant_col, next_mutant_id, preview_size)
		preview_row.add_child(mutant_col)

		var roll_hint = Label.new()
		roll_hint.text = "是否变异由系统判定"
		roll_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		roll_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		roll_hint.add_theme_font_size_override("font_size", 18)
		roll_hint.add_theme_color_override("font_color", Color(0.734, 0.714, 0.657))
		preview_body.add_child(roll_hint)
	elif not next_normal_id.is_empty():
		var single_col = VBoxContainer.new()
		single_col.alignment = BoxContainer.ALIGNMENT_CENTER
		single_col.add_theme_constant_override("separation", 6)
		var s_label = Label.new()
		s_label.text = "下一形态\n%s" % _get_species_display_name(next_normal_id)
		s_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		s_label.add_theme_font_size_override("font_size", 20)
		s_label.add_theme_color_override("font_color", Color(0.85, 0.95, 0.75))
		single_col.add_child(s_label)
		_mount_feature_preview(single_col, next_normal_id, preview_size)
		preview_row.add_child(single_col)
	else:
		preview_body.add_child(_create_placeholder_label("暂无下一形态预览数据"))

	var tip = Label.new()
	tip.text = "进化后等级重置为1"
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tip.add_theme_font_size_override("font_size", 18)
	tip.add_theme_color_override("font_color", Color(0.734, 0.714, 0.657))
	preview_body.add_child(tip)
	var evolve_growth_predict: = _predict_evolve_growth_range(pet, game_manager)
	var evolve_growth_text: = _format_evolve_growth_predict_text(evolve_growth_predict)
	if not evolve_growth_text.is_empty():
		var growth_predict_label = Label.new()
		growth_predict_label.text = evolve_growth_text
		growth_predict_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		growth_predict_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		growth_predict_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		growth_predict_label.add_theme_font_size_override("font_size", 20)
		growth_predict_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
		preview_body.add_child(growth_predict_label)
	body.add_child(preview_card)
	TouchScrollUtils.enable_touch_drag_passthrough(body)

static func _add_pet_park_wait_overlay(panel: Control, line1: String) -> ColorRect:
	var overlay = ColorRect.new()
	overlay.name = "PetParkNetWaitOverlay"
	overlay.color = Color(0.631, 0.611, 0.564, 0.72)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var lbl = Label.new()
	lbl.text = line1
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
	center.add_child(lbl)
	panel.add_child(overlay)
	overlay.z_index = 100
	panel.move_child(overlay, panel.get_child_count() - 1)
	return overlay


static func _remove_pet_park_wait_overlay(overlay: ColorRect) -> void :
	if overlay != null and is_instance_valid(overlay):
		overlay.queue_free()


static func _set_pet_park_wait_overlay_text(overlay: ColorRect, text: String) -> void :
	if overlay == null or not is_instance_valid(overlay):
		return
	var center = overlay.get_child(0) as CenterContainer
	if center == null or center.get_child_count() < 1:
		return
	var lbl = center.get_child(0) as Label
	if lbl:
		lbl.text = text

static func _ensure_critical_sync_ready(panel: Control, game_manager, op_name: String) -> bool:
	if not game_manager or not game_manager.network or not game_manager.network.is_logged_in():
		_show_result_popup_fullscreen(panel, op_name, op_name + "失败", "当前网络不可用，请联网后再尝试。\n\n为防止SL刷成长，关键操作需要实时联网并完成云端确认。", game_manager)
		return false
	if game_manager.network.has_method("can_commit_critical_op") and not bool(game_manager.network.can_commit_critical_op()):
		var msg: = "当前网络同步异常，请等待网络恢复后再尝试。"
		if game_manager.network.has_method("get_sync_status_message"):
			msg = str(game_manager.network.get_sync_status_message())
		_show_result_popup_fullscreen(panel, op_name, op_name + "失败", msg + "\n\n为避免进度回滚，本次操作已被阻止。", game_manager)
		return false
	return true




static func _run_evolve_animation_timers(panel: Control, anim_panel: Window) -> bool:
	var anim_label = anim_panel.get_meta("anim_label") as Label
	var desc_label = anim_panel.get_meta("desc_label") as Label
	if anim_label and desc_label:
		anim_label.text = "进化中·"
		desc_label.text = "血脉觉醒，力量涌动..."
	await panel.get_tree().create_timer(0.7).timeout
	if anim_label and desc_label and is_instance_valid(anim_panel):
		anim_label.text = "进化中··"
		desc_label.text = "形态蜕变，能量汇聚..."
	await panel.get_tree().create_timer(0.7).timeout
	if anim_label and desc_label and is_instance_valid(anim_panel):
		anim_label.text = "进化中···"
		desc_label.text = "最终突破，新形态诞生..."
	await panel.get_tree().create_timer(0.6).timeout
	if is_instance_valid(anim_panel):
		anim_panel.queue_free()
	return true


static func _run_fusion_animation_timers(panel: Control, anim_panel: Window) -> bool:
	var anim_label = anim_panel.get_meta("anim_label") as Label
	var desc_label = anim_panel.get_meta("desc_label") as Label
	if anim_label and desc_label:
		anim_label.text = "幻化中·"
		desc_label.text = "两只宠物开始融合..."
	await panel.get_tree().create_timer(0.7).timeout
	if anim_label and desc_label and is_instance_valid(anim_panel):
		anim_label.text = "幻化中··"
		desc_label.text = "血脉交融，基因重组..."
	await panel.get_tree().create_timer(0.7).timeout
	if anim_label and desc_label and is_instance_valid(anim_panel):
		anim_label.text = "幻化中···"
		desc_label.text = "新生命即将诞生..."
	await panel.get_tree().create_timer(0.6).timeout
	if is_instance_valid(anim_panel):
		anim_panel.queue_free()
	return true



const _PET_CLOUD_LEVEL_FETCH_TIMEOUT_MS: int = 30000


static func _find_pet_instance_level_in_save_data(save_data: Dictionary, instance_id: String) -> int:
	var pid: = str(instance_id).strip_edges()
	if pid.is_empty():
		return -1
	var pets_raw = save_data.get("petsData", null)
	var pets_arr: Array = []
	var bag_arr: Array = []
	if pets_raw is Dictionary:
		var pd: Dictionary = pets_raw
		pets_arr = pd.get("pets", [])
		bag_arr = pd.get("pet_bag", [])
	elif pets_raw is Array:
		pets_arr = pets_raw
	for p in pets_arr:
		if p is Dictionary and str(p.get("id", "")) == pid:
			return int(p.get("level", 0))
	for p in bag_arr:
		if p is Dictionary and str(p.get("id", "")) == pid:
			return int(p.get("level", 0))
	return -1


static func _fetch_cloud_pet_level_readonly(game_manager, instance_id: String) -> Dictionary:
	var result: = {"ok": false, "level": -1, "error": ""}
	if game_manager == null or game_manager.network == null or not game_manager.network.is_logged_in():
		result["error"] = "当前网络不可用，无法核对云端等级。"
		return result
	var net = game_manager.network
	var state: = {"done": false, "level": -1, "error": ""}
	var on_fetched = func(data: Dictionary):
		state["done"] = true
		if data.has("error") and not bool(data.get("success", false)):
			state["error"] = str(data.get("error", "核对云端等级失败"))
			return
		if not bool(data.get("success", false)):
			state["error"] = str(data.get("error", data.get("message", "核对云端等级失败")))
			return
		if bool(data.get("found", true)) == false:
			state["error"] = "云端未找到该宠物，请重新登录后再试。"
			return
		var lv: = int(data.get("level", -1))
		if lv < 0:
			state["error"] = "云端未找到该宠物，请重新登录后再试。"
			return
		state["level"] = lv
	net.pet_instance_level_fetched.connect(on_fetched, CONNECT_ONE_SHOT)
	net.fetch_pet_instance_level(instance_id)
	var start_ms: = Time.get_ticks_msec()
	while not bool(state.get("done", false)):
		if not is_instance_valid(game_manager):
			state["error"] = "界面已关闭"
			break
		if Time.get_ticks_msec() - start_ms > _PET_CLOUD_LEVEL_FETCH_TIMEOUT_MS:
			state["error"] = "核对云端等级超时，请稍后重试。"
			break
		await game_manager.get_tree().process_frame
	if int(state.get("level", -1)) >= 0:
		result["ok"] = true
		result["level"] = int(state["level"])
	else:
		result["error"] = str(state.get("error", "核对云端等级失败"))
	return result



static func _ensure_evolve_level_synced_for_max_level(panel: Control, game_manager, pet) -> bool:
	var instance_id: = str(pet.id) if pet != null else ""
	if instance_id.is_empty():
		_show_result_popup_fullscreen(panel, "宠物进化", "进化失败", "宠物数据无效，请关闭并重开宠物园后重试。", game_manager)
		return false
	var effective_max: = int(pet.get_effective_max_level()) if pet != null and pet.has_method("get_effective_max_level") else GameData.MAX_LEVEL_EVOLUTION
	var local_level: = int(pet.level)
	if local_level < effective_max:
		return true
	var check_overlay: = _add_pet_park_wait_overlay(panel, "正在核对云端宠物等级…")
	var fetch: Dictionary = await _fetch_cloud_pet_level_readonly(game_manager, instance_id)
	_remove_pet_park_wait_overlay(check_overlay)
	if not is_instance_valid(panel):
		return false
	if not bool(fetch.get("ok", false)):
		_show_result_popup_fullscreen(panel, "宠物进化", "进化失败", str(fetch.get("error", "无法核对云端等级，请稍后重试。")), game_manager)
		return false
	var cloud_level: = int(fetch.get("level", 0))
	print("[CloudSync] 宠物进化：本地Lv.%d 云端Lv.%d 有效上限=%d" % [local_level, cloud_level, effective_max])
	if cloud_level >= effective_max:
		return true
	var sync_overlay: = _add_pet_park_wait_overlay(panel, "正在同步宠物等级到云端…")
	var synced: bool = await game_manager.force_cloud_upload_and_wait("pet_evolve_level_sync", true, 120.0)
	_remove_pet_park_wait_overlay(sync_overlay)
	if not is_instance_valid(panel):
		return false
	if not synced:
		_show_result_popup_fullscreen(panel, "宠物进化", "同步失败", "宠物等级未同步成功，请检查网络后稍后再试。", game_manager)
		return false
	print("[CloudSync] 宠物进化：满级进度已同步，继续提交进化")
	return true


static func _do_evolve_fullscreen(panel: Control, pet, next_form: String, use_mutant: bool, btn: Button, can_mutate: bool = false):
	var game_manager = panel.get_meta("game_manager")
	if game_manager and game_manager.has_method("local_feature_action"):
		if use_mutant:
			_show_result_popup_fullscreen(panel, "宠物进化", "本地模拟", "变异路线尚未校准，请使用普通进化。", game_manager)
			return
		var result: Dictionary = game_manager.local_feature_action("pet_evolve", {"id": str(pet.id)})
		_request_evolve_view_rebuild(panel)
		_show_result_popup_fullscreen(panel, "宠物进化", "本地结果", str(result.get("message", "")), game_manager)
		return
	if not game_manager:
		return
	if not _ensure_critical_sync_ready(panel, game_manager, "宠物进化"):
		return
	var pm_evo = game_manager.pet_manager
	var pet_live = pm_evo.get_pet_by_stable_id(String(pet.id)) if pm_evo else null
	if pet_live == null:
		_show_result_popup_fullscreen(panel, "宠物进化", "进化失败", "宠物数据已更新，请关闭并重开宠物园后重试。", game_manager)
		return
	pet = pet_live
	var stable_pet_id: = String(pet.id)

	btn.disabled = true
	btn.text = "进化中..."

	if not await _ensure_evolve_level_synced_for_max_level(panel, game_manager, pet):
		if is_instance_valid(btn):
			btn.disabled = false
			btn.text = "开始进化"
		return


	pet = pm_evo.get_pet_by_stable_id(stable_pet_id) if pm_evo else null
	if pet == null:
		if is_instance_valid(btn):
			btn.disabled = false
			btn.text = "开始进化"
		_show_result_popup_fullscreen(panel, "宠物进化", "进化失败", "宠物数据已更新，请关闭并重开宠物园后重试。", game_manager)
		return


	print("[CloudSync] 宠物进化：开始专用事务流程")
	var anim_panel = _show_evolve_animation_fullscreen(panel, pet.pet_name, pet.form, next_form)
	await _run_evolve_animation_timers(panel, anim_panel)

	var net_overlay = _add_pet_park_wait_overlay(panel, "正在向服务器提交进化，请稍候…")

	var op_id = "pet_evolve_%s_%s" % [str(Time.get_unix_time_from_system()), str(randi())]
	var state: = {"done": false, "ok": false, "payload": {}}
	var on_success = func(data: Dictionary):
		state["done"] = true
		state["ok"] = true
		state["payload"] = data
	var on_failed = func(error_msg: String):
		state["done"] = true
		state["ok"] = false
		state["payload"] = {"error": error_msg}
	if game_manager.network:
		game_manager.network.pet_evolve_success.connect(on_success, CONNECT_ONE_SHOT)
		game_manager.network.pet_evolve_failed.connect(on_failed, CONNECT_ONE_SHOT)

		await game_manager.get_tree().process_frame
		game_manager.network.pet_evolve(stable_pet_id, use_mutant, op_id)
	var wait_start_ms = Time.get_ticks_msec()
	while not bool(state.get("done", false)):
		if not is_instance_valid(panel):
			if net_overlay != null and is_instance_valid(net_overlay):
				_remove_pet_park_wait_overlay(net_overlay)
			_show_result_popup_fullscreen(null, "宠物进化", "提示", "界面已关闭，本次进化结果可能稍后才会同步。\n请保持联网并稍后打开宠物园查看。", game_manager)
			return
		if Time.get_ticks_msec() - wait_start_ms > _PET_SERVER_RPC_WAIT_MS:
			state["done"] = true
			state["ok"] = false
			state["payload"] = {"error": "网络响应超时（60秒），但服务器可能已处理完成。\n请保持联网，稍后重新登录查看结果。\n如未生效，可再次尝试进化（系统会自动检测重复操作）。"}
			break
		await game_manager.get_tree().process_frame

	_remove_pet_park_wait_overlay(net_overlay)

	if not is_instance_valid(panel) or not is_instance_valid(btn):
		_show_result_popup_fullscreen(null, "宠物进化", "提示", "界面已关闭，若未看到进化结果请稍后重试或确认网络。", game_manager)
		return
	pet = pm_evo.get_pet_by_stable_id(stable_pet_id) if pm_evo else null
	btn.disabled = false
	btn.text = "开始进化"

	var ok = bool(state.get("ok", false))
	var payload: Dictionary = state.get("payload", {})
	if ok:
		if payload.get("duplicate"):
			if game_manager:
				game_manager.download_cloud_save()
			_notify_pet_evolve_quest(game_manager, pet, null, next_form)
			_show_result_popup_fullscreen(panel, "宠物进化", "提示", "该操作已在服务器处理，正在同步最新存档。", game_manager)
			panel.set_meta("evolve_confirm_pet_id", "")
			_request_evolve_view_rebuild(panel)
			return
		if not payload.has("result"):
			_show_result_popup_fullscreen(panel, "宠物进化", "进化失败", String(payload.get("message", "服务端返回缺少结果，请重试。")), game_manager)
			return
		var save_data = payload.get("saveData", {})
		if save_data is Dictionary and not save_data.is_empty():

			game_manager.apply_cloud_save(save_data, {"skip_pet_collection_trim": true, "pets_authoritative": true})
		var resolved = game_manager.pet_manager.get_pet_by_stable_id(stable_pet_id) if game_manager.pet_manager else null
		# 进化后等级必须回到 1：预览页和成功弹窗一直是这么写的，但服务端 /pet/evolve
		# 只重算成长、完全不动等级，满级 1200 进化完还是 1200，等于白送一大截面板。
		# 存档应用完之后在这里补做重置，并按新成长重算属性（不掷成长骰子）。
		var did_reset_level: = false
		var level_before_reset: int = int(resolved.level) if resolved != null else 0
		if RESET_LEVEL_ON_EVOLVE and resolved != null and level_before_reset > 1:
			resolved.level = 1
			resolved.experience = 0
			if game_manager.pet_manager != null:
				game_manager.pet_manager._update_pet_stats(resolved)
			did_reset_level = true
		if did_reset_level:
			print("[PetEvolve] 进化后等级已重置：%d → 1，属性按新成长重算" % level_before_reset)
		var result_data = payload.get("result", {})
		var new_growth = float(result_data.get("newGrowth", 0.0))

		var did_mutate: = false
		if result_data.has("mutated") or result_data.has("appliedMutant"):
			did_mutate = bool(result_data.get("mutated", result_data.get("appliedMutant", false)))
		else:

			did_mutate = bool(use_mutant)
		var mutation_count: = 0
		if did_mutate:
			mutation_count = clampi(int(result_data.get("mutation_count", result_data.get("mutationCount", 0))), 0, 2)
			if mutation_count <= 0 and resolved != null and "mutation_count" in resolved:
				mutation_count = clampi(int(resolved.mutation_count), 0, 2)
		var evolve_type = "变异进化" if did_mutate else "正常进化"
		var poem = String(result_data.get("poem", ""))
		var display_name: String = str(resolved.pet_name) if resolved else String(result_data.get("petName", ""))
		var display_form: String = str(resolved.form) if resolved else String(result_data.get("newForm", next_form))
		# 上面已经做过重置（服务端不重置，客户端补），这里照实写
		var lv_after: int = int(resolved.level) if resolved != null else int(result_data.get("level", 1))
		var lv_line: String = "等级：%d" % lv_after if lv_after > 1 else "等级：1（已重置）"

		if did_mutate and mutation_count > 0:
			display_name = InventoryManager.format_pet_name_with_mutation(display_name, mutation_count)
		var announce_msg = "恭喜【%s】的宠物【%s】%s成功！成长:%.3f" % [game_manager.player.player_name, display_name, evolve_type, new_growth]
		if poem != "":
			announce_msg = poem + "\n" + announce_msg
		game_manager.broadcast_event("pet_evolve", game_manager.player.player_name, {
			"pet_name": display_name, 
			"new_form": display_form, 
			"growth": new_growth, 
			"level": 1, 
			"mutated": did_mutate, 
			"mutation_count": mutation_count if did_mutate else 0, 
		}, announce_msg)
		_notify_pet_evolve_quest(game_manager, pet, resolved, display_form)


		if did_mutate:
			var mutate_title: = "★变异进化成功★"
			if mutation_count > 0:
				mutate_title = "★变异%d进化成功★" % mutation_count
			var evolve_detail = "新形态：%s\n成长：%.3f\n%s" % [
				display_form, 
				new_growth, 
				lv_line
			]
			var learned_evo: Variant = payload.get("learnedSkill", result_data.get("learnedSkill", null))
			if learned_evo is Dictionary and not learned_evo.is_empty():
				evolve_detail += "\n领悟技能：%slv%d" % [
					str(learned_evo.get("skill_name", learned_evo.get("skillName", "新技能"))), 
					int(learned_evo.get("level", 1))
				]
			_show_result_popup_fullscreen(panel, mutate_title, display_name, evolve_detail, game_manager)
		else:
			var evolve_detail_normal = "新形态：%s\n成长：%.3f\n%s" % [
				display_form, 
				new_growth, 
				lv_line
			]
			var learned_evo_n: Variant = payload.get("learnedSkill", result_data.get("learnedSkill", null))
			if learned_evo_n is Dictionary and not learned_evo_n.is_empty():
				evolve_detail_normal += "\n领悟技能：%slv%d" % [
					str(learned_evo_n.get("skill_name", learned_evo_n.get("skillName", "新技能"))), 
					int(learned_evo_n.get("level", 1))
				]
			_show_result_popup_fullscreen(panel, "宠物进化成功", display_name, evolve_detail_normal, game_manager)
		panel.set_meta("evolve_confirm_pet_id", "")
		# 服务端 /pet/evolve 是「只算不存」：它返回新存档，但自己没落库。
		# 而普通上传有 180 秒冷却（CLOUD_UPLOAD_MIN_INTERVAL），进化完不主动推一次，
		# 玩家这三分钟内退出游戏，进度就回滚了 —— 表现就是「进化了但没生效」。
		if game_manager.has_method("force_cloud_upload_and_wait"):
			var push_ok: bool = await game_manager.force_cloud_upload_and_wait("pet_evolve_result", true, 60.0)
			print("[CloudSync] 宠物进化：结果上传%s" % ("成功" if push_ok else "失败"))
		if not is_instance_valid(panel):
			return
		_request_evolve_view_rebuild(panel)
	else:
		_show_result_popup_fullscreen(panel, "宠物进化", "进化失败", String(payload.get("error", "请求失败")), game_manager)

static func _resolve_fusion_selected_pets(panel: Control, pet_manager) -> Dictionary:
	var fusion_main_pet = null
	var fusion_sub_pet = null
	if panel.has_meta("fusion_main_pet"):
		fusion_main_pet = panel.get_meta("fusion_main_pet")
	if panel.has_meta("fusion_sub_pet"):
		fusion_sub_pet = panel.get_meta("fusion_sub_pet")
	if fusion_main_pet != null and is_instance_valid(fusion_main_pet):
		var mid: = String(fusion_main_pet.id).strip_edges()
		if not mid.is_empty():
			var rm = pet_manager.get_pet_by_stable_id(mid)
			if rm != null:
				fusion_main_pet = rm
				panel.set_meta("fusion_main_pet", rm)
			else:
				fusion_main_pet = null
				panel.set_meta("fusion_main_pet", null)
	elif fusion_main_pet != null:
		panel.set_meta("fusion_main_pet", null)
		fusion_main_pet = null
	if fusion_sub_pet != null and is_instance_valid(fusion_sub_pet):
		var sid_f: = String(fusion_sub_pet.id).strip_edges()
		if not sid_f.is_empty():
			var rs = pet_manager.get_pet_by_stable_id(sid_f)
			if rs != null:
				fusion_sub_pet = rs
				panel.set_meta("fusion_sub_pet", rs)
			else:
				fusion_sub_pet = null
				panel.set_meta("fusion_sub_pet", null)
	elif fusion_sub_pet != null:
		panel.set_meta("fusion_sub_pet", null)
		fusion_sub_pet = null
	return {"main": fusion_main_pet, "sub": fusion_sub_pet}

static func _get_merge_weights_for_display(game_manager, use_transform_charm: bool) -> Dictionary:
	var tier: = 0
	if game_manager != null and game_manager.player != null:
		tier = VipBenefits.tier_from_player(game_manager.player)
	var tier_idx: = clampi(tier, 0, _MERGE_WEIGHTS_BY_TIER.size() - 1)
	var weights: Dictionary = (_MERGE_WEIGHTS_BY_TIER[tier_idx] as Dictionary).duplicate()
	var noble_lv: = clampi(int(game_manager.noble_level) if game_manager else 0, 0, NobleBenefits.MERGE_BONUS.size() - 1)
	var noble_bonus: = int(NobleBenefits.MERGE_BONUS[noble_lv])
	weights = _apply_merge_perfect_bonus_to_weights(weights, noble_bonus)
	if use_transform_charm:
		weights = _apply_merge_perfect_bonus_to_weights(weights, 15)
	return weights


static func _get_pet_atk_def_agi_growth_total(pet) -> float:
	if pet == null:
		return 0.0
	if "growth_rates" in pet and pet.growth_rates is Dictionary:
		var gr: Dictionary = pet.growth_rates
		return float(gr.get("attack", 0.0)) + float(gr.get("defense", 0.0)) + float(gr.get("agility", 0.0))
	if "total_growth" in pet:
		return float(pet.total_growth)
	return 0.0

static func _resolve_evolve_stage_for_predict(pet) -> int:
	if pet == null:
		return 0
	if "evolution_stage" in pet:
		return clampi(int(pet.evolution_stage), 0, 2)
	var form_str: = str(pet.form) if "form" in pet else ""
	var forms: = ["幼年", "一进", "二进", "终极"]
	var idx: = forms.find(form_str)
	if idx < 0:
		return 0
	return mini(idx, 2)


static func _compute_evolve_lineage_bonus_for_predict(pet, game_manager = null) -> float:
	if pet == null:
		return 0.0
	var seed: = 3.0
	if "lineage_seed_growth" in pet:
		seed = float(pet.lineage_seed_growth)
	elif "initial_total_growth" in pet:
		seed = float(pet.initial_total_growth)
	var base: = sqrt(maxf(0.0, seed - _EVOLVE_LINEAGE_BASELINE)) * _EVOLVE_LINEAGE_COEFF
	var mult: = 1.0
	if game_manager != null and game_manager.has_method("is_pet_mutation_feature_enabled") and game_manager.is_pet_mutation_feature_enabled():
		var cfg: Dictionary = {}
		if game_manager.has_method("get_pet_mutation_runtime_config"):
			cfg = game_manager.get_pet_mutation_runtime_config()
		var ev: Variant = cfg.get("lineageEvolve", {})
		var base_mult: = 1.0
		var mut0: = 1.0
		var mut1: = 1.0
		var mut2: = 1.0
		if ev is Dictionary:
			base_mult = float(ev.get("baseMult", 1.0))
			var mm: Variant = ev.get("mutationMult", {})
			if mm is Dictionary:
				mut0 = float(mm.get(0, mm.get("0", 1.0)))
				mut1 = float(mm.get(1, mm.get("1", 1.0)))
				mut2 = float(mm.get(2, mm.get("2", 1.0)))
		var mc: = _get_pet_mutation_count(pet)
		var mut_mult: = mut0
		if mc == 1:
			mut_mult = mut1
		elif mc == 2:
			mut_mult = mut2
		mult = base_mult * mut_mult
	return base * mult


static func _predict_evolve_growth_range(pet, game_manager = null) -> Dictionary:
	var out: = {"min": 0.0, "max": 0.0, "is_max_level": false, "ok": false}
	if pet == null:
		return out
	var stage: = _resolve_evolve_stage_for_predict(pet)
	var effective_max: = GameData.MAX_LEVEL_EVOLUTION
	if pet.has_method("get_effective_max_level"):
		effective_max = int(pet.get_effective_max_level())
	var is_max_level: = int(pet.level) >= effective_max
	var base_min: = 1.0
	var base_max: = 1.5
	if stage == 0:
		if is_max_level:
			base_min = 1.5
			base_max = 2.0
		else:
			base_min = 1.0
			base_max = 1.5
	elif stage == 1:
		if is_max_level:
			base_min = 1.8
			base_max = 2.5
		else:
			base_min = 1.2
			base_max = 1.8
	elif stage == 2:
		if is_max_level:
			base_min = 2.0
			base_max = 3.0
		else:
			base_min = 1.5
			base_max = 2.0
	var gen: = int(pet.generation) if "generation" in pet else 0
	var gen_mult: = 1.0 + float(gen + 1) * 0.1
	var evo_bonus: = _compute_evolve_lineage_bonus_for_predict(pet, game_manager)
	var old_total: = _get_pet_atk_def_agi_growth_total(pet)
	var inc_min: = base_min * gen_mult + evo_bonus
	var inc_max: = base_max * gen_mult + evo_bonus
	out["min"] = snapped(old_total + inc_min, 0.001)
	out["max"] = snapped(old_total + inc_max, 0.001)
	out["is_max_level"] = is_max_level
	out["ok"] = true
	return out

static func _format_evolve_growth_predict_text(predict: Dictionary) -> String:
	if not bool(predict.get("ok", false)):
		return ""
	var hint: = "满级加成" if bool(predict.get("is_max_level", false)) else "未满级，满级更高"
	return "成长预测：%.3f ~ %.3f（%s）" % [
		float(predict.get("min", 0.0)), 
		float(predict.get("max", 0.0)), 
		hint
	]


static func _predict_merge_growth_outcomes(main_pet, sub_pet) -> Dictionary:
	var out: = {"A": 0.0, "B": 0.0, "C": 0.0, "D": 0.0, "ok": false}
	if main_pet == null or sub_pet == null:
		return out
	var main_total: = _get_pet_atk_def_agi_growth_total(main_pet)
	var sub_total: = _get_pet_atk_def_agi_growth_total(sub_pet)
	var high: = maxf(main_total, sub_total)
	var low: = minf(main_total, sub_total)
	out["A"] = snapped(high, 0.001)
	out["B"] = snapped(high * 0.8 + low * 0.2, 0.001)
	out["C"] = snapped(high * 0.7 + low * 0.3, 0.001)
	out["D"] = snapped((main_total + sub_total) / 2.0, 0.001)
	out["ok"] = true
	return out

static func _format_merge_growth_predict_text(outcomes: Dictionary, weights: Dictionary) -> String:
	if not bool(outcomes.get("ok", false)):
		return ""
	return "成长预测：完美(%d%%) %.3f / 优良(%d%%) %.3f / 普通(%d%%) %.3f / 平均(%d%%) %.3f" % [
		int(weights.get("A", 0)), float(outcomes.get("A", 0.0)), 
		int(weights.get("B", 0)), float(outcomes.get("B", 0.0)), 
		int(weights.get("C", 0)), float(outcomes.get("C", 0.0)), 
		int(weights.get("D", 0)), float(outcomes.get("D", 0.0))
	]

static func _style_fusion_charm_checkbox(charm_check: CheckBox) -> void :
	charm_check.text = "使用幻化符"
	charm_check.custom_minimum_size = Vector2(0, 42)
	charm_check.add_theme_font_size_override("font_size", 21)
	charm_check.add_theme_color_override("font_color", Color(1.0, 0.92, 0.5))
	charm_check.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.7))
	charm_check.add_theme_color_override("font_pressed_color", Color(1.0, 0.96, 0.7))
	charm_check.add_theme_color_override("font_disabled_color", Color(0.631, 0.611, 0.564))
	charm_check.add_theme_color_override("icon_normal_color", Color(1.0, 0.85, 0.35))
	charm_check.add_theme_color_override("icon_hover_color", Color(1.0, 0.92, 0.5))
	charm_check.add_theme_color_override("icon_pressed_color", Color(1.0, 0.95, 0.65))
	charm_check.add_theme_color_override("icon_disabled_color", Color(0.631, 0.611, 0.564))
	var charm_checkbox_normal = StyleBoxFlat.new()
	charm_checkbox_normal.bg_color = Color(0.072, 0.080, 0.079, 0.85)
	charm_checkbox_normal.border_width_left = 1
	charm_checkbox_normal.border_width_top = 1
	charm_checkbox_normal.border_width_right = 1
	charm_checkbox_normal.border_width_bottom = 1
	charm_checkbox_normal.border_color = Color(0.95, 0.75, 0.25, 0.65)
	charm_checkbox_normal.corner_radius_top_left = 0
	charm_checkbox_normal.corner_radius_top_right = 0
	charm_checkbox_normal.corner_radius_bottom_left = 0
	charm_checkbox_normal.corner_radius_bottom_right = 0
	charm_check.add_theme_stylebox_override("normal", charm_checkbox_normal)
	var charm_checkbox_hover = charm_checkbox_normal.duplicate()
	charm_checkbox_hover.bg_color = Color(0.072, 0.080, 0.079, 0.95)
	charm_checkbox_hover.border_color = Color(1.0, 0.82, 0.3, 0.9)
	charm_check.add_theme_stylebox_override("hover", charm_checkbox_hover)
	charm_check.add_theme_stylebox_override("pressed", charm_checkbox_hover.duplicate())
	charm_check.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

static func _build_fusion_slot_row(panel: Control, pet, is_main: bool) -> Panel:
	var item_panel = Panel.new()
	item_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_panel.custom_minimum_size = Vector2(0, 96)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.072, 0.080, 0.079, 0.9)
	style.border_color = Color(0.655, 0.531, 0.245)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	item_panel.add_theme_stylebox_override("panel", style)
	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 10
	hbox.offset_top = 8
	hbox.offset_right = -10
	hbox.offset_bottom = -8
	hbox.add_theme_constant_override("separation", 12)
	item_panel.add_child(hbox)
	if pet != null:
		var avatar = _make_static_pet_avatar(str(pet.pet_id), Vector2(72, 72))
		if avatar:
			hbox.add_child(avatar)
		var info = Label.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		info.text = "%s%s\nLv.%d [%s] %d代  成长:%.3f" % [
			pet.pet_name, _get_pet_quality_bracket_text(pet), pet.level, pet.form, pet.generation, pet.total_growth
		]
		info.add_theme_font_size_override("font_size", 20)
		info.add_theme_color_override("font_color", _get_pet_name_quality_color(pet))
		hbox.add_child(info)
	else:
		var empty = Label.new()
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.text = "尚未选择%s" % ("主宠" if is_main else "副宠")
		empty.add_theme_font_size_override("font_size", 21)
		empty.add_theme_color_override("font_color", Color(0.734, 0.714, 0.657))
		hbox.add_child(empty)
	var action_btn = Button.new()
	action_btn.text = "更换" if pet != null else "选择"
	action_btn.custom_minimum_size = Vector2(72, 36)
	action_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	action_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	action_btn.add_theme_font_size_override("font_size", 18)
	UIStyle.apply_action_button_style(action_btn)
	action_btn.pressed.connect( func():
		_show_fusion_pet_picker_fullscreen(panel, is_main)
	)
	hbox.add_child(action_btn)
	if pet != null:
		var clear_btn = Button.new()
		clear_btn.text = "清除"
		clear_btn.custom_minimum_size = Vector2(64, 36)
		clear_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
		clear_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		clear_btn.add_theme_font_size_override("font_size", 18)
		UIStyle.apply_button_style(clear_btn)
		clear_btn.pressed.connect( func():
			if is_main:
				panel.set_meta("fusion_main_pet", null)
			else:
				panel.set_meta("fusion_sub_pet", null)
			_refresh_fusion_view_fullscreen(panel)
		)
		hbox.add_child(clear_btn)
	return item_panel

static func _show_fusion_pet_picker_fullscreen(panel: Control, is_main: bool) -> void :
	var game_manager = panel.get_meta("game_manager")
	if game_manager == null or game_manager.pet_manager == null:
		return
	var pet_manager = game_manager.pet_manager
	var selected = _resolve_fusion_selected_pets(panel, pet_manager)
	var exclude = selected.get("sub") if is_main else selected.get("main")
	var saved_search = str(panel.get_meta("fusion_search_text")) if panel.has_meta("fusion_search_text") else ""
	panel.set_meta("fusion_search_text", "")
	var pets = _get_filtered_pets_for_fusion_fullscreen(pet_manager, panel, exclude)
	panel.set_meta("fusion_search_text", saved_search)

	var overlay = ColorRect.new()
	overlay.name = "FusionPetPickerOverlay"
	overlay.color = Color(0.631, 0.611, 0.564, 0.78)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 120
	panel.add_child(overlay)
	panel.move_child(overlay, panel.get_child_count() - 1)

	var card = Panel.new()
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.offset_left = 24
	card.offset_top = 48
	card.offset_right = -24
	card.offset_bottom = -48
	card.add_theme_stylebox_override("panel", UIStyle.create_panel_style())
	overlay.add_child(card)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 12
	vbox.offset_top = 12
	vbox.offset_right = -12
	vbox.offset_bottom = -12
	vbox.add_theme_constant_override("separation", 8)
	card.add_child(vbox)

	var title = Label.new()
	title.text = "选择主宠物" if is_main else "选择副宠物"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	vbox.add_child(title)

	var tip = Label.new()
	tip.text = "规则: 等级300+ | 0-2代且同代幻化 | 列表为静态图"
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.add_theme_font_size_override("font_size", 18)
	tip.add_theme_color_override("font_color", Color(0.791, 0.769, 0.708))
	vbox.add_child(tip)

	var search_hbox = HBoxContainer.new()
	search_hbox.add_theme_constant_override("separation", 8)
	var search_edit = LineEdit.new()
	search_edit.placeholder_text = "搜索宠物名称..."
	search_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_edit.custom_minimum_size = Vector2(0, 36)
	search_edit.add_theme_font_size_override("font_size", 20)
	search_hbox.add_child(search_edit)
	vbox.add_child(search_hbox)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	TouchScrollUtils.configure_scroll(scroll)
	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)

	var close_picker: = func():
		if is_instance_valid(overlay):
			overlay.queue_free()

	var rebuild_list: = func(filter_text: String = ""):
		for c in list.get_children():
			c.queue_free()
		var shown: = 0
		var ft: = filter_text.strip_edges().to_lower()
		for pet in pets:
			if ft != "" and ft not in str(pet.pet_name).to_lower():
				continue
			shown += 1
			var item = Panel.new()
			item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			item.custom_minimum_size = Vector2(0, 88)
			var st = StyleBoxFlat.new()
			st.bg_color = Color(0.072, 0.080, 0.079, 0.95)
			st.border_color = Color(0.655, 0.531, 0.245)
			st.border_width_left = 2
			st.border_width_top = 2
			st.border_width_right = 2
			st.border_width_bottom = 2
			st.corner_radius_top_left = 0
			st.corner_radius_top_right = 0
			st.corner_radius_bottom_left = 0
			st.corner_radius_bottom_right = 0
			item.add_theme_stylebox_override("panel", st)
			var row = HBoxContainer.new()
			row.set_anchors_preset(Control.PRESET_FULL_RECT)
			row.offset_left = 10
			row.offset_top = 6
			row.offset_right = -10
			row.offset_bottom = -6
			row.add_theme_constant_override("separation", 10)
			item.add_child(row)
			var av = _make_static_pet_avatar(str(pet.pet_id), Vector2(64, 64))
			if av:
				row.add_child(av)
			var info = Label.new()
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			info.text = "%s%s\nLv.%d [%s] %d代  成长:%.3f" % [
				pet.pet_name, _get_pet_quality_bracket_text(pet), pet.level, pet.form, pet.generation, pet.total_growth
			]
			info.add_theme_font_size_override("font_size", 20)
			info.add_theme_color_override("font_color", _get_pet_name_quality_color(pet))
			row.add_child(info)
			var pick_btn = Button.new()
			pick_btn.text = "选择"
			pick_btn.custom_minimum_size = Vector2(72, 36)
			pick_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
			pick_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			pick_btn.add_theme_font_size_override("font_size", 18)
			UIStyle.apply_action_button_style(pick_btn)
			var pick = pet
			pick_btn.pressed.connect( func():
				if is_main:
					panel.set_meta("fusion_main_pet", pick)
				else:
					panel.set_meta("fusion_sub_pet", pick)
				close_picker.call()
				_refresh_fusion_view_fullscreen(panel)
			)
			row.add_child(pick_btn)
			list.add_child(item)
		if shown == 0:
			list.add_child(_create_placeholder_label("没有符合条件的宠物"))
		TouchScrollUtils.enable_touch_drag_passthrough(list)

	search_edit.text_changed.connect( func(t): rebuild_list.call(t))
	rebuild_list.call("")

	var close_btn = Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(120, 42)
	close_btn.add_theme_font_size_override("font_size", 21)
	UIStyle.apply_button_style(close_btn)
	close_btn.pressed.connect( func(): close_picker.call())
	var close_wrap = CenterContainer.new()
	close_wrap.add_child(close_btn)
	vbox.add_child(close_wrap)

static func _start_fusion_submit_fullscreen(panel: Control, charm_check: CheckBox, fusion_btn: Button) -> void :
	var game_manager = panel.get_meta("game_manager")
	if game_manager and game_manager.has_method("local_feature_action"):
		var selected: Dictionary = _resolve_fusion_selected_pets(panel, game_manager.pet_manager)
		if selected.get("main") == null or selected.get("sub") == null:
			_show_result_popup_fullscreen(panel, "宠物幻化", "提示", "请选择主宠与副宠。", game_manager)
			return
		if charm_check.button_pressed:
			_show_result_popup_fullscreen(panel, "宠物幻化", "本地模拟", "幻化符概率尚未校准，请取消勾选；不会消耗幻化符。", game_manager)
			return
		var args := {"id": str(selected.main.id), "sub_id": str(selected.sub.id)}
		var confirm := ConfirmationDialog.new()
		confirm.dialog_text = "本地测试：消耗副宠，按成长合成规则生成新成长，代数+1、等级回到1级。确定继续？"
		confirm.confirmed.connect(func():
			var result: Dictionary = game_manager.local_feature_action("pet_merge", args)
			_request_fusion_view_rebuild(panel)
			_show_result_popup_fullscreen(panel, "宠物幻化", "本地结果", str(result.get("message", "")), game_manager)
			confirm.queue_free()
		)
		confirm.canceled.connect(confirm.queue_free)
		panel.add_child(confirm)
		confirm.popup_centered(Vector2i(440, 240))
		return
	if not game_manager:
		return
	if not _ensure_critical_sync_ready(panel, game_manager, "宠物幻化"):
		return
	if charm_check.button_pressed:
		if _count_inventory_item_by_name(game_manager, "幻化符") < 1:
			_show_result_popup_fullscreen(panel, "宠物幻化", "提示", "幻化符数量不足，请先取消勾选或前往商店购买。", game_manager)
			return
	var use_charm: bool = charm_check.button_pressed
	var pm_submit = game_manager.pet_manager
	var selected = _resolve_fusion_selected_pets(panel, pm_submit)
	var fusion_main_pet = selected.get("main")
	var fusion_sub_pet = selected.get("sub")
	if fusion_main_pet == null or fusion_sub_pet == null:
		_show_result_popup_fullscreen(panel, "宠物幻化", "幻化失败", "请先选择主宠与副宠。", game_manager)
		return
	var main_live = pm_submit.get_pet_by_stable_id(String(fusion_main_pet.id)) if pm_submit else null
	var sub_live = pm_submit.get_pet_by_stable_id(String(fusion_sub_pet.id)) if pm_submit else null
	if main_live == null or sub_live == null:
		_show_result_popup_fullscreen(panel, "宠物幻化", "幻化失败", "宠物数据已更新，请重新选择主宠与副宠后再试。", game_manager)
		return
	fusion_main_pet = main_live
	fusion_sub_pet = sub_live
	panel.set_meta("fusion_main_pet", main_live)
	panel.set_meta("fusion_sub_pet", sub_live)
	var merge_main_stable_id: = String(fusion_main_pet.id)
	var merge_sub_stable_id: = String(fusion_sub_pet.id)
	game_manager.begin_pet_merge_exp_block(merge_main_stable_id, merge_sub_stable_id, _PET_SERVER_RPC_WAIT_MS + 10000)
	if game_manager.has_method("begin_pet_merge_battle_guard"):
		game_manager.begin_pet_merge_battle_guard(_PET_SERVER_RPC_WAIT_MS + 15000)
	else:
		game_manager.block_battle_start_temporarily(_PET_SERVER_RPC_WAIT_MS + 15000, "pet_merge_in_progress")
	if game_manager.network:
		game_manager.network.discard_pending_saves_after_cloud_applied()
	fusion_btn.disabled = true
	fusion_btn.text = "幻化中..."

	print("[CloudSync] 宠物幻化：开始专用事务流程")
	var anim_panel = _show_fusion_animation_fullscreen(panel, fusion_main_pet.pet_name, fusion_sub_pet.pet_name)
	await _run_fusion_animation_timers(panel, anim_panel)

	var fusion_net_overlay = _add_pet_park_wait_overlay(panel, "正在向服务器提交幻化，请稍候…")

	var op_id = "pet_merge_%s_%s" % [str(Time.get_unix_time_from_system()), str(randi())]
	var state: = {"done": false, "ok": false, "payload": {}}
	var on_success = func(data: Dictionary):
		state["done"] = true
		state["ok"] = true
		state["payload"] = data
	var on_failed = func(error_msg: String):
		state["done"] = true
		state["ok"] = false
		state["payload"] = {"error": error_msg}
	if game_manager.network:
		game_manager.network.pet_merge_success.connect(on_success, CONNECT_ONE_SHOT)
		game_manager.network.pet_merge_failed.connect(on_failed, CONNECT_ONE_SHOT)
		await game_manager.get_tree().process_frame
		game_manager.network.pet_merge(String(fusion_main_pet.id), String(fusion_sub_pet.id), op_id, use_charm)
	var wait_start_ms = Time.get_ticks_msec()
	while not bool(state.get("done", false)):
		if not is_instance_valid(panel):
			if fusion_net_overlay != null and is_instance_valid(fusion_net_overlay):
				_remove_pet_park_wait_overlay(fusion_net_overlay)
			_finish_pet_merge_guard(game_manager)
			_show_result_popup_fullscreen(null, "宠物幻化", "提示", "界面已关闭，本次幻化结果可能稍后才会同步。\n请保持联网并稍后打开宠物园查看。", game_manager)
			return
		if Time.get_ticks_msec() - wait_start_ms > _PET_SERVER_RPC_WAIT_MS:
			state["done"] = true
			state["ok"] = false
			state["payload"] = {"error": "网络响应超时（60秒），但服务器可能已处理完成。\n请保持联网，稍后重新登录查看结果。\n如未生效，可再次尝试幻化（系统会自动检测重复操作）。"}
			break
		await game_manager.get_tree().process_frame

	_remove_pet_park_wait_overlay(fusion_net_overlay)

	if not is_instance_valid(panel) or not is_instance_valid(fusion_btn):
		_finish_pet_merge_guard(game_manager)
		_show_result_popup_fullscreen(null, "宠物幻化", "提示", "界面已关闭，若未看到幻化结果请稍后重试或确认网络。", game_manager)
		return
	fusion_btn.disabled = false
	fusion_btn.text = "开始幻化"

	var ok = bool(state.get("ok", false))
	var payload: Dictionary = state.get("payload", {})
	if ok:
		if payload.get("duplicate"):
			_finish_pet_merge_guard(game_manager)
			if game_manager:
				game_manager.download_cloud_save()
			_notify_pet_merge_quest(game_manager, fusion_main_pet, fusion_sub_pet, {})
			panel.set_meta("fusion_main_pet", null)
			panel.set_meta("fusion_sub_pet", null)
			_show_result_popup_fullscreen(panel, "宠物幻化", "提示", "该操作已在服务器处理，正在同步最新存档。", game_manager)
			_build_fusion_view_fullscreen(panel)
			return
		if not payload.has("result"):
			_finish_pet_merge_guard(game_manager)
			_show_result_popup_fullscreen(panel, "宠物幻化", "幻化失败", String(payload.get("message", "服务端返回缺少结果，请重试。")), game_manager)
			return
		var save_data = payload.get("saveData", {})
		if save_data is Dictionary and not save_data.is_empty():
			game_manager.apply_cloud_save(save_data, {
				"skip_pet_collection_trim": true, 
				"pets_authoritative": true, 
				"skip_pet_progress_merge": true, 
			})
			var main_ui_merge = game_manager._find_main_ui_node() if game_manager.has_method("_find_main_ui_node") else null
			if main_ui_merge != null and main_ui_merge.has_method("_refresh_pet_roster_after_authority_reward"):
				main_ui_merge.call_deferred("_refresh_pet_roster_after_authority_reward")
			game_manager._suppress_general_cloud_upload_until_ms = maxi(
				game_manager._suppress_general_cloud_upload_until_ms, 
				Time.get_ticks_msec() + 15000
			)
		var result_data = payload.get("result", {})
		var new_pet_name = String(result_data.get("newPetName", "新宠物"))
		var new_pet_growth = float(result_data.get("newGrowth", 0.0))
		var new_pet_generation = int(result_data.get("newGeneration", 1))
		if not _pet_merge_local_matches_result(game_manager, merge_main_stable_id, new_pet_generation, new_pet_growth):
			push_warning("[PetPark] 幻化本地数据与 result 不一致，强制拉取云端 id=%s" % merge_main_stable_id)
			await _await_cloud_save_download_for_pet_park(game_manager, 30000)
		_finish_pet_merge_guard(game_manager)
		var poem = String(result_data.get("poem", ""))
		var announce_msg = "恭喜【%s】的宠物幻化成功！%s 成长:%.3f 代数:%d" % [game_manager.player.player_name, new_pet_name, new_pet_growth, new_pet_generation]
		if poem != "":
			announce_msg = poem + "\n" + announce_msg
		game_manager.broadcast_event("pet_fusion", game_manager.player.player_name, {"pet_name": new_pet_name, "growth": new_pet_growth, "generation": new_pet_generation}, announce_msg)
		_notify_pet_merge_quest(game_manager, fusion_main_pet, fusion_sub_pet, result_data)
		panel.set_meta("fusion_main_pet", null)
		panel.set_meta("fusion_sub_pet", null)
		var merge_type_name = String(result_data.get("mergeName", ""))
		if merge_type_name == "":
			merge_type_name = _get_merge_type_display_name(String(result_data.get("mergeType", "")))
		var detail_lines = "新宠：%s\n成长：%.3f\n代数：%d" % [new_pet_name, new_pet_growth, new_pet_generation]
		if merge_type_name != "":
			detail_lines += "\n继承类型：%s" % merge_type_name
		var inherited: Variant = payload.get("inheritedSkills", result_data.get("inheritedSkills", []))
		if inherited is Array and not inherited.is_empty():
			var names: PackedStringArray = PackedStringArray()
			for row in inherited:
				if row is Dictionary:
					var nm: = str(row.get("skill_name", row.get("skillName", ""))).strip_edges()
					var lv: = int(row.get("level", row.get("to", 0)))
					if not nm.is_empty():
						names.append("%slv%d" % [nm, lv] if lv > 0 else nm)
				else:
					var s: = str(row).strip_edges()
					if not s.is_empty():
						names.append(s)
			if names.size() > 0:
				detail_lines += "\n技能继承：%s" % ", ".join(names)
		_show_result_popup_fullscreen(panel, "宠物幻化成功", "幻化完成", detail_lines, game_manager)
		_build_fusion_view_fullscreen(panel)
	else:
		_finish_pet_merge_guard(game_manager)
		_show_result_popup_fullscreen(panel, "宠物幻化", "幻化失败", String(payload.get("error", "请求失败")), game_manager)

static func _build_fusion_view_fullscreen(panel: Control):
	var content_container = panel.get_meta("content_container") as VBoxContainer
	var game_manager = panel.get_meta("game_manager")

	if not content_container:
		return

	_clear_pet_park_content(content_container)

	if not game_manager or not game_manager.pet_manager:
		var no_data_label = Label.new()
		no_data_label.text = "无宠物数据"
		no_data_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content_container.add_child(no_data_label)
		return

	var player = game_manager.player
	var pet_manager = game_manager.pet_manager
	var selected = _resolve_fusion_selected_pets(panel, pet_manager)
	var fusion_main_pet = selected.get("main")
	var fusion_sub_pet = selected.get("sub")

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_container.add_child(scroll)
	TouchScrollUtils.configure_scroll(scroll)

	var main_vbox = VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(main_vbox)

	var rules_label = Label.new()
	rules_label.text = "规则: 双方≥Lv300、同代数、代数<3；消耗两宠生成新宠（保留主宠物种）"
	rules_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rules_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rules_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules_label.add_theme_font_size_override("font_size", 19)
	rules_label.add_theme_color_override("font_color", Color(0.734, 0.714, 0.657))
	main_vbox.add_child(rules_label)

	var main_slot_title = Label.new()
	main_slot_title.text = "主宠物（保留物种）"
	main_slot_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_slot_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_slot_title.add_theme_font_size_override("font_size", 21)
	main_slot_title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	main_vbox.add_child(main_slot_title)
	main_vbox.add_child(_build_fusion_slot_row(panel, fusion_main_pet, true))

	var sub_slot_title = Label.new()
	sub_slot_title.text = "副宠物（提供素材）"
	sub_slot_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_slot_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub_slot_title.add_theme_font_size_override("font_size", 21)
	sub_slot_title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	main_vbox.add_child(sub_slot_title)
	main_vbox.add_child(_build_fusion_slot_row(panel, fusion_sub_pet, false))


	var growth_predict_holder: = {"label": null, "outcomes": {}, "pending_weights": {}}
	if fusion_main_pet and fusion_sub_pet:
		growth_predict_holder["outcomes"] = _predict_merge_growth_outcomes(fusion_main_pet, fusion_sub_pet)
		var main_medals = _get_pet_medal_counts(fusion_main_pet)
		var sub_medals = _get_pet_medal_counts(fusion_sub_pet)
		var inherit_count = int(floor(float(_get_total_medals(sub_medals)) / 2.0))
		var medal_hint = Label.new()
		medal_hint.text = "勋章预估：主宠全继承（勇%d/冷%d/果%d）+ 副宠随机继承%d枚" % [
			int(main_medals.get("brave", 0)), 
			int(main_medals.get("calm", 0)), 
			int(main_medals.get("bold", 0)), 
			inherit_count
		]
		medal_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		medal_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		medal_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		medal_hint.add_theme_font_size_override("font_size", 19)
		medal_hint.add_theme_color_override("font_color", Color(0.95, 0.85, 0.6))
		main_vbox.add_child(medal_hint)

		var weight_label = Label.new()
		weight_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		weight_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		weight_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		weight_label.add_theme_font_size_override("font_size", 19)
		weight_label.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
		main_vbox.add_child(weight_label)

		var can_result = pet_manager.can_merge(fusion_main_pet, fusion_sub_pet, player.realm)
		if not can_result.can:
			var fail_weights: = _get_merge_weights_for_display(game_manager, false)
			weight_label.text = "继承类型权重：完美%d / 优良%d / 普通%d / 平均%d" % [
				int(fail_weights.get("A", 0)), int(fail_weights.get("B", 0)), int(fail_weights.get("C", 0)), int(fail_weights.get("D", 0))
			]
			growth_predict_holder["pending_weights"] = fail_weights
			var error_label = Label.new()
			error_label.text = "! " + can_result.message
			error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			error_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			error_label.add_theme_font_size_override("font_size", 21)
			error_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
			main_vbox.add_child(error_label)
		else:
			var fusion_action_col = VBoxContainer.new()
			fusion_action_col.alignment = BoxContainer.ALIGNMENT_CENTER
			fusion_action_col.add_theme_constant_override("separation", 6)
			var fusion_action_row = HBoxContainer.new()
			fusion_action_row.alignment = BoxContainer.ALIGNMENT_CENTER
			fusion_action_row.add_theme_constant_override("separation", 12)
			var charm_check = CheckBox.new()
			_style_fusion_charm_checkbox(charm_check)
			var charm_owned: = _count_inventory_item_by_name(game_manager, "幻化符")
			var charm_hint_label = Label.new()
			charm_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			charm_hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			charm_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			charm_hint_label.add_theme_font_size_override("font_size", 18)
			var refresh_weights: = func(use_charm: bool = false):
				var active_charm: = use_charm and charm_owned > 0
				var weights: = _get_merge_weights_for_display(game_manager, active_charm)
				weight_label.text = "继承类型权重：完美%d / 优良%d / 普通%d / 平均%d" % [
					int(weights.get("A", 0)), int(weights.get("B", 0)), int(weights.get("C", 0)), int(weights.get("D", 0))
				]
				growth_predict_holder["pending_weights"] = weights
				var gpl = growth_predict_holder.get("label")
				if gpl != null and is_instance_valid(gpl):
					gpl.text = _format_merge_growth_predict_text(growth_predict_holder.get("outcomes", {}), weights)
				var perfect_pct: = int(weights.get("A", 0))
				if charm_owned <= 0:
					charm_check.disabled = true
					charm_hint_label.text = "背包中没有幻化符（友情点商店可购买） · 当前完美幻化总几率%d%%" % perfect_pct
					charm_hint_label.add_theme_color_override("font_color", Color(0.85, 0.55, 0.55))
				else:
					charm_check.disabled = false
					charm_hint_label.text = "消耗1张幻化符，完美幻化+15%% · 当前拥有%d张 · 当前完美幻化总几率%d%%" % [charm_owned, perfect_pct]
					charm_hint_label.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
			refresh_weights.call(false)
			if charm_owned > 0:
				charm_check.toggled.connect( func(pressed: bool):
					refresh_weights.call(pressed)
				)
			fusion_action_row.add_child(charm_check)
			var fusion_btn = Button.new()
			fusion_btn.text = "开始幻化"
			fusion_btn.custom_minimum_size = Vector2(140, 50)
			fusion_btn.add_theme_font_size_override("font_size", 24)
			UIStyle.apply_action_button_style(fusion_btn)
			fusion_action_row.add_child(fusion_btn)
			fusion_action_col.add_child(fusion_action_row)
			fusion_action_col.add_child(charm_hint_label)
			fusion_btn.pressed.connect( func():
				_start_fusion_submit_fullscreen(panel, charm_check, fusion_btn)
			)
			main_vbox.add_child(fusion_action_col)
	elif fusion_main_pet != null:
		main_vbox.add_child(_create_placeholder_label("请继续选择副宠"))
	else:
		main_vbox.add_child(_create_placeholder_label("请选择主宠和副宠"))

	var preview_section = _create_section_vbox("结果预览（主宠物种）")
	main_vbox.add_child(preview_section)

	if fusion_main_pet == null:
		preview_section.add_child(_create_placeholder_label("选择主宠后显示预览"))
	else:
		var preview_wrap = CenterContainer.new()
		preview_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_mount_feature_preview(preview_wrap, str(fusion_main_pet.pet_id), _feature_preview_size(false))
		preview_section.add_child(preview_wrap)
		var species_label = Label.new()
		species_label.text = "结果物种：%s" % _get_species_display_name(str(fusion_main_pet.pet_id))
		species_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		species_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		species_label.add_theme_font_size_override("font_size", 20)
		species_label.add_theme_color_override("font_color", Color(0.85, 0.95, 0.75))
		preview_section.add_child(species_label)
		if fusion_sub_pet != null:
			var growth_predict_label = Label.new()
			growth_predict_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			growth_predict_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			growth_predict_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			growth_predict_label.add_theme_font_size_override("font_size", 18)
			growth_predict_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
			preview_section.add_child(growth_predict_label)
			growth_predict_holder["label"] = growth_predict_label
			var pw: Dictionary = growth_predict_holder.get("pending_weights", {})
			if pw.is_empty():
				pw = _get_merge_weights_for_display(game_manager, false)
				growth_predict_holder["pending_weights"] = pw
			growth_predict_label.text = _format_merge_growth_predict_text(growth_predict_holder.get("outcomes", {}), pw)
	TouchScrollUtils.enable_touch_drag_passthrough(main_vbox)

static func _get_filtered_pets_for_fusion_fullscreen(pet_manager, panel: Control, exclude_pet = null) -> Array:
	var pets = []
	var search_text = panel.get_meta("fusion_search_text")
	var sort_mode = panel.get_meta("fusion_sort_mode")

	for i in range(pet_manager.get_pet_count()):
		var pet = pet_manager.get_pet(i)
		if search_text != "" and search_text.to_lower() not in pet.pet_name.to_lower():
			continue
		if pet.locked:
			continue
		if pet.level < 300:
			continue
		if pet.generation >= 3:
			continue
		if pet_manager.active_pet and pet.id == pet_manager.active_pet.id:
			continue

		if exclude_pet and pet.id == exclude_pet.id:
			continue

		if exclude_pet and int(pet.generation) != int(exclude_pet.generation):
			continue
		pets.append(pet)

	match sort_mode:
		0:
			pets.sort_custom( func(a, b): return a.level > b.level)
		1:
			pets.sort_custom( func(a, b): return a.level < b.level)
		2:
			pets.sort_custom( func(a, b): return a.total_growth > b.total_growth)
		3:
			pets.sort_custom( func(a, b): return a.total_growth < b.total_growth)
		4:
			pets.sort_custom( func(a, b): return a.generation > b.generation)
		5:
			pets.sort_custom( func(a, b): return a.generation < b.generation)

	return pets

static func _refresh_evolve_view_fullscreen(panel: Control):
	_request_evolve_view_rebuild(panel)

static func _refresh_fusion_view_fullscreen(panel: Control):
	_request_fusion_view_rebuild(panel)


static func _request_evolve_view_rebuild(panel: Control) -> void :
	if panel == null or not is_instance_valid(panel):
		return
	if bool(panel.get_meta("_evolve_rebuild_queued", false)):
		return
	panel.set_meta("_evolve_rebuild_queued", true)
	_flush_evolve_view_rebuild.call_deferred(panel)

static func _flush_evolve_view_rebuild(panel: Control) -> void :
	if panel == null or not is_instance_valid(panel):
		return
	panel.set_meta("_evolve_rebuild_queued", false)
	_build_evolve_view_fullscreen(panel)

static func _request_fusion_view_rebuild(panel: Control) -> void :
	if panel == null or not is_instance_valid(panel):
		return
	if bool(panel.get_meta("_fusion_rebuild_queued", false)):
		return
	panel.set_meta("_fusion_rebuild_queued", true)
	_flush_fusion_view_rebuild.call_deferred(panel)

static func _flush_fusion_view_rebuild(panel: Control) -> void :
	if panel == null or not is_instance_valid(panel):
		return
	panel.set_meta("_fusion_rebuild_queued", false)
	_build_fusion_view_fullscreen(panel)

static func _build_collection_view_fullscreen(panel: Control):
	var content_container = panel.get_meta("content_container") as VBoxContainer
	var game_manager = panel.get_meta("game_manager")

	if not content_container:
		return

	_clear_pet_park_content(content_container)

	if not game_manager:
		var no_data_label = Label.new()
		no_data_label.text = "无数据"
		no_data_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content_container.add_child(no_data_label)
		return


	# 图鉴已和宠物页的「灵兽图鉴」合并成同一页：这里不再建旧版那套列表，
	# 直接把主界面那页顶上来。先把宠物园退回大厅，关掉图鉴看到的就是大厅而不是空白功能层。
	var main_ui: = _find_main_ui(game_manager)
	if main_ui != null and main_ui.has_method("_show_pet_atlas_page"):
		_show_pet_park_hub(panel)
		main_ui.call("_show_pet_atlas_page")
		return

	# 兜底（找不到主界面：独立运行或调试场景）才用旧图鉴
	var collection_view = PetCollectionUI.create_fullscreen(game_manager, false)
	content_container.add_child(collection_view)


	PetCollectionUI.refresh_on_open(collection_view)


## 找到主界面节点。图鉴那一页挂在主界面根上，宠物园在 city 层里，得往上找。
## 注意节点名是场景里起的（main.tscn 里叫 InkMainUI），不能按名字找，
## 按"有没有图鉴那页的入口方法"来认。
static func _find_main_ui(game_manager) -> Control:
	if game_manager == null or game_manager.get_tree() == null:
		return null
	var root: Window = game_manager.get_tree().root
	if root == null:
		return null
	var stack: Array = root.get_children()
	while not stack.is_empty():
		var n = stack.pop_back()
		if n is Control and n.has_method("_show_pet_atlas_page"):
			return n as Control
		stack.append_array(n.get_children())
	return null

static func _create_dropdown_button_fullscreen(parent_control: Control, items: Array, selected_idx: int, on_selected: Callable) -> Button:
	var btn = Button.new()
	btn.text = items[selected_idx]
	btn.custom_minimum_size = Vector2(100, 32)
	btn.add_theme_font_size_override("font_size", 20)
	UIStyle.apply_button_style(btn)

	var popup = PopupMenu.new()
	for i in range(items.size()):
		popup.add_item(items[i], i)
		if i == selected_idx:
			popup.set_item_checked(i, true)

	btn.pressed.connect( func():
		var btn_rect = btn.get_global_rect()
		popup.position = Vector2i(int(btn_rect.position.x), int(btn_rect.position.y + btn_rect.size.y))
		popup.popup()
	)

	popup.index_pressed.connect( func(idx: int):
		btn.text = items[idx]
		for i in range(items.size()):
			popup.set_item_checked(i, i == idx)
		on_selected.call(idx)
	)

	parent_control.add_child(popup)

	return btn

static func _show_evolve_animation_fullscreen(parent_control: Control, pet_name: String, current_form: String, next_form: String) -> Window:
	var dialog = Window.new()
	dialog.title = ""
	dialog.size = Vector2i(400, 250)
	dialog.transparent = true
	dialog.borderless = true
	dialog.unresizable = true

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
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	popup.add_child(vbox)

	var anim_label = Label.new()
	anim_label.text = "进化中..."
	anim_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	anim_label.add_theme_font_size_override("font_size", 29)
	anim_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	vbox.add_child(anim_label)
	dialog.set_meta("anim_label", anim_label)

	var pet_label = Label.new()
	pet_label.text = "%s [%s -> %s]" % [pet_name, current_form, next_form]
	pet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pet_label.add_theme_font_size_override("font_size", 22)
	pet_label.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
	vbox.add_child(pet_label)

	var desc_label = Label.new()
	desc_label.text = "准备开始..."
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 20)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(desc_label)
	dialog.set_meta("desc_label", desc_label)

	WindowHost.attach_window_and_popup_centered(dialog, parent_control)

	return dialog

static func _show_fusion_animation_fullscreen(parent_control: Control, main_name: String, sub_name: String) -> Window:
	var dialog = Window.new()
	dialog.title = ""
	dialog.size = Vector2i(400, 250)
	dialog.transparent = true
	dialog.borderless = true
	dialog.unresizable = true

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
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	popup.add_child(vbox)

	var anim_label = Label.new()
	anim_label.text = "幻化中..."
	anim_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	anim_label.add_theme_font_size_override("font_size", 29)
	anim_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	vbox.add_child(anim_label)
	dialog.set_meta("anim_label", anim_label)

	var pet_label = Label.new()
	pet_label.text = "%s + %s" % [main_name, sub_name]
	pet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pet_label.add_theme_font_size_override("font_size", 22)
	pet_label.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
	vbox.add_child(pet_label)

	var desc_label = Label.new()
	desc_label.text = "准备开始..."
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 20)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(desc_label)
	dialog.set_meta("desc_label", desc_label)

	WindowHost.attach_window_and_popup_centered(dialog, parent_control)

	return dialog

static func _show_result_popup_fullscreen(parent_control: Control, title: String, message: String, details: String, game_manager = null):
	var dialog = Window.new()
	dialog.title = ""
	dialog.size = Vector2i(450, 380)
	dialog.transparent = true
	dialog.borderless = true
	dialog.unresizable = true
	dialog.close_requested.connect( func(): dialog.queue_free())

	var popup = Panel.new()
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	dialog.add_child(popup)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 25
	vbox.offset_top = 25
	vbox.offset_right = -25
	vbox.offset_bottom = -28
	vbox.add_theme_constant_override("separation", 14)
	popup.add_child(vbox)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)

	var content_width: = 400.0
	var title_label = Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.custom_minimum_size = Vector2(content_width, 0)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_font_size_override("font_size", 27)
	title_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	content.add_child(title_label)

	if message != "":
		var msg_label = Label.new()
		msg_label.text = message
		msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		msg_label.custom_minimum_size = Vector2(content_width, 0)
		msg_label.add_theme_font_size_override("font_size", 21)
		msg_label.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
		msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(msg_label)

	if details != "":
		var details_label = Label.new()
		details_label.text = details
		details_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		details_label.custom_minimum_size = Vector2(content_width, 0)
		details_label.add_theme_font_size_override("font_size", 20)
		details_label.add_theme_color_override("font_color", Color(0.734, 0.714, 0.657))
		details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(details_label)

	var ok_btn = Button.new()
	ok_btn.text = "确定"
	UIStyle.style_popup_button(ok_btn, true)
	ok_btn.pressed.connect( func(): dialog.queue_free())
	vbox.add_child(ok_btn)

	if parent_control != null and is_instance_valid(parent_control) and parent_control.is_inside_tree():
		WindowHost.attach_window_and_popup_centered(dialog, parent_control)
	elif game_manager != null and is_instance_valid(game_manager) and game_manager.get_tree():
		WindowHost.attach_window_to_scene_root(dialog, game_manager.get_tree())
	else:
		push_warning("[PetPark] 无法显示结果弹窗：无可用挂载点")
		dialog.queue_free()

static func _pet_merge_local_matches_result(game_manager, main_pet_id: String, expected_gen: int, expected_growth: float) -> bool:
	if game_manager == null or game_manager.pet_manager == null:
		return false
	var pid: = str(main_pet_id).strip_edges()
	if pid.is_empty():
		return false
	var pet = game_manager.pet_manager.get_pet_by_stable_id(pid)
	if pet == null:
		return false
	if int(pet.generation) != expected_gen:
		return false
	if absf(float(pet.total_growth) - expected_growth) > 0.01:
		return false
	return true

static func _await_cloud_save_download_for_pet_park(game_manager, timeout_ms: int = 30000) -> bool:
	if game_manager == null:
		return false
	var state: = {"done": false, "ok": false}
	var on_dl = func(success: bool, _save_data: Dictionary):
		state["done"] = true
		state["ok"] = bool(success)
	if not game_manager.cloud_save_downloaded.is_connected(on_dl):
		game_manager.cloud_save_downloaded.connect(on_dl, CONNECT_ONE_SHOT)
	game_manager.download_cloud_save()
	var start_ms: = Time.get_ticks_msec()
	while not bool(state.get("done", false)):
		if Time.get_ticks_msec() - start_ms > timeout_ms:
			break
		await game_manager.get_tree().process_frame
	return bool(state.get("ok", false))

static func _notify_pet_evolve_quest(game_manager, pet, resolved, display_form: String) -> void :
	if game_manager == null or game_manager.pet_manager == null:
		return
	var old_form: = str(pet.form) if pet else ""
	var evolved_pet = resolved if resolved else pet
	game_manager.pet_manager.pet_evolved.emit(evolved_pet, old_form, display_form)

static func _notify_pet_merge_quest(game_manager, main_pet, sub_pet, result_data: Dictionary) -> void :
	if game_manager == null or game_manager.pet_manager == null:
		return
	var merge_type: = String(result_data.get("mergeType", ""))
	game_manager.pet_manager.pet_merged.emit(null, main_pet, sub_pet, merge_type)

static func _get_merge_type_display_name(merge_type: String) -> String:
	match merge_type:
		"A":
			return "完美继承"
		"B":
			return "优良继承"
		"C":
			return "普通继承"
		"D":
			return "平均继承"
		_:
			return merge_type


static func _apply_merge_perfect_bonus_to_weights(base_weights: Dictionary, bonus_percent: int) -> Dictionary:
	var remaining: = maxi(0, bonus_percent)
	if remaining <= 0:
		return base_weights.duplicate()
	var next_weights: = {
		"A": maxi(0, int(base_weights.get("A", 0))), 
		"B": maxi(0, int(base_weights.get("B", 0))), 
		"C": maxi(0, int(base_weights.get("C", 0))), 
		"D": maxi(0, int(base_weights.get("D", 0))), 
	}
	for bucket in ["D", "C", "B"]:
		if remaining <= 0:
			break
		var take: = mini(remaining, int(next_weights.get(bucket, 0)))
		next_weights[bucket] = int(next_weights.get(bucket, 0)) - take
		next_weights["A"] = int(next_weights.get("A", 0)) + take
		remaining -= take
	if int(next_weights.get("A", 0)) > 100:
		var overflow: = int(next_weights.get("A", 0)) - 100
		next_weights["A"] = 100
		next_weights["B"] = maxi(0, int(next_weights.get("B", 0)) - overflow)
	return next_weights

static func _calc_merge_perfect_percent(game_manager, use_transform_charm: bool) -> int:
	var tier: = 0
	if game_manager != null and game_manager.player != null:
		tier = VipBenefits.tier_from_player(game_manager.player)
	var tier_idx: = clampi(tier, 0, _MERGE_WEIGHTS_BY_TIER.size() - 1)
	var weights: Dictionary = (_MERGE_WEIGHTS_BY_TIER[tier_idx] as Dictionary).duplicate()
	var noble_lv: = clampi(int(game_manager.noble_level) if game_manager else 0, 0, NobleBenefits.MERGE_BONUS.size() - 1)
	var noble_bonus: = int(NobleBenefits.MERGE_BONUS[noble_lv])
	weights = _apply_merge_perfect_bonus_to_weights(weights, noble_bonus)
	if use_transform_charm:
		weights = _apply_merge_perfect_bonus_to_weights(weights, 15)
	return maxi(0, int(weights.get("A", 0)))

static func _get_pet_medal_counts(pet) -> Dictionary:
	var result = {"brave": 0, "calm": 0, "bold": 0}
	if pet == null:
		return result
	if "medal_counts" in pet and pet.medal_counts is Dictionary:
		var medals = pet.medal_counts as Dictionary
		result.brave = clamp(int(medals.get("brave", medals.get("yongmeng", 0))), 0, 5)
		result.calm = clamp(int(medals.get("calm", medals.get("lengjing", 0))), 0, 5)
		result.bold = clamp(int(medals.get("bold", medals.get("guogan", 0))), 0, 5)
	return result

static func _get_total_medals(medals: Dictionary) -> int:
	return int(medals.get("brave", 0)) + int(medals.get("calm", 0)) + int(medals.get("bold", 0))
