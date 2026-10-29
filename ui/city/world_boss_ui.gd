class_name WorldBossUI
extends RefCounted

const UIStyle = preload("res://scripts/ui_style.gd")
const WorldBossConfig = preload("res://scripts/world_boss/world_boss_config.gd")
const PetIdleDisplay = preload("res://scripts/ui/pet_idle_display.gd")
const PlayerCharacterConfig = preload("res://scripts/player_character_config.gd")
const WindowHost = preload("res://scripts/ui/window_host.gd")

const BOSS_DISPLAY_SIZE: = Vector2(240, 240)
const BOSS_STAGE_HEIGHT: = 240
const HERO_ROW_MIN_HEIGHT: = 240
const RANK_PANEL_MIN_WIDTH: = 96
const RANK_PREVIEW_LIMIT: = 5
const RANK_POPUP_LIMIT: = 100
const RANK_AVATAR_SIZE: = 32
const RANK_NUM_COL_WIDTH: = 32
const OUTER_MARGIN: = 10
const PANEL_INNER_MARGIN: = 10
const LOOT_ICON_CELL_W: = 64
const WB_UI_DIR: = "res://assets/ui/world_boss/"
const WB_BG_PATH: = WB_UI_DIR + "wb_bg_atmosphere.jpg"
const WB_STAGE_PATH: = WB_UI_DIR + "wb_boss_stage.png"
const WB_ICON_ATTEMPTS_PATH: = WB_UI_DIR + "wb_icon_attempts.png"
const WB_ICON_DAMAGE_PATH: = WB_UI_DIR + "wb_icon_damage.png"
const WB_ICON_RANK_PATH: = WB_UI_DIR + "wb_icon_rank.png"
const WB_BADGE_GOLD_PATH: = WB_UI_DIR + "wb_badge_gold.png"
const WB_BADGE_SILVER_PATH: = WB_UI_DIR + "wb_badge_silver.png"
const WB_BADGE_BRONZE_PATH: = WB_UI_DIR + "wb_badge_bronze.png"

static var _wb_tex_cache: Dictionary = {}


static func _boss_side_px() -> int:
	var w: = int(DisplayServer.window_get_size().x)
	if w <= 0:
		return 260

	return clampi(int(w * 0.56), 200, 320)

static func _load_wb_tex(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if _wb_tex_cache.has(path):
		return _wb_tex_cache[path]
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	elif FileAccess.file_exists(path):
		var img: = Image.load_from_file(ProjectSettings.globalize_path(path))
		if img != null and not img.is_empty():
			tex = ImageTexture.create_from_image(img)
	_wb_tex_cache[path] = tex
	return tex

static func _make_tex_rect(path: String, size: Vector2 = Vector2.ZERO) -> TextureRect:
	var tr: = TextureRect.new()
	tr.texture = _load_wb_tex(path)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if size != Vector2.ZERO:
		tr.custom_minimum_size = size
		tr.size = size
	return tr


static func _tex_fit_size(path: String, max_w: float, max_h: float) -> Vector2:
	var tex: = _load_wb_tex(path)
	if tex == null:
		return Vector2(maxi(1, int(max_w)), maxi(1, int(max_h)))
	var tw: = float(tex.get_width())
	var th: = float(tex.get_height())
	if tw <= 0.0 or th <= 0.0:
		return Vector2(maxi(1, int(max_w)), maxi(1, int(max_h)))
	var s: = minf(max_w / tw, max_h / th)
	return Vector2(tw * s, th * s)

static func create_content(game_manager, _parent: Control) -> Control:
	_wb_tex_cache.clear()
	var boss_side: = _boss_side_px()
	var boss_size: = Vector2(boss_side, boss_side)
	var stage_frame_h: = boss_side + 80

	var root: = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.clip_contents = true
	root.set_meta("wb_boss_side", boss_side)

	var bg: = _make_tex_rect(WB_BG_PATH)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.modulate = Color(1, 1, 1, 0.55)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)

	var scroll: = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.scroll_deadzone = 20
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(scroll)

	var outer_margin: = MarginContainer.new()
	outer_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer_margin.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	outer_margin.add_theme_constant_override("margin_left", OUTER_MARGIN)
	outer_margin.add_theme_constant_override("margin_right", OUTER_MARGIN)
	outer_margin.add_theme_constant_override("margin_top", OUTER_MARGIN)
	outer_margin.add_theme_constant_override("margin_bottom", OUTER_MARGIN)
	scroll.add_child(outer_margin)

	var main_vbox: = VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	main_vbox.add_theme_constant_override("separation", 12)
	outer_margin.add_child(main_vbox)

	var title: = Label.new()
	title.text = "🐉 世界boss"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
	main_vbox.add_child(title)

	var activity_label: = Label.new()
	activity_label.name = "ActivityLabel"
	activity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	activity_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	activity_label.add_theme_font_size_override("font_size", 15)
	activity_label.text = ""
	main_vbox.add_child(activity_label)

	var stats_row: = HBoxContainer.new()
	stats_row.name = "StatsRow"
	stats_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_row.add_theme_constant_override("separation", 10)
	main_vbox.add_child(stats_row)

	var remaining_card: = _create_stat_card("剩余次数", "0", "RemainingStatValue", WB_ICON_ATTEMPTS_PATH)
	var damage_card: = _create_stat_card("我的伤害", "0", "DamageStatValue", WB_ICON_DAMAGE_PATH)
	var rank_card: = _create_stat_card("我的排名", "-", "RankStatValue", WB_ICON_RANK_PATH)
	stats_row.add_child(remaining_card)
	stats_row.add_child(damage_card)
	stats_row.add_child(rank_card)

	var status_label: = Label.new()
	status_label.name = "StatusLabel"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.add_theme_color_override("font_color", Color(0.894, 0.864, 0.803))
	status_label.text = "同步排行中..."
	main_vbox.add_child(status_label)

	var hero_wrap: = MarginContainer.new()
	hero_wrap.name = "HeroRowWrap"
	hero_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	hero_wrap.add_theme_constant_override("margin_top", -15)
	main_vbox.add_child(hero_wrap)

	var hero_row: = HBoxContainer.new()
	hero_row.name = "HeroRow"
	hero_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_row.custom_minimum_size = Vector2(0, stage_frame_h)
	hero_row.add_theme_constant_override("separation", 8)
	hero_wrap.add_child(hero_row)


	var rank_panel: = _create_section_panel()
	rank_panel.custom_minimum_size = Vector2(RANK_PANEL_MIN_WIDTH, stage_frame_h)
	rank_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rank_panel.size_flags_stretch_ratio = 0.28
	hero_row.add_child(rank_panel)

	var rank_inner: = _panel_inner_vbox(rank_panel)
	rank_inner.add_theme_constant_override("separation", 6)

	var rank_title: = Label.new()
	rank_title.text = "当日排名"
	rank_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rank_title.add_theme_font_size_override("font_size", 16)
	rank_title.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
	rank_inner.add_child(rank_title)

	var rank_sub: = Label.new()
	rank_sub.text = "（前5名）"
	rank_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rank_sub.add_theme_font_size_override("font_size", 13)
	rank_sub.add_theme_color_override("font_color", Color(0.708, 0.688, 0.633))
	rank_inner.add_child(rank_sub)

	var rank_list: = VBoxContainer.new()
	rank_list.name = "RankList"
	rank_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rank_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rank_list.add_theme_constant_override("separation", 4)
	rank_inner.add_child(rank_list)

	var rank_more_row: = CenterContainer.new()
	rank_more_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rank_inner.add_child(rank_more_row)

	var rank_more_btn: = Button.new()
	rank_more_btn.name = "RankMoreBtn"
	rank_more_btn.text = "查看更多"
	rank_more_btn.custom_minimum_size = Vector2(100, 34)
	rank_more_btn.add_theme_font_size_override("font_size", 14)
	UIStyle.apply_button_style(rank_more_btn)
	rank_more_row.add_child(rank_more_btn)


	var boss_panel: = _create_section_panel()
	boss_panel.name = "BossPanel"
	boss_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boss_panel.size_flags_stretch_ratio = 0.72

	var boss_panel_clear: = StyleBoxFlat.new()
	boss_panel_clear.bg_color = Color(0, 0, 0, 0)
	boss_panel_clear.content_margin_left = PANEL_INNER_MARGIN
	boss_panel_clear.content_margin_right = PANEL_INNER_MARGIN
	boss_panel_clear.content_margin_top = PANEL_INNER_MARGIN
	boss_panel_clear.content_margin_bottom = PANEL_INNER_MARGIN
	boss_panel.add_theme_stylebox_override("panel", boss_panel_clear)
	hero_row.add_child(boss_panel)

	var boss_inner: = _panel_inner_vbox(boss_panel)
	boss_inner.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var boss_stage: = Control.new()
	boss_stage.name = "BossStage"

	boss_stage.custom_minimum_size = Vector2(0, stage_frame_h)
	boss_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boss_stage.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	boss_stage.clip_contents = true
	boss_inner.add_child(boss_stage)


	var stage_side: = int(clampf(float(boss_side) * 0.82, 130.0, 250.0))
	var stage_sz: = _tex_fit_size(WB_STAGE_PATH, float(stage_side), float(stage_side))
	var stage_bg: = _make_tex_rect(WB_STAGE_PATH, stage_sz)
	stage_bg.name = "BossStageBg"
	stage_bg.anchor_left = 0.5
	stage_bg.anchor_right = 0.5
	stage_bg.anchor_top = 1.0
	stage_bg.anchor_bottom = 1.0
	stage_bg.offset_left = - stage_sz.x * 0.5
	stage_bg.offset_right = stage_sz.x * 0.5

	stage_bg.offset_top = - stage_sz.y
	stage_bg.offset_bottom = 0
	stage_bg.z_index = 0
	stage_bg.modulate = Color(1, 1, 1, 0.98)
	boss_stage.add_child(stage_bg)

	var boss_sprite_layer: = CenterContainer.new()
	boss_sprite_layer.name = "BossSpriteLayer"
	boss_sprite_layer.set_anchors_preset(Control.PRESET_FULL_RECT)

	var sprite_lift: = int(stage_sz.y * 0.38) - 40 - 50 - 30 + 30
	boss_sprite_layer.offset_top = - sprite_lift
	boss_sprite_layer.offset_bottom = - sprite_lift
	boss_sprite_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_sprite_layer.z_index = 1
	boss_stage.add_child(boss_sprite_layer)

	var boss_sprite_host: = CenterContainer.new()
	boss_sprite_host.name = "BossSpriteHost"
	boss_sprite_host.custom_minimum_size = boss_size
	boss_sprite_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_sprite_layer.add_child(boss_sprite_host)

	var boss_info_top: = VBoxContainer.new()
	boss_info_top.name = "BossInfoTop"
	boss_info_top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	boss_info_top.offset_top = 2
	boss_info_top.offset_bottom = 52
	boss_info_top.add_theme_constant_override("separation", 2)
	boss_info_top.z_index = 2
	boss_stage.add_child(boss_info_top)

	var boss_name: = Label.new()
	boss_name.name = "BossNameLabel"
	boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boss_name.add_theme_font_size_override("font_size", 16)
	boss_name.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	boss_info_top.add_child(boss_name)

	var boss_element: = Label.new()
	boss_element.name = "BossElementLabel"
	boss_element.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_element.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boss_element.add_theme_font_size_override("font_size", 14)
	boss_info_top.add_child(boss_element)

	var challenge_row: = CenterContainer.new()
	challenge_row.name = "ChallengeRow"
	challenge_row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	challenge_row.offset_top = -56
	challenge_row.z_index = 10
	boss_stage.add_child(challenge_row)


	var challenge_btn: = Button.new()
	challenge_btn.name = "ChallengeBtn"
	challenge_btn.text = "挑战"
	challenge_btn.custom_minimum_size = Vector2(160, 48)
	challenge_btn.add_theme_font_size_override("font_size", 20)
	UIStyle.apply_golden_button_style(challenge_btn)
	UIStyle.setup_button_animation(challenge_btn)
	challenge_row.add_child(challenge_btn)

	var bottom_spacer: = Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 8)
	main_vbox.add_child(bottom_spacer)

	var rules_btn_row: = CenterContainer.new()
	rules_btn_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(rules_btn_row)

	var rules_btn: = Button.new()
	rules_btn.name = "RulesBtn"
	rules_btn.text = "规则说明"
	rules_btn.custom_minimum_size = Vector2(160, 44)
	rules_btn.add_theme_font_size_override("font_size", 18)
	UIStyle.apply_button_style(rules_btn)
	rules_btn_row.add_child(rules_btn)

	var loot_panel: = _create_loot_showcase_panel({})
	loot_panel.name = "LootShowcasePanel"
	loot_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(loot_panel)

	root.set_meta("game_manager", game_manager)
	root.set_meta("wb_rules_cfg", {})
	challenge_btn.pressed.connect( func():
		if game_manager != null and game_manager.has_method("request_world_boss_challenge_from_ui"):
			game_manager.request_world_boss_challenge_from_ui(root)
	)
	rank_more_btn.pressed.connect( func():
		_on_rank_more_pressed(game_manager, root)
	)
	rules_btn.pressed.connect( func():
		_open_rules_window(root)
	)

	var default_boss: = WorldBossConfig.pick_daily_boss_pet_id()
	_apply_boss_visual(
		boss_sprite_host, 
		boss_name, 
		default_boss, 
		boss_element
	)
	_apply_boss_panel_border(root, default_boss)
	_apply_status(root, {})
	_enable_touch_drag_passthrough(main_vbox)
	return root

static func _enable_touch_drag_passthrough(root: Control) -> void :
	var root_keep_input: = (root is BaseButton) or (root is LineEdit) or (root is TextEdit) or (root is OptionButton) or (root is ScrollContainer)
	if not root_keep_input:
		root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in root.get_children():
		if not (child is Control):
			continue
		var c: = child as Control
		var keep_input: = (c is BaseButton) or (c is LineEdit) or (c is TextEdit) or (c is OptionButton) or (c is ScrollContainer)
		if not keep_input:
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_enable_touch_drag_passthrough(c)

static func _create_stat_card(title_text: String, value_text: String, value_node_name: String, icon_path: String = "") -> PanelContainer:
	var card: = PanelContainer.new()
	var card_style: = UIStyle.create_item_style()
	card_style.content_margin_left = 10
	card_style.content_margin_right = 10
	card_style.content_margin_top = 8
	card_style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", card_style)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_stretch_ratio = 1.0

	var vbox: = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	var head: = HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", 6)
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(head)

	if not icon_path.is_empty():
		head.add_child(_make_tex_rect(icon_path, Vector2(32, 32)))

	var title_label: = Label.new()
	title_label.text = title_text
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color(0.708, 0.688, 0.633))
	head.add_child(title_label)

	var value_label: = Label.new()
	value_label.name = value_node_name
	value_label.text = value_text
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.add_theme_font_size_override("font_size", 20)
	value_label.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
	vbox.add_child(value_label)
	return card

static func _create_section_panel() -> PanelContainer:
	var panel: = PanelContainer.new()
	var style: = UIStyle.create_item_style()
	style.content_margin_left = PANEL_INNER_MARGIN
	style.content_margin_right = PANEL_INNER_MARGIN
	style.content_margin_top = PANEL_INNER_MARGIN
	style.content_margin_bottom = PANEL_INNER_MARGIN
	panel.add_theme_stylebox_override("panel", style)
	return panel

static func _panel_inner_vbox(panel: PanelContainer) -> VBoxContainer:
	var vbox: = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	panel.add_child(vbox)
	return vbox

static func refresh_panel(game_manager, root: Control) -> void :
	if game_manager == null or root == null or not is_instance_valid(root):
		return
	if game_manager.has_method("refresh_world_boss_ui_panel"):
		game_manager.refresh_world_boss_ui_panel(root)

static func apply_status_to_root(root: Control, data: Dictionary) -> void :
	_apply_status(root, data)

static func _find_node(root: Control, node_name: String) -> Node:
	if root == null:
		return null
	return root.find_child(node_name, true, false)

static func _loot_display_names(cfg: Dictionary) -> PackedStringArray:
	var raw_names: PackedStringArray = PackedStringArray()
	var raw: Variant = cfg.get("giftLootDisplay", null)
	if raw is Array:
		for entry in raw:
			var n: = str(entry).strip_edges()
			if not n.is_empty():
				raw_names.append(n)
	if raw_names.is_empty():
		raw_names = WorldBossConfig.gift_loot_display_names()
	return _filter_showcase_loot_names(raw_names)


static func _short_loot_label(raw_name: String) -> String:
	var s: = raw_name.strip_edges()
	if s.is_empty():
		return ""
	if s.contains("金币"):
		return "金币"
	if s.contains("极限装备"):
		return "极限装备"
	if s.contains("套装强化石"):
		return "套装强化石"
	if s.contains("宠物技能书") or s.contains("技能书"):
		return "宠物技能书"
	if s.contains("世界boss宠") or s.contains("世界Boss宠"):
		return "世界boss宠"
	return s

static func _filter_showcase_loot_names(raw_names: PackedStringArray) -> PackedStringArray:
	var out: = PackedStringArray()
	for n in raw_names:
		var short: = _short_loot_label(String(n))
		if short.is_empty():
			continue
		if out.has(short):
			continue
		out.append(short)
	if out.is_empty():
		return WorldBossConfig.gift_loot_display_names()
	return out

static func _loot_item_icon_tex(display_name: String) -> Texture2D:
	var n: = _short_loot_label(display_name)
	if n == "金币" or n.contains("金币"):
		var bag: = _load_wb_tex("res://assets/items/category/icon_gold_bag.png")
		if bag != null:
			return bag
		return InventoryIconHelper.category_icon_for_item_type("material")
	match n:
		"极限装备":
			return InventoryIconHelper.category_icon_for_inventory_item({"name": "极限装备礼包"})
		"套装强化石":
			return InventoryIconHelper.category_icon_for_inventory_item({"name": "套装强化石"})
		"宠物技能书":
			return InventoryIconHelper.category_icon_for_item_type("pet_skill_book")
		"世界boss宠":
			return InventoryIconHelper.category_icon_for_item_type("pet_egg")
		_:
			var tex: = InventoryIconHelper.category_icon_for_inventory_item({"name": n})
			if tex != null:
				return tex
			return InventoryIconHelper.category_icon_for_item_type("gift")

static func _create_loot_showcase_panel(cfg: Dictionary) -> PanelContainer:
	var drop_panel: = _create_section_panel()

	var drop_vbox: = VBoxContainer.new()
	drop_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drop_vbox.add_theme_constant_override("separation", 10)
	drop_panel.add_child(drop_vbox)

	var drop_title: = Label.new()
	drop_title.name = "LootShowcaseTitle"
	drop_title.text = "🎁 %s 可能获得" % WorldBossConfig.GIFT_ITEM_NAME
	drop_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	drop_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drop_title.add_theme_font_size_override("font_size", 17)
	drop_title.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
	drop_vbox.add_child(drop_title)

	var icons_row: = HFlowContainer.new()
	icons_row.name = "LootIconsRow"
	icons_row.alignment = FlowContainer.ALIGNMENT_CENTER
	icons_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icons_row.add_theme_constant_override("h_separation", 8)
	icons_row.add_theme_constant_override("v_separation", 8)
	drop_vbox.add_child(icons_row)

	_fill_loot_icons_row(icons_row, cfg)
	return drop_panel

static func _fill_loot_icons_row(icons_row: Control, cfg: Dictionary) -> void :
	if icons_row != null:
		for child in icons_row.get_children():
			child.queue_free()
	var names: = _loot_display_names(cfg)
	if icons_row == null:
		return
	for n in names:
		var cell: = VBoxContainer.new()
		cell.add_theme_constant_override("separation", 4)
		cell.custom_minimum_size = Vector2(LOOT_ICON_CELL_W, 0)
		cell.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var icon: = TextureRect.new()
		icon.custom_minimum_size = Vector2(44, 44)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.texture = _loot_item_icon_tex(n)
		cell.add_child(icon)
		var lab: = Label.new()
		lab.text = n
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lab.add_theme_font_size_override("font_size", 12)
		lab.add_theme_color_override("font_color", Color(0.8, 0.82, 0.7))
		cell.add_child(lab)
		icons_row.add_child(cell)

static func _refresh_loot_showcase(root: Control, cfg: Dictionary) -> void :
	var loot_panel: PanelContainer = _find_node(root, "LootShowcasePanel") as PanelContainer
	if loot_panel == null:
		return
	var icons_row: Control = _find_node(loot_panel, "LootIconsRow") as Control
	_fill_loot_icons_row(icons_row, cfg)

static func _apply_boss_panel_border(root: Control, boss_id: String) -> void :
	var boss_panel: PanelContainer = _find_node(root, "BossPanel") as PanelContainer
	if boss_panel == null:
		return

	var style: = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_width_left = 0
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	style.content_margin_left = PANEL_INNER_MARGIN
	style.content_margin_right = PANEL_INNER_MARGIN
	style.content_margin_top = PANEL_INNER_MARGIN
	style.content_margin_bottom = PANEL_INNER_MARGIN
	boss_panel.add_theme_stylebox_override("panel", style)

static func _apply_boss_visual(host: Control, boss_name: Label, boss_id: String, boss_element_label: Label = null) -> void :
	if boss_id.is_empty():
		return
	if host != null:
		for child in host.get_children():
			child.queue_free()
		var side: = int(host.custom_minimum_size.x)
		if side <= 0:
			side = _boss_side_px()
		var widget: = PetIdleDisplay.create_avatar_widget(boss_id, Vector2(side, side))
		if widget != null:
			host.add_child(widget)
	var display_name: = str(WorldBossConfig.BOSS_DISPLAY_NAMES.get(boss_id, boss_id))
	var elem: = WorldBossConfig.boss_element(boss_id)
	var elem_color: = WorldBossConfig.boss_element_color(boss_id)
	if boss_element_label != null:
		if elem.is_empty():
			boss_element_label.text = ""
		else:
			boss_element_label.text = "五行属性: %s" % elem
			boss_element_label.add_theme_color_override("font_color", elem_color)
	if boss_name != null:
		boss_name.text = "今日boss: %s" % display_name
		boss_name.add_theme_color_override("font_color", elem_color)

static func _api_ok(data: Dictionary) -> bool:
	return bool(data.get("ok", false)) or bool(data.get("success", false))

static func _resolve_boss_pet_id(root: Control, data: Dictionary, cfg: Dictionary) -> String:
	var from_api: = str(data.get("bossPetId", data.get("boss_pet_id", ""))).strip_edges()
	if not from_api.is_empty():
		return from_api
	var event_date: = str(data.get("eventDate", data.get("event_date", ""))).strip_edges()
	if root != null and root.has_meta("wb_boss_pet_id"):
		var cached: = str(root.get_meta("wb_boss_pet_id", "")).strip_edges()
		if not cached.is_empty():
			return cached
	return WorldBossConfig.pick_daily_boss_pet_id(event_date, cfg)

static func _apply_status(root: Control, data: Dictionary) -> void :
	var activity_label: Label = _find_node(root, "ActivityLabel") as Label
	var status_label: Label = _find_node(root, "StatusLabel") as Label
	var remaining_stat: Label = _find_node(root, "RemainingStatValue") as Label
	var damage_stat: Label = _find_node(root, "DamageStatValue") as Label
	var rank_stat: Label = _find_node(root, "RankStatValue") as Label
	var boss_host: Control = _find_node(root, "BossSpriteHost") as Control
	var boss_element_label: Label = _find_node(root, "BossElementLabel") as Label
	var boss_name: Label = _find_node(root, "BossNameLabel") as Label
	var challenge_btn: Button = _find_node(root, "ChallengeBtn") as Button
	var rank_list: VBoxContainer = _find_node(root, "RankList") as VBoxContainer

	var cfg: Dictionary = data.get("config", {}) if data.get("config") is Dictionary else {}
	root.set_meta("wb_rules_cfg", cfg)
	_refresh_loot_showcase(root, cfg)

	var boss_id: = _resolve_boss_pet_id(root, data, cfg)
	if not boss_id.is_empty():
		root.set_meta("wb_boss_pet_id", boss_id)
	_apply_boss_visual(boss_host, boss_name, boss_id, boss_element_label)
	_apply_boss_panel_border(root, boss_id)

	var api_ok: = _api_ok(data)
	var max_attempts: = int(cfg.get("dailyMaxAttempts", WorldBossConfig.FALLBACK_DAILY_MAX_ATTEMPTS))
	var remaining: = int(data.get("remainingAttempts", data.get("remaining_attempts", -1)))
	if remaining < 0:
		remaining = max_attempts
	var my_damage: = int(data.get("myTotalDamage", data.get("my_total_damage", 0)))
	var my_rank: = int(data.get("myRank", data.get("my_rank", 0)))

	var in_window: = false
	if api_ok and (data.has("inChallengeWindow") or data.has("in_challenge_window")):
		in_window = bool(data.get("inChallengeWindow", data.get("in_challenge_window", false)))
	else:
		in_window = WorldBossConfig.is_in_challenge_window(cfg)

	var feature_on: = bool(data.get("featureEnabled", data.get("feature_enabled", true))) if api_ok else true

	var start_h: = int(cfg.get("challengeStartHour", WorldBossConfig.FALLBACK_CHALLENGE_START_HOUR))
	var start_m: = int(cfg.get("challengeStartMinute", WorldBossConfig.FALLBACK_CHALLENGE_START_MINUTE))
	var end_h: = int(cfg.get("challengeEndHour", WorldBossConfig.FALLBACK_CHALLENGE_END_HOUR))
	var end_m: = int(cfg.get("challengeEndMinute", WorldBossConfig.FALLBACK_CHALLENGE_END_MINUTE))

	if activity_label != null:
		if in_window:
			activity_label.text = "今日 %02d:%02d–%02d:%02d 开放中" % [start_h, start_m, end_h, end_m]
			activity_label.add_theme_color_override("font_color", Color(0.35, 0.9, 0.55))
		else:
			activity_label.text = "当前不在活动时间"
			activity_label.add_theme_color_override("font_color", Color(0.631, 0.611, 0.564))

	if remaining_stat != null:
		remaining_stat.text = str(remaining)
	if damage_stat != null:
		damage_stat.text = _fmt_num(my_damage)
	if rank_stat != null:
		rank_stat.text = "100+" if my_rank <= 0 or my_rank > 100 else str(my_rank)

	if status_label != null:
		status_label.text = ""
		if not api_ok:
			var err: = str(data.get("error", "")).strip_edges()
			if not err.is_empty():
				status_label.text = "排行同步失败：%s" % err

	if challenge_btn != null:
		var challenge_row: Control = _find_node(root, "ChallengeRow") as Control
		var pending: = bool(root.get_meta("wb_challenge_pending", false))

		var show_challenge: = feature_on and in_window
		if challenge_row != null:
			challenge_row.visible = show_challenge
		if show_challenge:
			if pending:
				challenge_btn.disabled = true
				challenge_btn.text = "开战请求中..."
			else:
				challenge_btn.disabled = remaining <= 0
				challenge_btn.text = "今日次数已用完" if remaining <= 0 else "挑战"

	var ranking: Array = data.get("ranking", []) if data.get("ranking") is Array else []
	root.set_meta("wb_ranking_cache", ranking)
	_populate_ranking(rank_list, ranking, RANK_PREVIEW_LIMIT)

static func _populate_ranking(rank_list: VBoxContainer, ranking: Array, limit: int) -> void :
	if rank_list == null:
		return
	for child in rank_list.get_children():
		child.queue_free()
	if ranking.is_empty():
		var empty: = Label.new()
		empty.text = "暂无排名"
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.add_theme_color_override("font_color", Color(0.631, 0.611, 0.564))
		empty.add_theme_font_size_override("font_size", 13)
		rank_list.add_child(empty)
		_enable_touch_drag_passthrough(rank_list)
		return
	var shown: = 0
	for entry in ranking:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		if shown >= limit:
			break
		var rank_no: = int(entry.get("rank", shown + 1))
		var player_name: = str(entry.get("playerName", entry.get("player_name", "未知")))
		var dmg: = int(entry.get("totalDamage", entry.get("total_damage", 0)))

		var row_panel: = PanelContainer.new()
		row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if shown < 3:
			var rank_style: = UIStyle.create_rank_style(shown)
			rank_style.content_margin_left = 6
			rank_style.content_margin_right = 6
			rank_style.content_margin_top = 5
			rank_style.content_margin_bottom = 5
			row_panel.add_theme_stylebox_override("panel", rank_style)
		else:
			var plain_style: = StyleBoxFlat.new()
			plain_style.bg_color = Color(0.060, 0.068, 0.069, 0.35)
			plain_style.corner_radius_top_left = 0
			plain_style.corner_radius_top_right = 0
			plain_style.corner_radius_bottom_left = 0
			plain_style.corner_radius_bottom_right = 0
			plain_style.content_margin_left = 6
			plain_style.content_margin_right = 6
			plain_style.content_margin_top = 5
			plain_style.content_margin_bottom = 5
			row_panel.add_theme_stylebox_override("panel", plain_style)

		var row_h: = HBoxContainer.new()
		row_h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_h.add_theme_constant_override("separation", 4)
		row_panel.add_child(row_h)

		if shown == 0:
			row_h.add_child(_make_tex_rect(WB_BADGE_GOLD_PATH, Vector2(22, 22)))
		elif shown == 1:
			row_h.add_child(_make_tex_rect(WB_BADGE_SILVER_PATH, Vector2(22, 22)))
		elif shown == 2:
			row_h.add_child(_make_tex_rect(WB_BADGE_BRONZE_PATH, Vector2(22, 22)))

		var inner: = VBoxContainer.new()
		inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		inner.add_theme_constant_override("separation", 2)
		row_h.add_child(inner)

		var name_label: = Label.new()
		name_label.text = "%d. %s" % [rank_no, player_name]
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.add_theme_font_size_override("font_size", 13)
		name_label.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
		inner.add_child(name_label)

		var dmg_label: = Label.new()
		dmg_label.text = "伤害数据：%s" % _fmt_num(dmg)
		dmg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dmg_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dmg_label.add_theme_font_size_override("font_size", 12)
		dmg_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
		inner.add_child(dmg_label)

		rank_list.add_child(row_panel)
		shown += 1
	_enable_touch_drag_passthrough(rank_list)

static func _on_rank_more_pressed(game_manager, root: Control) -> void :
	_show_ranking_popup_async(game_manager, root)

static func _open_rules_window(parent: Control) -> void :
	if parent == null or not is_instance_valid(parent):
		return
	var cfg: Dictionary = {}
	var cached: Variant = parent.get_meta("wb_rules_cfg", {})
	if cached is Dictionary:
		cfg = cached
	var rules_text: = WorldBossConfig.build_rules_text(cfg)

	var popup: = Window.new()
	popup.title = ""
	popup.size = Vector2i(520, 640)
	popup.transparent = true
	popup.borderless = true
	popup.unresizable = true
	popup.close_requested.connect( func():
		if is_instance_valid(popup):
			popup.queue_free()
	)

	var main_panel: = Panel.new()
	main_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_panel.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	popup.add_child(main_panel)

	var vbox: = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 12)
	main_panel.add_child(vbox)

	var title: = Label.new()
	title.text = "规则说明"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(title)

	var scroll: = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.scroll_deadzone = 20
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(scroll)

	var body: = Label.new()
	body.text = rules_text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("font_size", 16)
	body.add_theme_color_override("font_color", Color(0.894, 0.864, 0.803))
	scroll.add_child(body)

	var close_row: = CenterContainer.new()
	vbox.add_child(close_row)
	var close_btn: = Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(120, 42)
	close_btn.add_theme_font_size_override("font_size", 18)
	UIStyle.apply_button_style(close_btn)
	close_btn.pressed.connect( func():
		if is_instance_valid(popup):
			popup.queue_free()
	)
	close_row.add_child(close_btn)

	WindowHost.attach_window_and_popup_centered(popup, parent)

static func _show_ranking_popup_async(game_manager, root: Control) -> void :
	var ranking: Array = []
	if game_manager != null and game_manager.network != null:
		var res: Dictionary = await game_manager.network.request_world_boss_ranking(RANK_POPUP_LIMIT)
		if _api_ok(res):
			var rows: Variant = res.get("ranking", [])
			if rows is Array:
				ranking = rows
	if ranking.is_empty() and root != null:
		var cached: Variant = root.get_meta("wb_ranking_cache", [])
		if cached is Array:
			ranking = cached
	_open_ranking_window(root, ranking)

static func _open_ranking_window(parent: Control, ranking: Array) -> void :
	if parent == null or not is_instance_valid(parent):
		return
	var popup: = Window.new()
	popup.title = ""
	popup.size = Vector2i(520, 640)
	popup.transparent = true
	popup.borderless = true
	popup.unresizable = true
	popup.close_requested.connect( func():
		if is_instance_valid(popup):
			popup.queue_free()
	)

	var main_panel: = Panel.new()
	main_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_panel.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	popup.add_child(main_panel)

	var vbox: = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 12)
	main_panel.add_child(vbox)

	var title: = Label.new()
	title.text = "世界boss当日排名（前%d名）" % RANK_POPUP_LIMIT
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(title)

	var scroll: = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.scroll_deadzone = 20
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(scroll)

	var list: = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	list.add_theme_constant_override("separation", 2)
	scroll.add_child(list)

	_add_ranking_table_header(list)
	_populate_ranking_popup(list, ranking, RANK_POPUP_LIMIT)
	_enable_touch_drag_passthrough(list)

	var close_row: = CenterContainer.new()
	vbox.add_child(close_row)
	var close_btn: = Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(120, 42)
	UIStyle.apply_button_style(close_btn)
	close_btn.pressed.connect( func():
		if is_instance_valid(popup):
			popup.queue_free()
	)
	close_row.add_child(close_btn)

	WindowHost.attach_window_and_popup_centered(popup, parent)

static func _create_table_row_style(odd: bool) -> StyleBoxFlat:
	var style: = StyleBoxFlat.new()
	style.bg_color = Color(0.072, 0.080, 0.079, 0.55) if odd else Color(0.066, 0.074, 0.074, 0.4)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.content_margin_left = 6
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

static func _load_rank_avatar_texture(character_id: int) -> Texture2D:
	var cid: = PlayerCharacterConfig.normalize_id(character_id)
	var path: = PlayerCharacterConfig.get_avatar_tx_path(cid)
	if not ResourceLoader.exists(path):
		path = PlayerCharacterConfig.get_avatar_tx_path(0)
	return load(path) as Texture2D

static func _create_rank_avatar_cell(tex: Texture2D) -> Control:
	var frame: = Panel.new()
	frame.custom_minimum_size = Vector2(RANK_AVATAR_SIZE, RANK_AVATAR_SIZE)
	frame.clip_contents = true
	var style: = UIStyle.create_item_style()
	style.bg_color = Color(0.072, 0.080, 0.079, 1.0)
	style.border_color = UIStyle.COLORS.item_border
	frame.add_theme_stylebox_override("panel", style)
	var inner_size: = RANK_AVATAR_SIZE - 4
	var avatar: = TextureRect.new()
	avatar.position = Vector2(2, 2)
	avatar.custom_minimum_size = Vector2(inner_size, inner_size)
	avatar.size = Vector2(inner_size, inner_size)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar.texture = tex
	frame.add_child(avatar)
	return frame

static func _add_ranking_table_header(parent: VBoxContainer) -> void :
	var header_panel: = PanelContainer.new()
	var header_style: = StyleBoxFlat.new()
	header_style.bg_color = Color(0.054, 0.063, 0.064, 0.85)
	header_style.corner_radius_top_left = 0
	header_style.corner_radius_top_right = 0
	header_style.corner_radius_bottom_left = 0
	header_style.corner_radius_bottom_right = 0
	header_style.content_margin_left = 6
	header_style.content_margin_right = 8
	header_style.content_margin_top = 8
	header_style.content_margin_bottom = 8
	header_panel.add_theme_stylebox_override("panel", header_style)
	header_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(header_panel)
	_add_ranking_table_row(header_panel, "名次", "玩家昵称", "伤害数据", true, true, 0)

static func _add_ranking_table_row(
	parent: Node, 
	rank_text: String, 
	name_text: String, 
	damage_text: String, 
	is_header: bool = false, 
	odd_row: bool = false, 
	character_id: int = 0
) -> void :
	var row: = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 6)
	if not is_header:
		var row_panel: = PanelContainer.new()
		row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_panel.add_theme_stylebox_override("panel", _create_table_row_style(odd_row))
		row_panel.add_child(row)
		parent.add_child(row_panel)
	else:
		parent.add_child(row)

	var rank_col: = Label.new()
	rank_col.custom_minimum_size.x = RANK_NUM_COL_WIDTH
	rank_col.text = rank_text
	rank_col.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	rank_col.add_theme_font_size_override("font_size", 14 if is_header else 13)
	if is_header:
		rank_col.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
	else:
		rank_col.add_theme_color_override("font_color", Color(0.863, 0.836, 0.774))
	row.add_child(rank_col)

	if is_header:
		var avatar_header: = Label.new()
		avatar_header.custom_minimum_size = Vector2(RANK_AVATAR_SIZE, RANK_AVATAR_SIZE)
		avatar_header.text = "头像"
		avatar_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		avatar_header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		avatar_header.add_theme_font_size_override("font_size", 14)
		avatar_header.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
		row.add_child(avatar_header)
	else:
		row.add_child(_create_rank_avatar_cell(_load_rank_avatar_texture(character_id)))

	var name_col: = Label.new()
	name_col.text = name_text
	name_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_col.clip_text = true
	name_col.add_theme_font_size_override("font_size", 14 if is_header else 13)
	if is_header:
		name_col.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
	else:
		name_col.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
	row.add_child(name_col)

	var dmg_col: = Label.new()
	dmg_col.custom_minimum_size.x = 96
	dmg_col.text = damage_text
	dmg_col.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dmg_col.add_theme_font_size_override("font_size", 14 if is_header else 13)
	if is_header:
		dmg_col.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
	else:
		dmg_col.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
	row.add_child(dmg_col)

static func _populate_ranking_popup(rank_list: VBoxContainer, ranking: Array, limit: int) -> void :
	if rank_list == null:
		return
	for child in rank_list.get_children():
		child.queue_free()
	if ranking.is_empty():
		var empty: = Label.new()
		empty.text = "暂无排名数据"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color", Color(0.631, 0.611, 0.564))
		empty.add_theme_font_size_override("font_size", 14)
		rank_list.add_child(empty)
		return
	var shown: = 0
	for entry in ranking:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		if shown >= limit:
			break
		var rank_no: = int(entry.get("rank", shown + 1))
		var player_name: = str(entry.get("playerName", entry.get("player_name", "未知")))
		var dmg: = int(entry.get("totalDamage", entry.get("total_damage", 0)))
		var character_id: = int(entry.get("characterId", entry.get("character_id", 0)))
		_add_ranking_table_row(
			rank_list, 
			str(rank_no), 
			player_name, 
			_fmt_num(dmg), 
			false, 
			shown % 2 == 0, 
			character_id
		)
		shown += 1

static func _fmt_num(n: int) -> String:
	if n >= 100000000:
		return "%.2f亿" % (float(n) / 100000000.0)
	if n >= 10000:
		return "%.1f万" % (float(n) / 10000.0)
	return str(n)

static func set_challenge_pending(root: Control, pending: bool) -> void :
	if root == null or not is_instance_valid(root):
		return
	root.set_meta("wb_challenge_pending", pending)
	var challenge_btn: Button = _find_node(root, "ChallengeBtn") as Button
	var challenge_row: Control = _find_node(root, "ChallengeRow") as Control
	if challenge_btn == null:
		return
	if pending:
		if challenge_row != null:
			challenge_row.visible = true
		challenge_btn.disabled = true
		challenge_btn.text = "开战请求中..."

static func set_challenge_result(root: Control, success: bool, err: String = "") -> void :
	if root == null or not is_instance_valid(root):
		return
	root.set_meta("wb_challenge_pending", false)
	var challenge_btn: Button = _find_node(root, "ChallengeBtn") as Button
	var status_label: Label = _find_node(root, "StatusLabel") as Label
	if success:
		if challenge_btn != null:
			challenge_btn.text = "战斗中..."
		return
	if status_label != null:
		status_label.text = "开战失败：%s" % err if not err.is_empty() else "开战失败"

	if root.has_meta("game_manager"):
		var gm = root.get_meta("game_manager")
		if gm != null and gm.has_method("refresh_world_boss_ui_panel"):
			gm.refresh_world_boss_ui_panel(root)
			return
	if challenge_btn != null:
		challenge_btn.disabled = false
		challenge_btn.text = "挑战"
