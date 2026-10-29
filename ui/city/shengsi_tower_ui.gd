extends Control
class_name ShengsiTowerUI



const UIStyle = preload("res://scripts/ui_style.gd")
const WindowHost = preload("res://scripts/ui/window_host.gd")
const PlayerCharacterConfig = preload("res://scripts/player_character_config.gd")
const BG_TOWER_PATH: = "res://assets/ui/shengsi_tower/bg_tower.jpg"
const FEED_POLL_SEC: = 5.0
const HEAVY_POLL_EVERY: = 4
const ROOM_LIST_POLL_EVERY: = 2
const MISSING_MEMBER_POLL_MS: = 2000
const FEED_MAX_LINES: = 40
const MEMBER_SLOT_WIDTH: = 120
const MEMBER_AVATAR_FRAME_SIZE: = 64
const COLOR_TITLE: = Color(1.0, 0.88, 0.45)
const COLOR_FEED: = Color(0.072, 0.080, 0.079)
const COLOR_MY_FLOOR: = Color(0.55, 1.0, 0.7)
const COLOR_MUTED: = Color(0.072, 0.080, 0.079)
const PIN_SNAPSHOT_REQUIRED_MSG: = "请先在生死塔界面更新人物与出战宠快照"
const SNAPSHOT_PIN_COOLDOWN_MS: = 3000

var game_manager = null
var _title_label: Label
var _time_label: Label
var _my_floor_hint: Label
var _hub_layer: Control
var _hub_scroll: ScrollContainer
var _hub_inner: Control
var _hub_bg: TextureRect
var _hub_layout_busy: = false
var _floor_layer: Control
var _floor_title: Label
var _floor_info: Label
var _champion_box: VBoxContainer
var _lobby_box: VBoxContainer
var _teams_box: VBoxContainer
var _prep_box: VBoxContainer
var _action_box: VBoxContainer
var _feed_box: VBoxContainer
var _floor_scroll: ScrollContainer
var _floor_body: VBoxContainer
var _closed_overlay: Label
var _floor_hotspots: Dictionary = {}
var _poll_timer: Timer
var _last_feed_id: int = 0
var _overview: Dictionary = {}
var _overview_ok: = false
var _heavy_poll_n: = 0
var _floor_data: Dictionary = {}
var _match_data: Dictionary = {}
var _room_list_data: Dictionary = {}
var _room_list_poll_n: = 0
var _last_missing_members_poll_ms: = 0
var _active_floor: int = 0
var _clock_skew_sec: float = 0.0
var _signals_connected: bool = false
var _auto_battle_match_id: int = 0
var _matchup_log_requested_id: int = 0
var _stance_popup_match_id: int = 0
var _battle_win: Window = null
var _selected_stance: String = "balanced"
var _local_ready: bool = false
var _local_ready_match_id: int = 0
var _replay_opened_match_id: int = 0
var _battles_list_cache: Dictionary = {}
var _match_replay_cache: Dictionary = {}
var _cached_event_key: String = ""
var _pending_replay_match_id: int = 0
var _pending_replay_my_entry_id: int = 0
var _flow_overlay: Control
var _flow_dim: ColorRect
var _flow_card: Panel
var _flow_title: Label
var _flow_count: Label
var _flow_hint: Label
var _flow_wait_mode: = false
var _prep_intro_playing_id: int = 0
var _prep_intro_done_id: int = 0
var _prep_intro_tween: Tween
var _snapshot_pin_pending: = false
var _snapshot_pin_cooldown_until_ms: = 0

static func create_fullscreen(manager) -> ShengsiTowerUI:
	var ui: = ShengsiTowerUI.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.set_game_manager(manager)
	return ui

func set_game_manager(manager) -> void :
	game_manager = manager
	_ensure_signals()
	if is_inside_tree():
		_request_window()
		_request_overview()

func _ready() -> void :
	_build_ui()
	_ensure_signals()
	_poll_timer = Timer.new()
	_poll_timer.wait_time = FEED_POLL_SEC
	_poll_timer.autostart = false
	_poll_timer.timeout.connect(_on_poll_tick)
	add_child(_poll_timer)
	_refresh_my_floor_hint()
	_request_window()
	_request_overview()
	_sync_poll_timer()
	set_process(false)

func _notification(what: int) -> void :
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		_sync_poll_timer()
		if is_visible_in_tree():
			_request_window()
			_request_overview()
	elif what == NOTIFICATION_PREDELETE:
		_clear_public_battle_cache()

func _sync_poll_timer() -> void :
	if _poll_timer == null:
		return
	if is_visible_in_tree() and not _event_fully_finished():
		if _poll_timer.is_stopped():
			_poll_timer.start()
	else:
		_poll_timer.stop()

func _ensure_signals() -> void :
	if _signals_connected or game_manager == null:
		return
	var net = game_manager.network if game_manager.get("network") else null
	if net == null:
		return
	if net.has_signal("shengsi_tower_overview_loaded") and not net.shengsi_tower_overview_loaded.is_connected(_on_overview):
		net.shengsi_tower_overview_loaded.connect(_on_overview)
	if net.has_signal("shengsi_tower_window_loaded") and not net.shengsi_tower_window_loaded.is_connected(_on_window):
		net.shengsi_tower_window_loaded.connect(_on_window)
	if net.has_signal("shengsi_tower_window_failed") and not net.shengsi_tower_window_failed.is_connected(_on_window_fail):
		net.shengsi_tower_window_failed.connect(_on_window_fail)
	if net.has_signal("shengsi_tower_feed_loaded") and not net.shengsi_tower_feed_loaded.is_connected(_on_feed):
		net.shengsi_tower_feed_loaded.connect(_on_feed)
	if net.has_signal("shengsi_tower_floor_loaded") and not net.shengsi_tower_floor_loaded.is_connected(_on_floor):
		net.shengsi_tower_floor_loaded.connect(_on_floor)
	if net.has_signal("shengsi_tower_floor_failed") and not net.shengsi_tower_floor_failed.is_connected(_on_floor_fail):
		net.shengsi_tower_floor_failed.connect(_on_floor_fail)
	if net.has_signal("shengsi_tower_matchup_loaded") and not net.shengsi_tower_matchup_loaded.is_connected(_on_matchup):
		net.shengsi_tower_matchup_loaded.connect(_on_matchup)
	if net.has_signal("shengsi_tower_action_success") and not net.shengsi_tower_action_success.is_connected(_on_action_ok):
		net.shengsi_tower_action_success.connect(_on_action_ok)
	if net.has_signal("shengsi_tower_action_failed") and not net.shengsi_tower_action_failed.is_connected(_on_action_fail):
		net.shengsi_tower_action_failed.connect(_on_action_fail)
	if net.has_signal("shengsi_tower_my_battles_loaded") and not net.shengsi_tower_my_battles_loaded.is_connected(_on_my_battles):
		net.shengsi_tower_my_battles_loaded.connect(_on_my_battles)
	if net.has_signal("shengsi_tower_my_battles_failed") and not net.shengsi_tower_my_battles_failed.is_connected(_on_my_battles_fail):
		net.shengsi_tower_my_battles_failed.connect(_on_my_battles_fail)
	if net.has_signal("shengsi_tower_floor_battles_loaded") and not net.shengsi_tower_floor_battles_loaded.is_connected(_on_floor_battles):
		net.shengsi_tower_floor_battles_loaded.connect(_on_floor_battles)
	if net.has_signal("shengsi_tower_floor_battles_failed") and not net.shengsi_tower_floor_battles_failed.is_connected(_on_floor_battles_fail):
		net.shengsi_tower_floor_battles_failed.connect(_on_floor_battles_fail)
	if net.has_signal("shengsi_tower_match_loaded") and not net.shengsi_tower_match_loaded.is_connected(_on_match_detail):
		net.shengsi_tower_match_loaded.connect(_on_match_detail)
	if net.has_signal("shengsi_tower_match_failed") and not net.shengsi_tower_match_failed.is_connected(_on_match_detail_fail):
		net.shengsi_tower_match_failed.connect(_on_match_detail_fail)
	if net.has_signal("shengsi_tower_room_list_loaded") and not net.shengsi_tower_room_list_loaded.is_connected(_on_room_list):
		net.shengsi_tower_room_list_loaded.connect(_on_room_list)
	if net.has_signal("shengsi_tower_overview_failed") and not net.shengsi_tower_overview_failed.is_connected(_on_overview_fail):
		net.shengsi_tower_overview_failed.connect(_on_overview_fail)
	_signals_connected = true

func _tex_ok(tex: Texture2D) -> bool:
	return tex != null and tex.get_width() > 0 and tex.get_height() > 0

func _load_png_tex(path: String) -> Texture2D:
	if path.is_empty():
		return null
	var loaded: = load(path) as Texture2D
	if _tex_ok(loaded):
		return loaded
	var abs_path: = ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(abs_path):
		var img: = Image.load_from_file(abs_path)
		if img != null and not img.is_empty():
			var from_disk: = ImageTexture.create_from_image(img)
			if _tex_ok(from_disk):
				return from_disk
	push_warning("[ShengsiTower] 背景图加载失败: %s" % path)
	return null

func _ensure_hub_bg() -> void :
	if _hub_bg == null:
		return
	if not _tex_ok(_hub_bg.texture):
		_hub_bg.texture = _load_png_tex(BG_TOWER_PATH)
	call_deferred("_layout_hub_tower")

func _floor_cn(floor: int) -> String:
	match floor:
		1:
			return "一"
		2:
			return "二"
		3:
			return "三"
		4:
			return "四"
		5:
			return "五"
		_:
			return str(floor)

func _portal_color(floor: int) -> Color:
	match floor:
		1:
			return Color(0.072, 0.080, 0.079)
		2:
			return Color(0.45, 0.95, 0.55)
		3:
			return Color(0.072, 0.080, 0.079)
		4:
			return Color(0.072, 0.080, 0.079)
		5:
			return Color(1.0, 0.58, 0.18)
		_:
			return Color(0.9, 0.9, 0.9)

func _default_reinc_row(floor: int) -> Dictionary:
	match floor:
		1:
			return {"minReincarnation": 0, "maxReincarnation": 99}
		2:
			return {"minReincarnation": 100, "maxReincarnation": 199}
		3:
			return {"minReincarnation": 200, "maxReincarnation": 299}
		4:
			return {"minReincarnation": 300, "maxReincarnation": 399}
		5:
			return {"minReincarnation": 400, "maxReincarnation": null}
		_:
			return {"minReincarnation": 0, "maxReincarnation": null}

func _reinc_hint_text(row: Dictionary) -> String:
	var mn: = int(row.get("minReincarnation", 0))
	if row.has("maxReincarnation") and row.get("maxReincarnation") != null:
		return "投胎数:%d-%d" % [mn, int(row.get("maxReincarnation", 0))]
	return "投胎数:%d以上" % mn

func _layout_hub_tower() -> void :

	if _hub_layout_busy:
		return
	if _hub_layer == null or _hub_inner == null:
		return
	var w: = _hub_layer.size.x
	var vh: = _hub_layer.size.y
	if w < 8.0 or vh < 8.0:
		return
	var aspect: = 16.0 / 9.0
	if _hub_bg and _tex_ok(_hub_bg.texture):
		var tw: = float(_hub_bg.texture.get_width())
		if tw > 1.0:
			aspect = float(_hub_bg.texture.get_height()) / tw
	var h: = maxf(vh, w * aspect)
	var next: = Vector2(w, h)
	if _hub_inner.custom_minimum_size.distance_to(next) < 1.0:
		return
	_hub_layout_busy = true
	_hub_inner.custom_minimum_size = next
	_hub_layout_busy = false

func _build_ui() -> void :
	var panel: = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", UIStyle.create_panel_style())
	add_child(panel)

	var vbox: = UIStyle.create_base_vbox()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var header: = HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)

	_title_label = Label.new()
	_title_label.text = "生死塔"
	_title_label.add_theme_font_size_override("font_size", 22)
	_title_label.add_theme_color_override("font_color", COLOR_TITLE)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title_label)

	_time_label = Label.new()
	_time_label.text = "报名 --:--"
	_time_label.add_theme_font_size_override("font_size", 16)
	_time_label.add_theme_color_override("font_color", Color(1, 0.95, 0.7))
	header.add_child(_time_label)

	var rules_btn: = Button.new()
	rules_btn.text = "规则"
	rules_btn.custom_minimum_size = Vector2(72, 44)
	UIStyle.apply_button_style(rules_btn)
	TouchScrollUtils.bind_tap(rules_btn, _on_rules_pressed)
	header.add_child(rules_btn)

	_my_floor_hint = Label.new()
	_my_floor_hint.text = "我的层：--"
	_my_floor_hint.add_theme_font_size_override("font_size", 14)
	_my_floor_hint.add_theme_color_override("font_color", COLOR_MY_FLOOR)
	vbox.add_child(_my_floor_hint)

	_hub_layer = Control.new()
	_hub_layer.name = "HubLayer"
	_hub_layer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hub_layer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hub_layer.clip_contents = true
	vbox.add_child(_hub_layer)

	_hub_scroll = ScrollContainer.new()
	_hub_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hub_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_hub_layer.add_child(_hub_scroll)
	TouchScrollUtils.configure_scroll(_hub_scroll)

	_hub_inner = Control.new()
	_hub_inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hub_scroll.add_child(_hub_inner)
	TouchScrollUtils.bind_content_touch_scroll(_hub_scroll, _hub_inner)

	_hub_bg = TextureRect.new()
	_hub_bg.name = "ShengsiTowerBg"
	_hub_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hub_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hub_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hub_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var bg_tex: Texture2D = _load_png_tex(BG_TOWER_PATH)
	if bg_tex != null:
		_hub_bg.texture = bg_tex
	_hub_inner.add_child(_hub_bg)

	_closed_overlay = Label.new()
	_closed_overlay.text = "生死塔尚未开启"
	_closed_overlay.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_closed_overlay.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_closed_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_closed_overlay.add_theme_font_size_override("font_size", 22)
	_closed_overlay.add_theme_color_override("font_color", COLOR_TITLE)
	_closed_overlay.visible = false
	_closed_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hub_inner.add_child(_closed_overlay)


	var ranges: = [[0.04, 0.24], [0.22, 0.42], [0.4, 0.6], [0.58, 0.78], [0.76, 0.98]]
	var floors: = [5, 4, 3, 2, 1]
	for i in range(5):
		var fl: int = floors[i]
		var dy: = 20.0
		match fl:
			5:
				dy = 20.0
			4:
				dy = 22.0
			3:
				dy = 24.0
			2:
				dy = 26.0
			1:
				dy = 30.0
		var r: Array = ranges[i]
		var wrap: = Control.new()
		wrap.name = "FloorHot_%d" % fl
		wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
		wrap.anchor_left = 0.16
		wrap.anchor_right = 0.84
		wrap.anchor_top = float(r[0])
		wrap.anchor_bottom = float(r[1])
		wrap.offset_left = 0
		wrap.offset_right = 0
		wrap.offset_top = 0
		wrap.offset_bottom = 0
		var tap_fl: = fl
		TouchScrollUtils.bind_tap(wrap, func(): _open_floor(tap_fl))
		var enter_lbl: = Label.new()
		enter_lbl.name = "EnterLbl"
		enter_lbl.text = "进入"
		enter_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		enter_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		enter_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		enter_lbl.add_theme_font_size_override("font_size", 18)
		var col: = _portal_color(fl)
		enter_lbl.add_theme_color_override("font_color", col)
		enter_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		enter_lbl.add_theme_constant_override("outline_size", 4)
		enter_lbl.set_anchors_preset(Control.PRESET_CENTER)
		enter_lbl.offset_left = -40
		enter_lbl.offset_right = 40
		enter_lbl.offset_top = -16.0 + dy
		enter_lbl.offset_bottom = 16.0 + dy
		wrap.add_child(enter_lbl)
		var hint: = Label.new()
		hint.name = "ReincHint"
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.autowrap_mode = TextServer.AUTOWRAP_OFF
		hint.add_theme_font_size_override("font_size", 13)
		hint.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
		hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		hint.add_theme_constant_override("outline_size", 4)
		hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hint.text = _reinc_hint_text(_default_reinc_row(fl))
		hint.set_anchors_preset(Control.PRESET_CENTER)
		hint.offset_left = -90
		hint.offset_right = 90
		hint.offset_top = 18.0 + dy
		hint.offset_bottom = 40.0 + dy
		wrap.add_child(hint)
		_hub_inner.add_child(wrap)
		_floor_hotspots[fl] = wrap

	_hub_layer.resized.connect(_layout_hub_tower)
	_ensure_hub_bg()

	_floor_layer = VBoxContainer.new()
	_floor_layer.name = "FloorLayer"
	_floor_layer.visible = false
	_floor_layer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_floor_layer.add_theme_constant_override("separation", 6)
	vbox.add_child(_floor_layer)

	var floor_header: = HBoxContainer.new()
	floor_header.add_theme_constant_override("separation", 8)
	_floor_layer.add_child(floor_header)
	var back_btn: = Button.new()
	back_btn.text = "返回大厅"
	back_btn.custom_minimum_size = Vector2(110, 44)
	UIStyle.apply_button_style(back_btn)
	TouchScrollUtils.bind_tap(back_btn, _show_hub)
	floor_header.add_child(back_btn)
	_floor_title = Label.new()
	_floor_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_floor_title.add_theme_font_size_override("font_size", 18)
	_floor_title.add_theme_color_override("font_color", COLOR_TITLE)
	floor_header.add_child(_floor_title)

	var floor_stage: = Control.new()
	floor_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	floor_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	floor_stage.clip_contents = true
	_floor_layer.add_child(floor_stage)

	_floor_scroll = ScrollContainer.new()
	_floor_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_floor_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_floor_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_floor_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	floor_stage.add_child(_floor_scroll)
	TouchScrollUtils.configure_scroll(_floor_scroll)
	_build_flow_overlay(floor_stage)
	_floor_body = VBoxContainer.new()
	_floor_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_floor_body.add_theme_constant_override("separation", 10)
	_floor_scroll.add_child(_floor_body)
	TouchScrollUtils.bind_content_touch_scroll(_floor_scroll, _floor_body)

	_champion_box = VBoxContainer.new()
	_champion_box.add_theme_constant_override("separation", 6)
	_add_section_card(_floor_body, "本层塔主").add_child(_champion_box)

	_floor_info = Label.new()
	_floor_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_floor_info.add_theme_font_size_override("font_size", 14)
	_floor_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_floor_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_section_card(_floor_body, "本层概况").add_child(_floor_info)

	_lobby_box = VBoxContainer.new()
	_lobby_box.add_theme_constant_override("separation", 6)
	_add_section_card(_floor_body, "组队大厅").add_child(_lobby_box)

	_teams_box = VBoxContainer.new()
	_teams_box.add_theme_constant_override("separation", 6)
	_add_section_card(_floor_body, "本层报名队伍").add_child(_teams_box)

	_action_box = VBoxContainer.new()
	_action_box.add_theme_constant_override("separation", 6)
	_add_section_card(_floor_body, "报名操作").add_child(_action_box)

	_prep_box = VBoxContainer.new()
	_prep_box.add_theme_constant_override("separation", 6)
	_add_section_card(_floor_body, "临场准备").add_child(_prep_box)

	_feed_box = VBoxContainer.new()
	_feed_box.add_theme_constant_override("separation", 4)
	_add_section_card(_floor_body, "本层战况").add_child(_feed_box)
	_enable_floor_touch_scroll()

func _build_flow_overlay(host: Control) -> void :
	_flow_overlay = Control.new()
	_flow_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flow_overlay.visible = false
	_flow_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_flow_overlay.z_index = 40
	host.add_child(_flow_overlay)
	_flow_dim = ColorRect.new()
	_flow_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flow_dim.color = Color(0.631, 0.611, 0.564, 0.62)
	_flow_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_flow_overlay.add_child(_flow_dim)
	_flow_card = Panel.new()
	_flow_card.custom_minimum_size = Vector2(280, 120)
	_flow_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_flow_card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_flow_card.set_anchors_preset(Control.PRESET_CENTER)
	var gold: = StyleBoxFlat.new()
	gold.bg_color = Color(0.1, 0.08, 0.05, 0.97)
	gold.border_width_left = 3
	gold.border_width_top = 3
	gold.border_width_right = 3
	gold.border_width_bottom = 3
	gold.border_color = Color(1.0, 0.85, 0.3, 1)
	gold.corner_radius_top_left = 0
	gold.corner_radius_top_right = 0
	gold.corner_radius_bottom_left = 0
	gold.corner_radius_bottom_right = 0
	gold.shadow_color = Color(1.0, 0.75, 0.2, 0.28)
	gold.shadow_size = 12
	_flow_card.add_theme_stylebox_override("panel", gold)
	_flow_overlay.add_child(_flow_card)
	var box: = VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 18
	box.offset_right = -18
	box.offset_top = 16
	box.offset_bottom = -16
	box.add_theme_constant_override("separation", 10)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	_flow_card.add_child(box)
	_flow_title = Label.new()
	_flow_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_flow_title.add_theme_font_size_override("font_size", 22)
	_flow_title.add_theme_color_override("font_color", COLOR_TITLE)
	box.add_child(_flow_title)
	_flow_count = Label.new()
	_flow_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_flow_count.add_theme_font_size_override("font_size", 58)
	_flow_count.add_theme_color_override("font_color", Color(1.0, 0.86, 0.32))
	_flow_count.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.0, 0.85))
	_flow_count.add_theme_constant_override("outline_size", 6)
	_flow_count.visible = false
	box.add_child(_flow_count)
	_flow_hint = Label.new()
	_flow_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_flow_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_flow_hint.add_theme_font_size_override("font_size", 15)
	_flow_hint.add_theme_color_override("font_color", Color(0.92, 0.9, 0.82))
	box.add_child(_flow_hint)
	_layout_flow_card(false)

func _layout_flow_card(wait_mode: bool) -> void :
	if _flow_card == null:
		return
	if wait_mode:
		_flow_card.custom_minimum_size = Vector2(360, 240)
		_flow_card.offset_left = -190
		_flow_card.offset_right = 190
		_flow_card.offset_top = -140
		_flow_card.offset_bottom = 140
		if _flow_dim:
			_flow_dim.color = Color(0.631, 0.611, 0.564, 0.84)
	else:
		_flow_card.custom_minimum_size = Vector2(280, 120)
		_flow_card.offset_left = -140
		_flow_card.offset_right = 140
		_flow_card.offset_top = -60
		_flow_card.offset_bottom = 60
		if _flow_dim:
			_flow_dim.color = Color(0.631, 0.611, 0.564, 0.62)

func _show_flow_overlay(title: String, hint: String) -> void :
	if _flow_overlay == null:
		return
	_flow_wait_mode = false
	set_process(false)
	if _flow_count:
		_flow_count.visible = false
		_flow_count.modulate = Color(1, 1, 1, 1)
	_layout_flow_card(false)
	_flow_title.text = title
	_flow_hint.text = hint
	_flow_hint.visible = not hint.strip_edges().is_empty()
	_flow_overlay.visible = true
	_flow_overlay.modulate = Color(1, 1, 1, 1)

func _wait_remain_sec() -> int:
	var end_at: = int(_overview.get("signupEndAt", 0))
	if end_at <= 0:
		return 0
	return maxi(0, end_at - _now_unix())

func _refresh_wait_countdown_text() -> void :
	if not _flow_wait_mode or _flow_count == null:
		return
	var remain: = _wait_remain_sec()
	_flow_count.text = _fmt_remain(remain) if remain > 0 else "即将开战"
	_flow_hint.text = "战斗将启！既分高下，亦决生死"
	_flow_hint.visible = true
	if remain > 0 and remain <= 60:
		var pulse: = 0.55 + 0.45 * absf(sin(float(Time.get_ticks_msec()) / 180.0))
		_flow_count.modulate = Color(1.0, 0.45 + 0.4 * pulse, 0.18, 1.0)
	else:
		_flow_count.modulate = Color(1, 1, 1, 1)

func _show_wait_overlay() -> void :
	if _flow_overlay == null:
		return
	_flow_wait_mode = true
	_layout_flow_card(true)
	_flow_title.text = "已经入局，无路可退"
	if _flow_count:
		_flow_count.visible = true
	_refresh_wait_countdown_text()
	_flow_overlay.visible = true
	_flow_overlay.modulate = Color(1, 1, 1, 1)
	set_process(true)

func _hide_flow_overlay() -> void :
	_flow_wait_mode = false
	set_process(false)
	if _flow_count:
		_flow_count.modulate = Color(1, 1, 1, 1)
	if _flow_overlay:
		_flow_overlay.visible = false
		_flow_overlay.modulate = Color(1, 1, 1, 1)

func _process(_delta: float) -> void :
	if _flow_wait_mode:
		_refresh_wait_countdown_text()
		if _event_started_or_finished():
			_sync_flow_overlay({})

func _kill_prep_intro_tween() -> void :
	if _prep_intro_tween != null and is_instance_valid(_prep_intro_tween):
		_prep_intro_tween.kill()
	_prep_intro_tween = null
	_prep_intro_playing_id = 0

func _play_prep_intro_then_stance(md: Dictionary) -> void :
	var mid: = _match_id_of(md)
	if mid <= 0 or _is_round_ready(md):
		return
	if _find_popup_by_key("shengsi_stance"):
		return
	if mid == _prep_intro_done_id:
		_maybe_show_stance_popup(md, _match_data)
		return
	if mid == _prep_intro_playing_id:
		return
	_kill_prep_intro_tween()
	_prep_intro_playing_id = mid
	var overlay_on: = _flow_overlay != null and _flow_overlay.visible
	_show_flow_overlay("最后的准备", "请选你的战斗策略")
	if overlay_on:
		_flow_overlay.modulate = Color(1, 1, 1, 1)
		var hold: = create_tween()
		hold.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		hold.tween_interval(0.9)
		hold.tween_callback(_on_prep_intro_finished.bind(mid))
		_prep_intro_tween = hold
		return
	_flow_overlay.modulate = Color(1, 1, 1, 0)
	var tw: = create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_flow_overlay, "modulate", Color(1, 1, 1, 1), 0.4)
	tw.tween_interval(0.9)
	tw.tween_callback(_on_prep_intro_finished.bind(mid))
	_prep_intro_tween = tw

func _on_prep_intro_finished(mid: int) -> void :
	_prep_intro_tween = null
	_prep_intro_playing_id = 0
	_prep_intro_done_id = mid
	if _active_floor <= 0 or _floor_layer == null or not _floor_layer.visible:
		_hide_flow_overlay()
		return
	_hide_flow_overlay()
	var m = _match_data.get("match") if _match_data else null
	if m is Dictionary:
		_maybe_show_stance_popup(m, _match_data)

func _match_id_of(md: Dictionary) -> int:
	return int(md.get("matchId", md.get("id", 0)))

func _is_round_ready(md: Dictionary) -> bool:
	if bool(md.get("myReady", false)):
		return true
	return _local_ready and _match_id_of(md) == _local_ready_match_id

func _display_ready_count(md: Dictionary) -> int:
	var rc: = int(md.get("readyCount", 0))
	var total: = int(md.get("readyTotal", 4))
	if _local_ready and not bool(md.get("myReady", false)) and _match_id_of(md) == _local_ready_match_id:
		rc += 1
	return mini(rc, total) if total > 0 else rc

func _request_matchup_if_started() -> void :
	if _active_floor <= 0 or not _is_own_floor(_active_floor):
		return
	if not _event_started_or_finished():
		return
	if _event_fully_finished() or _floor_settled():
		return
	var n = _net()
	if n and n.has_method("get_shengsi_tower_round_matchup"):
		n.get_shengsi_tower_round_matchup(false)

func _request_matchup_with_log() -> void :
	var n = _net()
	if n and n.has_method("get_shengsi_tower_round_matchup"):
		n.get_shengsi_tower_round_matchup(true)

func _match_has_log_payload(md: Dictionary) -> bool:
	var log = md.get("battleLog")
	if log is Array and not (log as Array).is_empty():
		return true
	return false

func _ensure_matchup_log(md: Dictionary) -> bool:
	if _match_has_log_payload(md):
		return true
	if not bool(md.get("hasBattleLog", false)):
		return false
	var mid: = int(md.get("matchId", 0))
	if mid <= 0:
		return false
	if mid == _matchup_log_requested_id:
		return false
	_matchup_log_requested_id = mid
	_request_matchup_with_log()
	return false

func _event_key_of(data) -> String:
	if not (data is Dictionary):
		return ""
	return str(data.get("eventKey", "")).strip_edges()

func _is_new_event_round(prev_key: String, new_key: String) -> bool:
	if prev_key.is_empty() or new_key.is_empty():
		return false
	return prev_key != new_key

func _drop_local_caches_for_new_event() -> void :
	_room_list_data["rooms"] = []
	_floor_data = {}
	_match_data = {}
	_replay_opened_match_id = 0
	_matchup_log_requested_id = 0
	_kill_prep_intro_tween()
	_prep_intro_done_id = 0

func _clear_local_team_state_for_new_event() -> void :
	_overview["myRoom"] = {}
	_overview["myEntry"] = {}
	_drop_local_caches_for_new_event()

func _keep_local_signup_against_empty(incoming_entry, incoming_room, prev_entry, prev_room, prev_event_key: String = "", incoming_event_key: String = "") -> void :
	if _is_new_event_round(prev_event_key, incoming_event_key):
		return
	if ( not (incoming_entry is Dictionary) or incoming_entry.is_empty()) and prev_entry is Dictionary and not (prev_entry as Dictionary).is_empty():
		_overview["myEntry"] = prev_entry
	var prev_reg: = prev_room is Dictionary and str(prev_room.get("status", "")) == "registered"
	var inc_reg: = incoming_room is Dictionary and str(incoming_room.get("status", "")) == "registered"
	if prev_reg and not inc_reg and ( not (incoming_room is Dictionary) or incoming_room.is_empty()):
		_overview["myRoom"] = prev_room

func _sync_overlay_from_match_cache() -> void :
	var m = _match_data.get("match") if _match_data else null
	if m is Dictionary:
		_sync_flow_overlay(m)
	else:
		_sync_flow_overlay({})

func _request_round_matchup() -> void :
	var n = _net()
	if n and n.has_method("get_shengsi_tower_round_matchup"):
		n.get_shengsi_tower_round_matchup()

func _mark_local_ready_and_submit() -> void :
	var m = _match_data.get("match") if _match_data else null
	var md: Dictionary = m if m is Dictionary else {}
	_local_ready_match_id = _match_id_of(md)
	_local_ready = true
	_kill_prep_intro_tween()
	_prep_intro_done_id = _local_ready_match_id
	_show_flow_overlay("对阵就绪，静候入局", "等待其他玩家...")
	var n = _net()
	if n and n.has_method("shengsi_tower_round_ready"):
		n.shengsi_tower_round_ready()
	_request_round_matchup()
	_fill_prep(_match_data)

func _sync_flow_overlay(md: Dictionary) -> void :
	if game_manager != null and bool(game_manager.get("is_shengsi_tower_replay")):
		_hide_flow_overlay()
		return
	if _active_floor <= 0 or _floor_layer == null or not _floor_layer.visible:
		_hide_flow_overlay()
		return
	if not _is_own_floor(_active_floor):
		_hide_flow_overlay()
		return
	if _floor_settled():
		_hide_flow_overlay()
		return
	if _my_entry_on_floor().is_empty() and not _my_room_registered():
		_hide_flow_overlay()
		return
	var mid: = _match_id_of(md)
	if mid > 0 and mid == _replay_opened_match_id:
		_hide_flow_overlay()
		return
	if mid > 0 and mid == _prep_intro_playing_id:
		return
	var st: = str(md.get("status", ""))
	if st == "prep" and _is_round_ready(md):
		_show_flow_overlay("对阵就绪，静候入局", "等待其他玩家...")
		return
	if st == "prep":
		return
	if st in ["simulating", "playback", "done"]:
		_close_stance_popup()
	if st in ["simulating", "playback"]:
		var start_ts: = _parse_time_unix(md.get("playbackStartAt", ""))
		if st == "playback" and start_ts > 0 and _now_unix() < start_ts:
			_show_flow_overlay("正在进入战场…", "")
			return
		if st == "playback" and (md.get("battleLog") != null or bool(md.get("hasBattleLog", false))):
			_show_flow_overlay("正在进入战场…", "")
			return
		if st == "simulating":
			_show_flow_overlay("正在进入战场…", "")
			return
	if _event_started_or_finished() and not _event_fully_finished() and (md.is_empty() or st.is_empty()):
		_show_flow_overlay("正在匹配对手…", "")
		return
	if _should_show_wait_overlay():
		_show_wait_overlay()
		return
	_hide_flow_overlay()

func _should_show_wait_overlay() -> bool:
	if _active_floor <= 0 or _floor_layer == null or not _floor_layer.visible:
		return false
	if not _is_own_floor(_active_floor):
		return false
	if _my_entry_on_floor().is_empty() and not _my_room_registered():
		return false
	if _event_started_or_finished() or _event_fully_finished():
		return false
	return true

func _net():
	if game_manager and game_manager.get("network"):
		return game_manager.network
	return null

func _now_unix() -> int:
	return int(Time.get_unix_time_from_system() + _clock_skew_sec)

func _request_window() -> void :
	var n = _net()
	if n and n.has_method("get_shengsi_tower_window"):
		n.get_shengsi_tower_window()

func _request_overview() -> void :
	var n = _net()
	if n and n.has_method("get_shengsi_tower_overview"):
		n.get_shengsi_tower_overview()

func _request_feed() -> void :
	if _active_floor <= 0:
		return
	if _event_fully_finished() or _floor_settled():
		return
	var n = _net()
	if n and n.has_method("get_shengsi_tower_feed"):
		n.get_shengsi_tower_feed(0, _active_floor)

func _should_poll_overview() -> bool:
	if not is_visible_in_tree():
		return false
	if _active_floor <= 0 or not _is_own_floor(_active_floor):
		return false
	if _event_fully_finished():
		return false
	if not _my_room_registered():
		return true
	return _my_open_room_needs_member_refresh()

func _should_poll_live_floor() -> bool:
	if not is_visible_in_tree():
		return false
	if _active_floor <= 0:
		return false
	if _event_fully_finished() or _floor_settled():
		return false
	return true

func _on_poll_tick() -> void :
	if not is_visible_in_tree():
		_sync_poll_timer()
		return
	if _event_fully_finished():
		_refresh_countdown()
		_sync_poll_timer()
		return
	_refresh_countdown()
	_request_window()
	if _should_poll_overview():
		_request_overview()
	if _active_floor > 0:
		var m = _match_data.get("match") if _match_data else null
		if m is Dictionary:
			_sync_flow_overlay(m)
		else:
			_sync_flow_overlay({})
	if not _should_poll_live_floor():
		return
	_heavy_poll_n += 1
	var force_rooms: = _my_open_room_needs_member_refresh()
	if force_rooms:
		var now_ms: = Time.get_ticks_msec()
		if now_ms - _last_missing_members_poll_ms >= MISSING_MEMBER_POLL_MS:
			_last_missing_members_poll_ms = now_ms
			_room_list_poll_n = 0
			var n_fast = _net()
			if n_fast and n_fast.has_method("get_shengsi_tower_room_list"):
				n_fast.get_shengsi_tower_room_list(_active_floor)
	else:
		_room_list_poll_n += 1
		if _room_list_poll_n >= ROOM_LIST_POLL_EVERY:
			_room_list_poll_n = 0
			var n_list = _net()
			if n_list and n_list.has_method("get_shengsi_tower_room_list"):
				n_list.get_shengsi_tower_room_list(_active_floor)
	if _event_started_or_finished() and _is_own_floor(_active_floor):
		_request_matchup_if_started()
	if _heavy_poll_n >= HEAVY_POLL_EVERY:
		_heavy_poll_n = 0
		_request_feed()
		var n = _net()
		if n and n.has_method("get_shengsi_tower_floor"):
			n.get_shengsi_tower_floor(_active_floor)
		_request_matchup_if_started()

func _feature_on() -> bool:
	if bool(_overview.get("featureEnabled", false)):
		return true
	var cfg = _overview.get("config", {})
	if cfg is Dictionary and bool(cfg.get("featureEnabled", false)):
		return true
	return false

func _shanghai_minutes_of_day(unix: int) -> int:
	var d: = Time.get_datetime_dict_from_unix_time(unix + 8 * 3600)
	return int(d.hour) * 60 + int(d.minute)

func _cfg_minute_bounds() -> Vector2i:
	var cfg = _overview.get("config", {})
	if not (cfg is Dictionary):
		return Vector2i(-1, -1)
	if not cfg.has("signupStartHour") and not cfg.has("startHour"):
		return Vector2i(-1, -1)
	var s: = int(cfg.get("signupStartHour", 19)) * 60 + int(cfg.get("signupStartMinute", 45))
	var e: = int(cfg.get("startHour", 20)) * 60 + int(cfg.get("startMinute", 0))
	return Vector2i(s, e)

func _event_fully_finished() -> bool:
	return str(_overview.get("phase", "")) == "finished"

func _public_event_key() -> String:
	return str(_overview.get("eventKey", "")).strip_edges()

func _clear_public_battle_cache() -> void :
	_battles_list_cache.clear()
	_match_replay_cache.clear()
	_cached_event_key = ""
	_pending_replay_match_id = 0
	_pending_replay_my_entry_id = 0

func _sync_public_battle_cache_event() -> void :
	var k: = _public_event_key()
	if k.is_empty():
		return
	if k != _cached_event_key:
		_battles_list_cache.clear()
		_match_replay_cache.clear()
		_cached_event_key = k

func _floor_battles_cache_key(floor: int) -> String:
	return "%s|%d" % [_public_event_key(), floor]

func _remember_match_replay(md: Dictionary) -> void :
	if not _match_has_log_payload(md):
		return
	var mid: = int(md.get("matchId", 0))
	if mid <= 0:
		return
	_match_replay_cache[str(mid)] = md.duplicate(true)

func _cached_match_replay(match_id: int) -> Dictionary:
	var key: = str(int(match_id))
	if _match_replay_cache.has(key):
		var cached = _match_replay_cache[key]
		if cached is Dictionary:
			return cached
	return {}

func _floor_settled() -> bool:
	if _event_fully_finished():
		return true
	var st: = str(_floor_row(_active_floor).get("status", ""))
	return st in ["finished", "ended"]

func _event_started_or_finished() -> bool:
	var phase: = str(_overview.get("phase", ""))
	if phase in ["battle", "finished"]:
		return true
	if bool(_overview.get("pastStart", false)):
		return true
	var end_at: = int(_overview.get("signupEndAt", 0))
	return end_at > 0 and _now_unix() >= end_at

func _in_signup_window() -> bool:
	if not _overview_ok:
		return false
	if _event_started_or_finished():
		return false
	if _overview.has("inSignupWindow"):
		return bool(_overview.get("inSignupWindow", false))
	var now: = _now_unix()
	var start_at: = int(_overview.get("signupStartAt", 0))
	var end_at: = int(_overview.get("signupEndAt", 0))
	if start_at > 0 and end_at > 0:
		return now >= start_at and now < end_at
	var bounds: = _cfg_minute_bounds()
	if bounds.x >= 0 and bounds.y > bounds.x:
		var md: = _shanghai_minutes_of_day(now)
		return md >= bounds.x and md < bounds.y
	return false

func _signup_wait_text() -> String:
	if _in_signup_window():
		return ""
	if not _overview_ok:
		return "报名状态没同步到，请点刷新或再进一次"
	var now: = _now_unix()
	var start_at: = int(_overview.get("signupStartAt", 0))
	var end_at: = int(_overview.get("signupEndAt", 0))
	if bool(_overview.get("pastStart", false)) or (end_at > 0 and now >= end_at):
		return "报名已截止"
	if start_at > 0 and now < start_at:
		return "报名尚未开始，可先查看本层"
	var bounds: = _cfg_minute_bounds()
	if bounds.x >= 0:
		var md: = _shanghai_minutes_of_day(now)
		if md < bounds.x:
			return "报名尚未开始，可先查看本层"
		if md >= bounds.y:
			return "报名已截止"
	return "当前不在报名时间"

func _player_reinc() -> int:
	if _overview.has("myReincarnation"):
		return maxi(0, int(_overview.get("myReincarnation", 0)))
	if game_manager == null or game_manager.player == null:
		return 0
	var p = game_manager.player
	if p is Dictionary:
		return maxi(0, int(p.get("reincarnation", 0)))
	return maxi(0, int(p.reincarnation))

func _floor_for_reinc(n: int) -> int:
	if n >= 400:
		return 5
	if n >= 300:
		return 4
	if n >= 200:
		return 3
	if n >= 100:
		return 2
	if n >= 0:
		return 1
	return 0

func _my_floor() -> int:
	var mf: = int(_overview.get("myFloor", 0))
	if mf > 0:
		return mf
	return _floor_for_reinc(_player_reinc())

func _is_own_floor(floor: int) -> bool:
	return floor > 0 and floor == _my_floor()

func _lookup_floor_in_list(floors, floor: int) -> Dictionary:
	if floors is Array:
		for f in floors:
			if f is Dictionary and int(f.get("floor", 0)) == floor:
				return f
	return {}

func _floor_row(floor: int) -> Dictionary:
	var row: = _lookup_floor_in_list(_overview.get("floors", []), floor)
	if row.is_empty():
		var cfg = _overview.get("config", {})
		if cfg is Dictionary:
			row = _lookup_floor_in_list(cfg.get("floors", []), floor)
	var base: = _default_reinc_row(floor)
	base["floor"] = floor
	base["championGiftItem"] = "塔%d礼包" % floor
	base["capacity"] = 8
	base["registeredCount"] = 0
	base["status"] = "waiting"
	if row.is_empty():
		return base
	for k in base.keys():
		if not row.has(k) or row.get(k) == null and k != "maxReincarnation":
			if k == "maxReincarnation":
				continue
			row[k] = base[k]
	if not row.has("championGiftItem") or str(row.get("championGiftItem", "")) == "":
		row["championGiftItem"] = base["championGiftItem"]
	if not row.has("minReincarnation"):
		row["minReincarnation"] = base["minReincarnation"]
	if not row.has("maxReincarnation") and base.has("maxReincarnation"):
		row["maxReincarnation"] = base.get("maxReincarnation")
	return row

func _refresh_my_floor_hint() -> void :
	if _my_floor_hint == null:
		return
	var mf: = _my_floor()
	var reinc: = _player_reinc()
	if mf > 0:
		_my_floor_hint.text = "我的层：第 %d 层（投胎 %d）" % [mf, reinc]
	else:
		_my_floor_hint.text = "我的层：未匹配到分区"

func _status_cn(st: String) -> String:
	match st:
		"waiting":
			return "未开放"
		"signup":
			return "报名中"
		"full":
			return "已满"
		"battle":
			return "激战中"
		"finished":
			return "已决出塔主"
		"closed":
			return "未开放"
		"ended":
			return "已结束"
		_:
			return "未开放"

func _reinc_text(row: Dictionary) -> String:
	var mn: = int(row.get("minReincarnation", 0))
	if row.get("maxReincarnation") == null:
		return "投胎 %d 次以上" % mn
	return "投胎 %d–%d" % [mn, int(row.get("maxReincarnation", 0))]

func _pad2_time(n: int) -> String:
	return "%02d" % maxi(0, n)

func _signup_range_text() -> String:
	var t: = str(_overview.get("signupRangeText", "")).strip_edges()
	if not t.is_empty():
		return t
	var cfg = _overview.get("config", {})
	if cfg is Dictionary:
		t = str(cfg.get("signupRangeText", "")).strip_edges()
		if not t.is_empty():
			return t
		if cfg.has("signupStartHour") or cfg.has("startHour"):
			return "%s:%s–%s:%s" % [
				_pad2_time(int(cfg.get("signupStartHour", 19))), 
				_pad2_time(int(cfg.get("signupStartMinute", 45))), 
				_pad2_time(int(cfg.get("startHour", 20))), 
				_pad2_time(int(cfg.get("startMinute", 0))), 
			]
	return ""

func _refresh_countdown() -> void :
	var range_text: = _signup_range_text()
	var start_at: = int(_overview.get("signupStartAt", 0))
	var end_at: = int(_overview.get("signupEndAt", 0))
	var now: = _now_unix()
	var phase: = str(_overview.get("phase", ""))
	if phase == "finished":
		_time_label.text = "今日已结束" if range_text.is_empty() else "今日已结束 · %s" % range_text
		return
	if phase == "battle" or bool(_overview.get("pastStart", false)) or (end_at > 0 and now >= end_at):
		_time_label.text = "激战中"
		return
	if start_at > 0 and now < start_at:
		_time_label.text = "距报名开始 %s" % _fmt_remain(start_at - now)
		return
	if end_at > 0 and now < end_at:
		_time_label.text = "距开战 %s" % _fmt_remain(end_at - now)
		return
	if range_text.is_empty():
		_time_label.text = "报名状态同步中" if not _overview_ok else "报名 --:--"
		return
	_time_label.text = "报名 %s" % range_text

func _fmt_remain(sec: int) -> String:
	var s: = maxi(0, sec)
	var m: = s / 60
	var r: = s % 60
	if m >= 60:
		return "%d:%02d:%02d" % [m / 60, m % 60, r]
	return "%02d:%02d" % [m, r]

func _on_window(data: Dictionary) -> void :
	if data == null or data.is_empty():
		return
	var prev_event_key: = _event_key_of(_overview)
	for k in ["inSignupWindow", "pastStart", "signupStartAt", "signupEndAt", "signupRangeText", "serverNow", "phase", "eventKey", "featureEnabled"]:
		if data.has(k):
			_overview[k] = data.get(k)
	var incoming_event_key: = _event_key_of(_overview)
	if _is_new_event_round(prev_event_key, incoming_event_key):
		_clear_local_team_state_for_new_event()
	_overview_ok = true
	_sync_public_battle_cache_event()
	var server_now: = int(_overview.get("serverNow", 0))
	if server_now > 0:
		_clock_skew_sec = float(server_now) - Time.get_unix_time_from_system()
	_refresh_countdown()
	if _active_floor > 0:
		_refresh_floor_header()
		_refresh_lobby_actions()
		_refresh_registered_button()
		_refresh_main_action()
		_sync_overlay_from_match_cache()
	_sync_poll_timer()

func _on_window_fail(_err: String) -> void :
	if _overview_ok:
		return
	_refresh_countdown()
	if _active_floor > 0:
		_refresh_lobby_actions()
		_refresh_main_action()

func _on_overview(data: Dictionary) -> void :
	var incoming_entry = data.get("myEntry") if data else null
	var incoming_room = data.get("myRoom") if data else null
	var prev_entry = _overview.get("myEntry")
	var prev_room = _overview.get("myRoom")
	var prev_event_key: = _event_key_of(_overview)
	var incoming_event_key: = _event_key_of(data)
	_overview = data if data else {}
	if _is_new_event_round(prev_event_key, incoming_event_key):
		_drop_local_caches_for_new_event()
	else:
		_keep_local_signup_against_empty(incoming_entry, incoming_room, prev_entry, prev_room, prev_event_key, incoming_event_key)
	_overview_ok = not _overview.is_empty()
	_sync_public_battle_cache_event()
	var server_now: = int(_overview.get("serverNow", 0))
	if server_now > 0:
		_clock_skew_sec = float(server_now) - Time.get_unix_time_from_system()
	_refresh_countdown()
	_refresh_my_floor_hint()
	_closed_overlay.visible = false
	var floors = _overview.get("floors", [])
	if floors is Array:
		for f in floors:
			if not (f is Dictionary):
				continue
			var fl: = int(f.get("floor", 0))
			var wrap: Control = _floor_hotspots.get(fl)
			if wrap == null:
				continue
			var hint: Label = wrap.get_node_or_null("ReincHint") as Label
			if hint:
				hint.text = _reinc_hint_text(f)
	if data.has("openRooms"):
		_apply_open_rooms_payload(data.get("openRooms"))
	if _active_floor > 0:
		_maybe_adopt_registered_from_teams()
		_refresh_floor_header()
		_refresh_lobby_actions()
		_refresh_registered_button()
		_refresh_main_action()
		_sync_overlay_from_match_cache()
	_sync_poll_timer()

func _on_overview_fail(_err: String) -> void :
	if _overview_ok:
		return
	_refresh_countdown()
	_refresh_my_floor_hint()
	if _active_floor > 0:
		_refresh_floor_header()
		_refresh_lobby_actions()
		_refresh_main_action()

func _open_floor(floor: int) -> void :
	_active_floor = floor
	_floor_data = {}
	_last_feed_id = 0
	_room_list_data = {}
	_room_list_poll_n = 0
	for c in _feed_box.get_children():
		c.queue_free()
	_hub_layer.visible = false
	_floor_layer.visible = true
	_floor_title.text = "生死塔 · 第 %d 层" % floor
	_refresh_floor_header()
	_refresh_lobby_actions()
	_refresh_registered_button()
	_fill_prep({})
	_refresh_main_action()
	_request_overview()
	var n = _net()
	if n and n.has_method("get_shengsi_tower_floor"):
		n.get_shengsi_tower_floor(floor)
	if not _event_fully_finished() and not _floor_settled():
		if n and n.has_method("get_shengsi_tower_room_list"):
			n.get_shengsi_tower_room_list(floor)
		_request_feed()
		_request_matchup_if_started()
	_sync_flow_overlay({})

func _show_hub() -> void :
	_active_floor = 0
	_room_list_data = {}
	_room_list_poll_n = 0
	_kill_prep_intro_tween()
	_hide_flow_overlay()
	_floor_layer.visible = false
	_hub_layer.visible = true
	_request_window()
	_request_overview()

func _refresh_floor_header() -> void :
	var row: = _floor_row(_active_floor)
	var own: = _is_own_floor(_active_floor)
	var gift: = str(row.get("championGiftItem", "塔%d礼包" % _active_floor))
	var st_row: = str(row.get("status", ""))
	var extra: = "仅可观战本层"
	if _event_fully_finished():
		if st_row != "finished":
			st_row = "ended"
		extra = "今日已结束"
	elif own:
		if _in_signup_window():
			extra = "可报名本层"
		elif st_row == "finished":
			extra = "已决出塔主"
		elif _event_started_or_finished():
			extra = "激战中"
		else:
			extra = "报名未开始"
	elif st_row == "finished":
		extra = "已决出塔主"
	_floor_info.text = "%s · 容量 %d/%d · 奖励 %s · %s · %s" % [
		_reinc_hint_text(row), 
		int(row.get("registeredCount", 0)), 
		int(row.get("capacity", 8)), 
		gift, 
		_status_cn(st_row), 
		extra, 
	]
	_refresh_champion_display()

func _floor_champion() -> Dictionary:
	var ch = _floor_data.get("champion") if _floor_data else null
	if ch is Dictionary and not ch.is_empty():
		return ch
	var row: = _floor_row(_active_floor)
	ch = row.get("champion")
	if ch is Dictionary and not ch.is_empty():
		return ch
	return {}

func _refresh_champion_display() -> void :
	if _champion_box == null:
		return
	_clear_box(_champion_box)
	var ch: = _floor_champion()
	var wrap: = CenterContainer.new()
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_champion_box.add_child(wrap)
	var row: = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	wrap.add_child(row)
	var members: Array = []
	if ch.get("members") is Array:
		members = ch.get("members")
	if members.size() >= 1:
		for i in range(2):
			var slot_m: Dictionary = members[i] if i < members.size() and members[i] is Dictionary else {}
			if slot_m.is_empty() and i == 0:
				slot_m = {
					"nickname": str(ch.get("leaderNickname", "塔主")), 
					"isLeader": true, 
				}
			elif slot_m.is_empty():
				slot_m = {
					"nickname": str(ch.get("memberNickname", "")), 
					"isLeader": false, 
				}
			if str(slot_m.get("nickname", "")).strip_edges().is_empty():
				row.add_child(_champion_slot({}, true))
			else:
				row.add_child(_champion_slot(slot_m, false))
	else:
		row.add_child(_champion_slot({}, true))
		row.add_child(_champion_slot({}, true))
	_enable_floor_touch_scroll()

func _champion_slot(member: Dictionary, is_empty: bool) -> Control:
	var slot: = _create_member_slot(member, is_empty, "vacant")
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return slot

func _add_section_card(parent: Control, title: String) -> VBoxContainer:
	var panel: = PanelContainer.new()
	var st: = UIStyle.create_item_style()
	st.content_margin_left = 12
	st.content_margin_right = 12
	st.content_margin_top = 10
	st.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", st)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var body: = VBoxContainer.new()
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_constant_override("separation", 8)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var head: = Label.new()
	head.text = title
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_theme_font_size_override("font_size", 16)
	head.add_theme_color_override("font_color", COLOR_TITLE)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(head)
	panel.add_child(body)
	parent.add_child(panel)
	return body

func _enable_floor_touch_scroll() -> void :
	if _floor_scroll == null or _floor_body == null:
		return
	TouchScrollUtils.configure_scroll(_floor_scroll)
	for child in _floor_body.get_children():
		if child is Control:
			TouchScrollUtils.enable_touch_drag_passthrough(child as Control)

func _clear_box(box: VBoxContainer) -> void :
	if box == null:
		return
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()

func _center_floor_label(lbl: Label) -> void :
	if lbl == null:
		return
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if lbl.autowrap_mode == TextServer.AUTOWRAP_OFF:
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _add_btn(parent: Control, text: String, w: float, fn: Callable, primary: bool = false) -> Button:
	var b: = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(w, 44)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if primary:
		_style_primary_button(b)
	else:
		_style_secondary_button(b)
	TouchScrollUtils.bind_tap(b, fn)
	parent.add_child(b)
	return b

func _refresh_lobby_actions() -> void :
	_clear_box(_lobby_box)
	if _active_floor <= 0 or _lobby_box == null:
		return
	var own: = _is_own_floor(_active_floor)
	if own:
		_lobby_box.add_child(_create_snapshot_panel())
	var rooms: = _rooms_on_floor()
	var my_id: = _my_room_id_on_floor()
	if not own:
		var tip: = Label.new()
		tip.text = "仅可观战本层，不能在此组队"
		tip.add_theme_color_override("font_color", COLOR_MUTED)
		tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_center_floor_label(tip)
		_lobby_box.add_child(tip)
	elif not _event_fully_finished() and (my_id > 0 or not _my_entry_on_floor().is_empty()):
		var mine: = _find_room(rooms, my_id)
		var ov_room = _overview.get("myRoom")
		if ov_room is Dictionary:
			mine = _prefer_fuller_room(mine, ov_room)
		var roster: = _card_from_my_registered_team()
		var roster_members = roster.get("members", [])
		if roster_members is Array and roster_members.size() >= 1:
			mine = _prefer_fuller_room(mine, roster)
		elif mine.is_empty():
			mine = _stub_my_room(my_id)
		_lobby_box.add_child(_create_team_card(mine, true, my_id, own))
		var sep: = Label.new()
		sep.text = "其他队伍"
		_center_floor_label(sep)
		sep.add_theme_font_size_override("font_size", 14)
		sep.add_theme_color_override("font_color", Color(0.669, 0.649, 0.598))
		_lobby_box.add_child(sep)
	else:
		if not _in_signup_window():
			var wait_s: = Label.new()
			wait_s.text = _signup_wait_text()
			wait_s.add_theme_color_override("font_color", COLOR_MUTED)
			wait_s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_center_floor_label(wait_s)
			_lobby_box.add_child(wait_s)
		if _in_signup_window():
			_lobby_box.add_child(_create_create_panel())
	var others: = 0
	for room in rooms:
		if not (room is Dictionary):
			continue
		if int(room.get("roomId", 0)) == my_id:
			continue
		_lobby_box.add_child(_create_team_card(room, false, my_id, own))
		others += 1
	if others == 0:
		var empty: = Label.new()
		empty.text = "暂无开放队伍"
		empty.add_theme_color_override("font_color", COLOR_MUTED)
		_center_floor_label(empty)
		_lobby_box.add_child(empty)
	_enable_floor_touch_scroll()

func _on_room_list(data: Dictionary) -> void :
	if _active_floor <= 0:
		return
	_apply_open_rooms_payload(data.get("rooms", []))
	var my_id: = _my_room_id_on_floor()
	if my_id > 0 and _find_room(_rooms_on_floor(), my_id).is_empty() and not _my_room_registered():
		var ov_room = _overview.get("myRoom")
		if ov_room is Dictionary and _room_member_count(ov_room) >= 1:
			_upsert_cached_room(ov_room)
		else:
			_upsert_cached_room(_stub_my_room(my_id))
	_refresh_lobby_actions()

func _apply_open_rooms_payload(rooms_raw) -> void :
	if not (rooms_raw is Array):
		return
	var my_id: = _my_room_id_on_floor()
	var prev_mine: = _find_room(_rooms_on_floor(), my_id)
	_room_list_data["rooms"] = rooms_raw
	var now_mine: = _find_room(_rooms_on_floor(), my_id)
	var ov_mine: Dictionary = {}
	var raw_ov = _overview.get("myRoom")
	if raw_ov is Dictionary:
		ov_mine = raw_ov
	var best: = _prefer_fuller_room(_prefer_fuller_room(prev_mine, now_mine), ov_mine)
	if my_id > 0 and _room_member_count(best) > _room_member_count(now_mine):
		_upsert_cached_room(best)

func _room_members_of(room: Dictionary) -> Array:
	var raw = room.get("members", [])
	return raw if raw is Array else []

func _room_member_count(room: Dictionary) -> int:
	if room.is_empty():
		return 0
	return maxi(_room_members_of(room).size(), int(room.get("memberCount", 0)))

func _prefer_fuller_room(a: Dictionary, b: Dictionary) -> Dictionary:
	var ca: = _room_member_count(a)
	var cb: = _room_member_count(b)
	if cb > ca:
		return b
	if ca > cb:
		return a
	if not b.is_empty():
		return b
	return a

func _my_open_room_needs_member_refresh() -> bool:
	if _my_room_registered():
		return false
	if _my_room_id_on_floor() <= 0:
		return false
	var mine: = _find_room(_rooms_on_floor(), _my_room_id_on_floor())
	var ov_room = _overview.get("myRoom")
	if ov_room is Dictionary:
		mine = _prefer_fuller_room(mine, ov_room)
	var max_m: = maxi(2, int(mine.get("maxMembers", 2)))
	return _room_member_count(mine) < max_m

func _rooms_on_floor() -> Array:
	var raw = _room_list_data.get("rooms", [])
	var out: Array = []
	if not (raw is Array):
		return out
	for r in raw:
		if not (r is Dictionary):
			continue
		if r.has("floor"):
			var rf: = int(r.get("floor", 0))
			if rf > 0 and rf != _active_floor:
				continue
		out.append(r)
	return out

func _my_room_id_on_floor() -> int:
	var my_room = _overview.get("myRoom")
	if not (my_room is Dictionary) or my_room.is_empty():
		return 0
	if my_room.has("floor"):
		var mf: = int(my_room.get("floor", 0))
		if mf > 0 and mf != _active_floor:
			return 0
	return int(my_room.get("roomId", 0))

func _find_room(rooms: Array, room_id: int) -> Dictionary:
	if room_id <= 0:
		return {}
	for r in rooms:
		if r is Dictionary and int(r.get("roomId", 0)) == room_id:
			return r
	return {}

func _local_leader_member() -> Dictionary:
	var uid: = 0
	var nick: = "队长"
	var cid: = 0
	var lv: = 1
	var realm: = ""
	if game_manager and game_manager.get("network") and game_manager.network:
		uid = int(game_manager.network.user_id)
	if game_manager and game_manager.get("player") and game_manager.player:
		nick = str(game_manager.player.player_name)
		cid = int(game_manager.player.player_character_id)
		lv = int(game_manager.player.level)
		realm = str(game_manager.player.realm)
	return {
		"userId": uid, 
		"nickname": nick, 
		"isLeader": true, 
		"playerCharacterId": cid, 
		"level": lv, 
		"realm": realm, 
	}

func _upsert_cached_room(room: Dictionary) -> void :
	if room.is_empty():
		return
	var rid: = int(room.get("roomId", 0))
	if rid <= 0:
		return
	var rooms: Array = []
	var raw = _room_list_data.get("rooms", [])
	if raw is Array:
		rooms = raw.duplicate()
	var found: = false
	for i in range(rooms.size()):
		if rooms[i] is Dictionary and int(rooms[i].get("roomId", 0)) == rid:
			rooms[i] = room
			found = true
			break
	if not found:
		rooms.append(room)
	_room_list_data["rooms"] = rooms

func _apply_room_from_action(kind: String, data: Dictionary) -> void :
	var room: Dictionary = {}
	var raw_room = data.get("room")
	if raw_room is Dictionary:
		room = raw_room
	var rid: = int(data.get("roomId", room.get("roomId", 0)))
	var fl: = int(data.get("floor", room.get("floor", _active_floor)))
	if kind == "room_create":
		_overview["myRoom"] = {
			"roomId": rid, 
			"floor": fl, 
			"status": "open", 
			"isLeader": true, 
		}
		if room.is_empty():
			room = _stub_my_room(rid)
		_upsert_cached_room(room)
	elif kind == "room_join":
		_overview["myRoom"] = {
			"roomId": rid, 
			"floor": fl, 
			"status": "open", 
			"isLeader": false, 
		}
		if not room.is_empty():
			_upsert_cached_room(room)
	elif kind == "room_leave" or kind == "room_disband":
		var old_id: = _my_room_id_on_floor()
		_overview["myRoom"] = {}
		if kind == "room_disband" and old_id > 0:
			var kept: Array = []
			for r in _rooms_on_floor():
				if int(r.get("roomId", 0)) != old_id:
					kept.append(r)
			_room_list_data["rooms"] = kept
	_refresh_lobby_actions()

func _my_entry_on_floor() -> Dictionary:
	var my_entry = _overview.get("myEntry")
	if not (my_entry is Dictionary) or my_entry.is_empty():
		return {}
	if int(my_entry.get("floor", 0)) != _active_floor:
		return {}
	return my_entry

func _my_room_registered() -> bool:
	var my_room = _overview.get("myRoom")
	if my_room is Dictionary and str(my_room.get("status", "")) == "registered":
		return true
	return not _my_entry_on_floor().is_empty()

func _i_am_team_leader() -> bool:
	var my_room = _overview.get("myRoom")
	if my_room is Dictionary and my_room.has("isLeader"):
		return bool(my_room.get("isLeader", false))
	var uid: = _local_user_id()
	if uid <= 0:
		return false
	if my_room is Dictionary and int(my_room.get("leaderId", 0)) == uid:
		return true
	var entry: = _my_entry_on_floor()
	var members = entry.get("members")
	if members is Array:
		for m in members:
			if m is Dictionary and int(m.get("userId", 0)) == uid:
				return bool(m.get("isLeader", false))
	return false

func _card_from_my_registered_team() -> Dictionary:
	var my_room = _overview.get("myRoom")
	var my_entry: = _my_entry_on_floor()
	var members: Array = []
	if my_room is Dictionary and my_room.get("members") is Array and not (my_room.get("members") as Array).is_empty():
		members = my_room.get("members")
	elif my_entry.get("members") is Array:
		members = my_entry.get("members")
	var rid: = _my_room_id_on_floor()
	return {
		"roomId": rid, 
		"floor": _active_floor, 
		"memberCount": members.size(), 
		"maxMembers": maxi(2, members.size()), 
		"status": "registered", 
		"members": members, 
	}

func _apply_register_result(data: Dictionary) -> void :
	var room = data.get("room")
	if room is Dictionary and not room.is_empty():
		_overview["myRoom"] = room
	else:
		var my_room = _overview.get("myRoom")
		if my_room is Dictionary:
			my_room["status"] = "registered"
			_overview["myRoom"] = my_room
	var my_entry = data.get("myEntry")
	if my_entry is Dictionary and not my_entry.is_empty():
		_overview["myEntry"] = my_entry
	_refresh_lobby_actions()
	_refresh_registered_button()
	_refresh_main_action()
	_sync_flow_overlay({})

func _stub_my_room(room_id: int) -> Dictionary:
	var leader: = _local_leader_member()
	return {
		"roomId": room_id, 
		"floor": _active_floor, 
		"leaderId": int(leader.get("userId", 0)), 
		"leaderNickname": str(leader.get("nickname", "")), 
		"memberCount": 1, 
		"maxMembers": 2, 
		"members": [leader], 
	}

func _request_lobby_refresh() -> void :
	_request_window()
	_request_overview()
	var n = _net()
	if n and n.has_method("get_shengsi_tower_room_list") and _active_floor > 0:
		n.get_shengsi_tower_room_list(_active_floor)

func _pinned_snapshot() -> Dictionary:
	var raw = _overview.get("pinnedSnapshot", {})
	return raw if raw is Dictionary else {}

func _has_pinned_snapshot() -> bool:
	return bool(_pinned_snapshot().get("hasPinned", false))

func _is_snapshot_pin_cooldown() -> bool:
	return Time.get_ticks_msec() < _snapshot_pin_cooldown_until_ms

func _create_snapshot_panel() -> Control:
	var box: = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	var status: = Label.new()
	var pin = _pinned_snapshot()
	if _has_pinned_snapshot():
		status.text = "出战快照：%s Lv%d / %s Lv%d" % [
			str(pin.get("playerName", "人物")), 
			int(pin.get("playerLevel", 1)), 
			str(pin.get("petName", "灵兽")), 
			int(pin.get("petLevel", 1)), 
		]
		status.add_theme_color_override("font_color", Color(0.75, 0.9, 0.75))
	else:
		status.text = "请先更新出战快照，再建队或报名"
		status.add_theme_color_override("font_color", Color(1.0, 0.7, 0.45))
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 14)
	box.add_child(status)
	var pin_btn: = Button.new()
	if _snapshot_pin_pending:
		pin_btn.text = "更新中…"
		pin_btn.disabled = true
	elif _is_snapshot_pin_cooldown():
		pin_btn.text = "冷却中…"
		pin_btn.disabled = true
	else:
		pin_btn.text = "查看/更新镜像"
		pin_btn.disabled = false
	pin_btn.custom_minimum_size = Vector2(180, 44)
	pin_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_style_secondary_button(pin_btn)
	TouchScrollUtils.bind_tap(pin_btn, _on_open_shengsi_mirror)
	box.add_child(pin_btn)
	return box

func get_shengsi_mirror_preview() -> Dictionary:
	var pin: = _pinned_snapshot()
	var out: = pin.duplicate() if not pin.is_empty() else {}
	out["mirrorMode"] = "shengsi"
	out["mirrorTitle"] = "当前生死塔出战快照"
	out["hasMirror"] = bool(pin.get("hasPinned", false))
	if str(out.get("updatedAt", "")).is_empty():
		out["updatedAt"] = str(pin.get("pinnedAt", ""))
	if int(out.get("characterId", out.get("character_id", 0))) <= 0 and game_manager and game_manager.get("player") and game_manager.player:
		out["characterId"] = int(game_manager.player.player_character_id)
	if str(out.get("playerRealm", "")).is_empty() and game_manager and game_manager.get("player") and game_manager.player:
		out["playerRealm"] = str(game_manager.player.realm)
	if int(out.get("playerReincarnation", 0)) <= 0 and game_manager and game_manager.get("player") and game_manager.player:
		out["playerReincarnation"] = int(game_manager.player.reincarnation)
	return out

func apply_shengsi_pinned_summary(summary: Dictionary) -> void :
	if summary.is_empty():
		return
	_overview["pinnedSnapshot"] = summary
	_refresh_lobby_actions()

func _on_open_shengsi_mirror() -> void :
	if game_manager and game_manager.has_method("open_shengsi_mirror_popup_from_ui"):
		game_manager.open_shengsi_mirror_popup_from_ui(self)

func _on_pin_snapshot() -> void :
	if _snapshot_pin_pending or _is_snapshot_pin_cooldown():
		return
	if game_manager == null or game_manager.player == null:
		_toast("人物数据未加载，请稍后再试")
		return
	if game_manager.pet_manager == null or game_manager.pet_manager.get_active_pet() == null:
		_toast("请先选择出战宠物后再更新快照")
		return
	var n = _net()
	if n == null or not n.has_method("shengsi_tower_pin_snapshot"):
		return
	_snapshot_pin_pending = true
	_refresh_lobby_actions()
	var snap: Dictionary = BrotherTowerManager.build_local_snapshot(game_manager)
	var op: = "st_pin_%d" % Time.get_unix_time_from_system()
	n.shengsi_tower_pin_snapshot(snap, op)

func _create_create_panel() -> Control:
	var create_panel: = PanelContainer.new()
	create_panel.add_theme_stylebox_override("panel", UIStyle.create_item_style())
	var create_margin: = MarginContainer.new()
	create_margin.add_theme_constant_override("margin_left", 12)
	create_margin.add_theme_constant_override("margin_right", 12)
	create_margin.add_theme_constant_override("margin_top", 14)
	create_margin.add_theme_constant_override("margin_bottom", 14)
	create_panel.add_child(create_margin)
	var create_col: = VBoxContainer.new()
	create_col.add_theme_constant_override("separation", 10)
	create_col.alignment = BoxContainer.ALIGNMENT_CENTER
	create_margin.add_child(create_col)
	var hint: = Label.new()
	hint.text = "先组满 2 人，再报名夺塔"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", COLOR_MUTED)
	create_col.add_child(hint)
	var row: = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	create_col.add_child(row)
	var create_btn: = Button.new()
	create_btn.text = "创建队伍"
	create_btn.custom_minimum_size = Vector2(180, 50)
	create_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	create_btn.disabled = not _in_signup_window()
	_style_primary_button(create_btn)
	TouchScrollUtils.bind_tap(create_btn, func():
		if not _in_signup_window():
			return
		var n = _net()
		if n and n.has_method("shengsi_tower_room_create"):
			n.shengsi_tower_room_create()
	)
	row.add_child(create_btn)
	var refresh_btn: = Button.new()
	refresh_btn.text = "刷新"
	refresh_btn.custom_minimum_size = Vector2(100, 50)
	refresh_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_style_secondary_button(refresh_btn)
	TouchScrollUtils.bind_tap(refresh_btn, _request_lobby_refresh)
	row.add_child(refresh_btn)
	return create_panel

func _create_team_card(room: Dictionary, is_mine: bool, my_room_id: int, can_join: bool) -> Control:
	var card: = PanelContainer.new()
	var card_style: = UIStyle.create_item_style()
	if is_mine:
		card_style.bg_color = Color(0.092, 0.076, 0.044, 0.92)
		card_style.border_color = Color(0.8, 0.6, 0.2, 1.0)
	card.add_theme_stylebox_override("panel", card_style)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.custom_minimum_size = Vector2(0, 88)
	var margin: = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)
	var info_v: = VBoxContainer.new()
	info_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_v.add_theme_constant_override("separation", 6)
	row.add_child(info_v)
	var members: Array = room.get("members", [])
	if members == null or not (members is Array):
		members = []
	if members.is_empty() and is_mine:
		members = [_local_leader_member()]
	var max_m: = maxi(1, int(room.get("maxMembers", 2)))
	var count: = int(room.get("memberCount", members.size()))
	if count < members.size():
		count = members.size()
	var title_lbl: = _line_label("队伍 #%d  人数 %d/%d" % [int(room.get("roomId", 0)), count, max_m], 16)
	if is_mine:
		title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	info_v.add_child(title_lbl)
	var members_row: = HBoxContainer.new()
	members_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	members_row.alignment = BoxContainer.ALIGNMENT_CENTER
	members_row.add_theme_constant_override("separation", 0)
	info_v.add_child(members_row)
	for i in range(max_m):
		var slot_member: Dictionary = {}
		if i < members.size() and members[i] is Dictionary:
			slot_member = members[i]
		members_row.add_child(_create_member_slot(slot_member, i >= members.size()))
	var btn_v: = VBoxContainer.new()
	btn_v.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_v.add_theme_constant_override("separation", 8)
	row.add_child(btn_v)
	var room_id: = int(room.get("roomId", 0))
	if is_mine:
		var my_room = _overview.get("myRoom")
		var i_am_leader: = true
		if my_room is Dictionary and my_room.has("isLeader"):
			i_am_leader = bool(my_room.get("isLeader", true))
		if _my_room_registered() or _event_started_or_finished():
			var tag: = Label.new()
			tag.text = "已报名" if _my_room_registered() else "已开赛"
			tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			tag.add_theme_font_size_override("font_size", 14)
			tag.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
			btn_v.add_child(tag)
		elif i_am_leader:
			var dis_btn: = Button.new()
			dis_btn.text = "解散"
			dis_btn.custom_minimum_size = Vector2(120, 44)
			dis_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			_style_secondary_button(dis_btn)
			TouchScrollUtils.bind_tap(dis_btn, func():
				var n = _net()
				if n and n.has_method("shengsi_tower_room_disband"):
					n.shengsi_tower_room_disband()
			)
			btn_v.add_child(dis_btn)
		else:
			var leave_btn: = Button.new()
			leave_btn.text = "退出"
			leave_btn.custom_minimum_size = Vector2(120, 44)
			leave_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			_style_secondary_button(leave_btn)
			TouchScrollUtils.bind_tap(leave_btn, func():
				var n = _net()
				if n and n.has_method("shengsi_tower_room_leave"):
					n.shengsi_tower_room_leave()
			)
			btn_v.add_child(leave_btn)
	else:
		var join_btn: = Button.new()
		join_btn.custom_minimum_size = Vector2(120, 48)
		join_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var full: = count >= max_m
		if not can_join:
			join_btn.text = "观战"
			join_btn.disabled = true
			_style_secondary_button(join_btn)
		elif full:
			join_btn.text = "已满"
			join_btn.disabled = true
			_style_secondary_button(join_btn)
		elif my_room_id > 0:
			join_btn.text = "加入"
			join_btn.disabled = true
			_style_secondary_button(join_btn)
		elif not _in_signup_window():
			join_btn.text = "加入"
			join_btn.disabled = true
			_style_secondary_button(join_btn)
		else:
			join_btn.text = "加入"
			_style_primary_button(join_btn)
			TouchScrollUtils.bind_tap(join_btn, func():
				var n = _net()
				if n and n.has_method("shengsi_tower_room_join"):
					n.shengsi_tower_room_join(room_id)
			)
		btn_v.add_child(join_btn)
	return card

func _line_label(text: String, size: int) -> Label:
	var l: = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(0.894, 0.864, 0.803))
	return l

func _style_primary_button(btn: Button) -> void :
	btn.add_theme_font_size_override("font_size", 16)
	UIStyle.apply_golden_button_style(btn)
	UIStyle.setup_button_animation(btn)

func _style_secondary_button(btn: Button) -> void :
	btn.add_theme_font_size_override("font_size", 15)
	UIStyle.apply_button_style(btn)
	UIStyle.setup_button_animation(btn)

func _style_stance_selected_button(btn: Button) -> void :
	var st: = StyleBoxFlat.new()
	st.bg_color = Color(0.072, 0.080, 0.079, 0.96)
	st.border_width_left = 3
	st.border_width_top = 3
	st.border_width_right = 3
	st.border_width_bottom = 3
	st.border_color = Color(1.000, 0.905, 0.640, 1)
	st.corner_radius_top_left = 0
	st.corner_radius_top_right = 0
	st.corner_radius_bottom_left = 0
	st.corner_radius_bottom_right = 0
	var hover: = st.duplicate()
	hover.bg_color = Color(0.072, 0.080, 0.079, 1.0)
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_stylebox_override("normal", st)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_hover_color", Color(0.945, 0.912, 0.850))
	btn.add_theme_color_override("font_pressed_color", Color(0.945, 0.912, 0.850))
	UIStyle.setup_button_animation(btn)

func _style_stance_idle_button(btn: Button) -> void :
	var st: = StyleBoxFlat.new()
	st.bg_color = Color(0.060, 0.068, 0.069, 0.88)
	st.border_width_left = 2
	st.border_width_top = 2
	st.border_width_right = 2
	st.border_width_bottom = 2
	st.border_color = Color(0.655, 0.531, 0.245, 0.75)
	st.corner_radius_top_left = 0
	st.corner_radius_top_right = 0
	st.corner_radius_bottom_left = 0
	st.corner_radius_bottom_right = 0
	var hover: = st.duplicate()
	hover.bg_color = Color(0.072, 0.080, 0.079, 0.92)
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_stylebox_override("normal", st)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_color_override("font_color", Color(0.631, 0.611, 0.564))
	btn.add_theme_color_override("font_hover_color", Color(0.682, 0.662, 0.610))
	btn.add_theme_color_override("font_pressed_color", Color(0.631, 0.611, 0.564))
	UIStyle.setup_button_animation(btn)

func _resolve_member_character_id(member: Dictionary) -> int:
	var cid: = int(member.get("playerCharacterId", member.get("player_character_id", -1)))
	if cid >= 0:
		return PlayerCharacterConfig.normalize_id(cid)
	if game_manager and game_manager.get("network") and game_manager.get("player") and game_manager.player:
		if int(member.get("userId", -1)) == int(game_manager.network.user_id):
			return PlayerCharacterConfig.normalize_id(game_manager.player.player_character_id)
	return 0

func _load_player_avatar_texture(character_id: int) -> Texture2D:
	var cid: = PlayerCharacterConfig.normalize_id(character_id)
	var path: = PlayerCharacterConfig.get_avatar_tx_path(cid)
	if not ResourceLoader.exists(path):
		path = PlayerCharacterConfig.get_avatar_tx_path(0)
	return load(path) as Texture2D

func _create_avatar_frame() -> Panel:
	var frame: = Panel.new()
	frame.custom_minimum_size = Vector2(MEMBER_AVATAR_FRAME_SIZE, MEMBER_AVATAR_FRAME_SIZE)
	frame.clip_contents = true
	var style: = UIStyle.create_item_style()
	style.bg_color = Color(0.072, 0.080, 0.079, 1.0)
	style.border_color = UIStyle.COLORS.item_border
	frame.add_theme_stylebox_override("panel", style)
	return frame

func _fill_avatar_frame(frame: Panel, tex: Texture2D = null, show_plus: bool = false) -> void :
	for child in frame.get_children():
		child.queue_free()
	var inner_size: = MEMBER_AVATAR_FRAME_SIZE - 4
	if show_plus or tex == null:
		var placeholder: = ColorRect.new()
		placeholder.position = Vector2(2, 2)
		placeholder.custom_minimum_size = Vector2(inner_size, inner_size)
		placeholder.size = Vector2(inner_size, inner_size)
		placeholder.color = Color(0.631, 0.611, 0.564, 1.0)
		frame.add_child(placeholder)
		if show_plus:
			var plus: = Label.new()
			plus.text = "+"
			plus.position = Vector2(2, 2)
			plus.custom_minimum_size = Vector2(inner_size, inner_size)
			plus.size = Vector2(inner_size, inner_size)
			plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			plus.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			plus.add_theme_font_size_override("font_size", 28)
			plus.add_theme_color_override("font_color", Color(0.708, 0.688, 0.633))
			frame.add_child(plus)
		return
	var avatar: = TextureRect.new()
	avatar.position = Vector2(2, 2)
	avatar.custom_minimum_size = Vector2(inner_size, inner_size)
	avatar.size = Vector2(inner_size, inner_size)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar.texture = tex
	frame.add_child(avatar)

func _format_member_level_text(level_value) -> String:
	if level_value == null:
		return "?"
	var text: = str(level_value).strip_edges()
	if text.is_empty() or text == "?":
		return "?"
	return str(int(float(text)))

func _create_member_slot(member: Dictionary, is_empty: bool, empty_kind: String = "wait", show_detail: bool = true) -> Control:
	var col: = VBoxContainer.new()
	col.custom_minimum_size = Vector2(MEMBER_SLOT_WIDTH, 0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 4)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	var frame_wrap: = CenterContainer.new()
	frame_wrap.custom_minimum_size = Vector2(MEMBER_SLOT_WIDTH, MEMBER_AVATAR_FRAME_SIZE)
	col.add_child(frame_wrap)
	var avatar_frame: = _create_avatar_frame()
	frame_wrap.add_child(avatar_frame)
	var name_lbl: = _line_label("", 13)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_lbl.custom_minimum_size = Vector2(MEMBER_SLOT_WIDTH - 8, 0)
	col.add_child(name_lbl)
	var detail_lbl: Label = null
	if show_detail:
		detail_lbl = _line_label("", 11)
		detail_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		detail_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		detail_lbl.custom_minimum_size = Vector2(MEMBER_SLOT_WIDTH - 8, 0)
		detail_lbl.add_theme_color_override("font_color", Color(0.760, 0.740, 0.680))
		col.add_child(detail_lbl)
	if is_empty or member.is_empty():
		_fill_avatar_frame(avatar_frame, null, true)
		if empty_kind == "vacant":
			name_lbl.text = "虚位以待"
			if detail_lbl:
				detail_lbl.text = "本层尚无塔主"
		else:
			name_lbl.text = "空位"
			if detail_lbl:
				detail_lbl.text = "等待加入"
		if detail_lbl:
			detail_lbl.add_theme_color_override("font_color", Color(0.631, 0.611, 0.564))
		return col
	_fill_avatar_frame(avatar_frame, _load_player_avatar_texture(_resolve_member_character_id(member)), false)
	if bool(member.get("isLeader", false)):
		var crown: = Label.new()
		crown.text = "👑"
		crown.position = Vector2(-2, -8)
		crown.z_index = 2
		crown.add_theme_font_size_override("font_size", 14)
		avatar_frame.add_child(crown)
	name_lbl.text = str(member.get("nickname", "?"))
	if detail_lbl:
		detail_lbl.text = "Lv.%s %s" % [_format_member_level_text(member.get("level", "?")), str(member.get("realm", ""))]
	return col

func _team_pair_name(side: Dictionary) -> String:
	var leader: = str(side.get("leaderNickname", "")).strip_edges()
	var member: = str(side.get("memberNickname", "")).strip_edges()
	if leader.is_empty() and member.is_empty():
		return "?"
	if member.is_empty():
		return leader
	if leader.is_empty():
		return member
	return "%s / %s" % [leader, member]

func _character_id_from_unit_snap(unit) -> int:
	if not (unit is Dictionary):
		return 0
	var u: Dictionary = unit
	var cid: = int(u.get("playerCharacterId", u.get("player_character_id", u.get("characterId", -1))))
	if cid >= 0:
		return cid
	var player = u.get("player")
	if player is Dictionary:
		return int(player.get("player_character_id", player.get("playerCharacterId", 0)))
	return 0

func _slot_member_from_side(side: Dictionary, is_leader: bool) -> Dictionary:
	var unit = side.get("leader") if is_leader else side.get("member")
	if not (unit is Dictionary):
		unit = {}
	var nick_key: = "leaderNickname" if is_leader else "memberNickname"
	var id_key: = "leaderId" if is_leader else "memberId"
	var nick: = str(side.get(nick_key, "")).strip_edges()
	if nick.is_empty():
		nick = str(unit.get("nickname", "")).strip_edges()
	if nick.is_empty() and unit.get("player") is Dictionary:
		var p: Dictionary = unit.get("player")
		nick = str(p.get("name", p.get("player_name", ""))).strip_edges()
	return {
		"nickname": nick, 
		"isLeader": is_leader, 
		"userId": int(side.get(id_key, 0)), 
		"playerCharacterId": _character_id_from_unit_snap(unit), 
	}

func _match_side_slot_members(side: Dictionary) -> Array:
	var raw = side.get("members")
	if raw is Array and (raw as Array).size() >= 1:
		var from_api: Array = []
		for i in range(2):
			if i < raw.size() and raw[i] is Dictionary:
				from_api.append(raw[i])
			else:
				from_api.append(_slot_member_from_side(side, i == 0))
		return from_api
	return [_slot_member_from_side(side, true), _slot_member_from_side(side, false)]

func _create_prep_avatar_slot(member: Dictionary) -> Control:
	var empty_slot: = member.is_empty() or str(member.get("nickname", "")).strip_edges().is_empty()
	var slot: = _create_member_slot(member, empty_slot, "wait", false)
	slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return slot

func _create_prep_team_column(title: String, side: Dictionary) -> Control:
	var col: = VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 6)
	var head: = Label.new()
	head.text = "%s  战力%d" % [title, int(side.get("teamPower", 0))]
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 13)
	head.add_theme_color_override("font_color", COLOR_TITLE)
	col.add_child(head)
	var pair: = HBoxContainer.new()
	pair.alignment = BoxContainer.ALIGNMENT_CENTER
	pair.add_theme_constant_override("separation", 12)
	col.add_child(pair)
	for m in _match_side_slot_members(side):
		var md: Dictionary = m if m is Dictionary else {}
		pair.add_child(_create_prep_avatar_slot(md))
	return col

func _create_prep_matchup_row(mine_d: Dictionary, opp_d: Dictionary) -> Control:
	var wrap: = CenterContainer.new()
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row: = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.add_theme_constant_override("separation", 16)
	wrap.add_child(row)
	row.add_child(_create_prep_team_column("己方", mine_d))
	var vs: = Label.new()
	vs.text = "vs"
	vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vs.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vs.add_theme_font_size_override("font_size", 18)
	vs.add_theme_color_override("font_color", Color(1.0, 0.86, 0.32))
	vs.custom_minimum_size = Vector2(36, 0)
	row.add_child(vs)
	row.add_child(_create_prep_team_column("敌方", opp_d))
	return wrap

func _official_registered_teams() -> Array:
	var teams = _floor_data.get("teams", [])
	var out: Array = []
	if not (teams is Array) or teams.is_empty():
		teams = _floor_row(_active_floor).get("teams", [])
	if not (teams is Array):
		return out
	for t in teams:
		if t is Dictionary and not bool(t.get("isPractice", false)):
			out.append(t)
	return out

func _refresh_registered_button() -> void :
	_clear_box(_teams_box)
	var teams: = _official_registered_teams()
	var cap: = int(_floor_row(_active_floor).get("capacity", 8))
	var row: = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_teams_box.add_child(row)
	var btn: = Button.new()
	btn.text = "查看报名队伍（%d/%d）" % [teams.size(), cap]
	btn.custom_minimum_size = Vector2(220, 44)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_style_secondary_button(btn)
	TouchScrollUtils.bind_tap(btn, _show_registered_teams_popup)
	row.add_child(btn)
	var rec: = Button.new()
	rec.text = "对战记录"
	rec.custom_minimum_size = Vector2(120, 44)
	rec.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_style_secondary_button(rec)
	TouchScrollUtils.bind_tap(rec, _request_my_battles)
	row.add_child(rec)
	_enable_floor_touch_scroll()

func _close_stance_popup() -> void :
	var win: = _find_popup_by_key("shengsi_stance")
	if win == null:
		return
	win.set_meta("popup_key", "")
	win.queue_free()

func _find_popup_by_key(popup_key: String) -> Window:
	if popup_key.is_empty():
		return null
	var hosts: Array = [self]
	var host_win = get_window()
	if host_win:
		hosts.append(host_win)
	for host in hosts:
		if host == null:
			continue
		for child in host.get_children():
			if child is Window and str(child.get_meta("popup_key", "")) == popup_key:
				return child as Window
	return null

func _make_borderless_popup(size: Vector2i, popup_key: String = "") -> Dictionary:
	if not popup_key.is_empty():
		var existing: = _find_popup_by_key(popup_key)
		if existing:
			existing.grab_focus()
			return {}
	var win: = Window.new()
	win.title = ""
	win.size = size
	win.transparent = true
	win.borderless = true
	win.unresizable = true
	if not popup_key.is_empty():
		win.set_meta("popup_key", popup_key)
	win.close_requested.connect( func():
		if is_instance_valid(win):
			win.queue_free()
	)
	var main_panel: = Panel.new()
	main_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_panel.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	win.add_child(main_panel)
	var vbox: = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 12)
	main_panel.add_child(vbox)
	return {"win": win, "box": vbox}

func _attach_popup(win: Window) -> void :
	if win == null:
		return
	WindowHost.attach_window_and_popup_centered(win, self)

func _popup_title(text: String) -> Label:
	var title: = Label.new()
	title.text = text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", COLOR_TITLE)
	return title

func _popup_close_btn(win: Window, text: String = "关闭") -> Button:
	var close_btn: = Button.new()
	close_btn.text = text
	close_btn.custom_minimum_size = UIStyle.POPUP_BUTTON_SIZE
	_style_secondary_button(close_btn)
	TouchScrollUtils.bind_tap(close_btn, func():
		if is_instance_valid(win):
			win.queue_free()
	)
	return close_btn

func _show_registered_teams_popup() -> void :
	var pack: = _make_borderless_popup(Vector2i(460, 560), "shengsi_registered_teams")
	if pack.is_empty():
		return
	var win: Window = pack.get("win")
	var v: VBoxContainer = pack.get("box")
	v.add_child(_popup_title("第 %d 层报名队伍" % _active_floor))
	var scroll: = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	TouchScrollUtils.configure_scroll(scroll)
	var list: = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	TouchScrollUtils.bind_content_touch_scroll(scroll, list)
	var teams: = _official_registered_teams()
	if teams.is_empty():
		var empty: = Label.new()
		empty.text = "暂无报名队伍"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color", COLOR_MUTED)
		list.add_child(empty)
	else:
		for t in teams:
			list.add_child(_create_registered_team_card(t))
	for child in list.get_children():
		if child is Control:
			TouchScrollUtils.enable_touch_drag_passthrough(child as Control)
	var close_row: = HBoxContainer.new()
	close_row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(close_row)
	close_row.add_child(_popup_close_btn(win))
	_attach_popup(win)

func _create_registered_team_card(team: Dictionary) -> Control:
	var card: = PanelContainer.new()
	var st: = UIStyle.create_item_style()
	if bool(team.get("isMine", false)):
		st.bg_color = Color(0.092, 0.076, 0.044, 0.92)
		st.border_color = Color(0.8, 0.6, 0.2, 1.0)
	if str(team.get("status", "")) == "eliminated":
		st.border_color = Color(0.655, 0.531, 0.245, 0.8)
	card.add_theme_stylebox_override("panel", st)
	var margin: = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)
	var col: = VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	margin.add_child(col)
	var status_cn: = "已出局" if str(team.get("status", "")) == "eliminated" else "报名中"
	if str(team.get("status", "")) == "champion":
		status_cn = "冠军"
	var head: = _line_label("战力 %d · %s%s" % [int(team.get("teamPower", 0)), status_cn, " · 我的队伍" if bool(team.get("isMine", false)) else ""], 14)
	if bool(team.get("isMine", false)):
		head.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	elif str(team.get("status", "")) == "eliminated":
		head.add_theme_color_override("font_color", COLOR_MUTED)
	col.add_child(head)
	var members: Array = team.get("members", [])
	if members == null or not (members is Array) or members.is_empty():
		members = [
			{"nickname": str(team.get("leaderNickname", "")), "isLeader": true}, 
			{"nickname": str(team.get("memberNickname", "")), "isLeader": false}, 
		]
	var members_row: = HBoxContainer.new()
	members_row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(members_row)
	for i in range(2):
		var slot_member: Dictionary = {}
		if i < members.size() and members[i] is Dictionary:
			slot_member = members[i]
		var empty_slot: = slot_member.is_empty() or str(slot_member.get("nickname", "")).strip_edges().is_empty()
		members_row.add_child(_create_member_slot(slot_member, empty_slot))
	return card


func _add_phase_outcome_label(parent: Control, my_entry, floor_st: String, match_d: Dictionary) -> void :
	var tip: = Label.new()
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.add_theme_color_override("font_color", COLOR_MUTED)
	var est: = ""
	if my_entry is Dictionary:
		est = str(my_entry.get("status", ""))
	var floor_from_match: = str(_match_data.get("floorStatus", ""))
	if floor_from_match.is_empty():
		floor_from_match = floor_st
	if est == "champion" or (floor_from_match == "finished" and est == "registered"):
		tip.text = "本层无对手，直接成为塔主"
		tip.add_theme_color_override("font_color", COLOR_MY_FLOOR)
	elif est == "eliminated":
		tip.text = "我方已出局"
	elif floor_from_match == "finished" or str(_overview.get("phase", "")) == "finished":
		if my_entry is Dictionary and not my_entry.is_empty():
			tip.text = "今日已结束"
		else:
			tip.text = "今日已结束，本层未参赛"
	elif match_d.is_empty():
		tip.text = "等待对阵"
	else:
		tip.text = "激战中"
	_center_floor_label(tip)
	parent.add_child(tip)

func _refresh_main_action() -> void :
	_clear_box(_action_box)
	var own: = _is_own_floor(_active_floor)
	var row: = _floor_row(_active_floor)
	var st: = str(row.get("status", ""))
	var my_entry = _overview.get("myEntry")
	var my_room = _overview.get("myRoom")
	var match_obj = _match_data.get("match") if _match_data else null
	var m: Dictionary = match_obj if match_obj is Dictionary else {}
	var mst: = str(m.get("status", "")) if not m.is_empty() else ""

	if not own:
		var tip: = Label.new()
		tip.text = "仅可观战本层"
		_center_floor_label(tip)
		_action_box.add_child(tip)
		_enable_floor_touch_scroll()
		return

	if mst in ["prep", "playback", "done"] and not m.is_empty():
		_enable_floor_touch_scroll()
		return

	if _event_started_or_finished():
		_add_phase_outcome_label(_action_box, my_entry, st, m)
		_enable_floor_touch_scroll()
		return

	if st == "battle":
		_enable_floor_touch_scroll()
		return

	if not _in_signup_window():
		if not (my_entry is Dictionary and not my_entry.is_empty() and int(my_entry.get("floor", 0)) == _active_floor):
			var wait_s: = Label.new()
			wait_s.text = _signup_wait_text()
			_center_floor_label(wait_s)
			_action_box.add_child(wait_s)
			_enable_floor_touch_scroll()
			return

	if my_entry is Dictionary and not my_entry.is_empty() and int(my_entry.get("floor", 0)) == _active_floor:
		if _i_am_team_leader():
			_add_btn(_action_box, "取消报名", 140, func():
				var n = _net()
				if n and n.has_method("shengsi_tower_unregister"):
					n.shengsi_tower_unregister()
			, true)
		else:
			var locked: = Button.new()
			locked.text = "取消报名"
			locked.custom_minimum_size = Vector2(140, 44)
			locked.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			locked.disabled = true
			locked.modulate = Color(0.631, 0.611, 0.564, 1)
			_style_secondary_button(locked)
			_action_box.add_child(locked)
		_enable_floor_touch_scroll()
		return

	if st == "full":
		var full: = Label.new()
		full.text = "本层已满"
		_center_floor_label(full)
		_action_box.add_child(full)
		_enable_floor_touch_scroll()
		return

	if not (my_room is Dictionary) or my_room.is_empty() or int(my_room.get("floor", 0)) != _active_floor:
		var need: = Label.new()
		need.text = "请先组满 2 人"
		_center_floor_label(need)
		_action_box.add_child(need)
		_enable_floor_touch_scroll()
		return

	if not bool(my_room.get("isLeader", false)):
		var wait: = Label.new()
		wait.text = "请队长报名"
		_center_floor_label(wait)
		_action_box.add_child(wait)
		_enable_floor_touch_scroll()
		return

	_add_btn(_action_box, "报名夺塔", 160, func():
		var n = _net()
		if n and n.has_method("shengsi_tower_register"):
			n.shengsi_tower_register()
	, true)
	_enable_floor_touch_scroll()

func _fill_prep(match_wrap: Dictionary) -> void :
	_clear_box(_prep_box)
	if not _is_own_floor(_active_floor):
		_hide_flow_overlay()
		_enable_floor_touch_scroll()
		return
	if match_wrap.has("myEntry") and match_wrap.get("myEntry") is Dictionary:
		_overview["myEntry"] = match_wrap.get("myEntry")
	var m = match_wrap.get("match") if match_wrap else null
	if not (m is Dictionary) or m.is_empty():
		if _event_started_or_finished():
			_add_phase_outcome_label(_prep_box, _my_entry_on_floor(), str(_floor_row(_active_floor).get("status", "")), {})
		_sync_flow_overlay({})
		_enable_floor_touch_scroll()
		return
	var md: Dictionary = m
	if int(md.get("floor", 0)) != 0 and int(md.get("floor", 0)) != _active_floor:
		_sync_flow_overlay({})
		_enable_floor_touch_scroll()
		return
	var a = md.get("a", {})
	var b = md.get("b", {})
	if not (a is Dictionary):
		a = {}
	if not (b is Dictionary):
		b = {}
	var my_id: = int(match_wrap.get("myEntryId", 0))
	var a_mine: = int(a.get("entryId", 0)) == my_id
	var mine_d: Dictionary = a if a_mine else b
	var opp_d: Dictionary = b if a_mine else a
	_prep_box.add_child(_create_prep_matchup_row(mine_d, opp_d))
	var st: = str(md.get("status", ""))
	if st != "prep":
		_close_stance_popup()

	if st == "prep":
		var ready_lbl: = Label.new()
		ready_lbl.text = "就绪 %d/%d · %s" % [_display_ready_count(md), int(md.get("readyTotal", 4)), _prep_remain_text(md)]
		_center_floor_label(ready_lbl)
		_prep_box.add_child(ready_lbl)
		_play_prep_intro_then_stance(md)
		if _is_round_ready(md):
			var done: = Label.new()
			done.text = "已就绪"
			done.add_theme_color_override("font_color", COLOR_MY_FLOOR)
			_center_floor_label(done)
			_prep_box.add_child(done)
		else:
			_add_btn(_prep_box, "就绪", 120, func():
				_mark_local_ready_and_submit()
			, true)
	elif st in ["playback", "done"] and (_match_has_log_payload(md) or bool(md.get("hasBattleLog", false))):
		var winner: = int(md.get("winnerEntryId", 0))
		var result: = Label.new()
		if winner == my_id:
			result.text = "我方获胜"
		elif winner > 0:
			result.text = "我方出局"
		else:
			result.text = "胜负已分"
		_center_floor_label(result)
		_prep_box.add_child(result)
		_add_btn(_prep_box, "观看本场对战" if st == "playback" else "再看本场", 160, func(): _show_battle(md, match_wrap), true)
		_maybe_auto_open_battle(md, match_wrap)
	_sync_flow_overlay(md)
	_enable_floor_touch_scroll()

func _prep_remain_text(md: Dictionary) -> String:
	var raw = md.get("prepEndsAt", "")
	var ts: = _parse_time_unix(raw)
	if ts <= 0:
		return "备战中"
	var left: = ts - _now_unix()
	if left <= 0:
		return "对战即将开始"
	return "开战倒计时 %s" % _fmt_remain(left)

func _parse_time_unix(raw) -> int:
	if raw == null or str(raw) == "":
		return 0
	if typeof(raw) in [TYPE_INT, TYPE_FLOAT]:
		var n: = int(raw)
		if n > 100000000000:
			return int(n / 1000)
		return n
	var s: = str(raw)
	var p: = Time.get_unix_time_from_datetime_string(s)
	if p > 0:
		return int(p)
	return 0

func _maybe_auto_open_battle(md: Dictionary, wrap: Dictionary) -> void :
	if _event_fully_finished():
		return
	if _floor_settled():
		return
	var mid: = int(md.get("matchId", 0))
	if mid <= 0 or mid == _auto_battle_match_id:
		return
	if str(md.get("status", "")) != "playback":
		return
	var start_ts: = _parse_time_unix(md.get("playbackStartAt", ""))
	if start_ts > 0 and _now_unix() < start_ts:
		return
	if not _ensure_matchup_log(md):
		return
	_auto_battle_match_id = mid
	_show_battle(md, wrap)

func _local_user_id() -> int:
	if game_manager and game_manager.get("network") and game_manager.network:
		return int(game_manager.network.user_id)
	return 0

func _pick_unit_snap(side: Dictionary, want_mine: bool) -> Dictionary:
	if side.is_empty():
		return {}
	var uid: = _local_user_id()
	var leader = side.get("leader")
	var member = side.get("member")
	if want_mine:
		if uid > 0 and int(side.get("leaderId", 0)) == uid and leader is Dictionary:
			return leader
		if uid > 0 and int(side.get("memberId", 0)) == uid and member is Dictionary:
			return member
		if leader is Dictionary:
			return leader
		if member is Dictionary:
			return member
		return {}
	if uid > 0 and int(side.get("leaderId", 0)) == uid and member is Dictionary:
		return member
	if leader is Dictionary:
		return leader
	if member is Dictionary:
		return member
	return {}

func _refresh_stance_choice_buttons(row: HBoxContainer, selected_key: String) -> void :
	for child in row.get_children():
		if not (child is Button):
			continue
		var btn: Button = child
		var key: = str(btn.get_meta("stance_key", ""))
		if key == selected_key:
			_style_stance_selected_button(btn)
		else:
			_style_stance_idle_button(btn)

func _maybe_show_stance_popup(md: Dictionary, wrap: Dictionary) -> void :
	if not bool(md.get("stanceEnabled", true)):
		return
	if _is_round_ready(md):
		return
	var mid: = int(md.get("matchId", 0))
	if mid <= 0 or mid == _stance_popup_match_id:
		return
	if _find_popup_by_key("shengsi_stance"):
		return
	_stance_popup_match_id = mid
	var pack: = _make_borderless_popup(Vector2i(420, 360), "shengsi_stance")
	if pack.is_empty():
		return
	var win: Window = pack.get("win")
	var v: VBoxContainer = pack.get("box")
	v.add_child(_popup_title("请选你的战斗策略"))
	var tip: = Label.new()
	tip.text = "入塔无回头，败者出局，本层只活一队。猛攻偏攻、稳守偏防、均衡攻守兼备。"
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.add_theme_color_override("font_color", COLOR_MUTED)
	v.add_child(tip)
	var row: = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	var cur: = str(md.get("myStance", _selected_stance))
	for pair in [["attack", "猛攻"], ["balanced", "均衡"], ["defend", "稳守"]]:
		var btn: = Button.new()
		btn.text = pair[1]
		btn.custom_minimum_size = Vector2(100, 48)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		if str(pair[0]) == cur:
			_style_stance_selected_button(btn)
		else:
			_style_stance_idle_button(btn)
		var key: String = pair[0]
		btn.set_meta("stance_key", key)
		TouchScrollUtils.bind_tap(btn, func():
			_selected_stance = key
			var n = _net()
			if n and n.has_method("shengsi_tower_round_stance"):
				n.shengsi_tower_round_stance(key)
			_refresh_stance_choice_buttons(row, key)
		)
		row.add_child(btn)
	var ready_row: = HBoxContainer.new()
	ready_row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(ready_row)
	_add_btn(ready_row, "就绪", 140, func():
		_mark_local_ready_and_submit()
		if is_instance_valid(win):
			win.queue_free()
	, true)
	_attach_popup(win)

func _show_battle(md: Dictionary, wrap: Dictionary) -> void :
	_close_stance_popup()
	if game_manager == null or not game_manager.has_method("start_shengsi_tower_replay"):
		_toast("暂时无法进入战斗画面")
		return
	var my_id: = int(wrap.get("myEntryId", 0))
	if _event_fully_finished() or my_id <= 0:
		_play_or_fetch_battle(md, my_id)
		return
	if not _ensure_matchup_log(md):
		_toast("正在读取战报…")
		return
	_start_shengsi_replay(md, my_id)

func _play_or_fetch_battle(md: Dictionary, my_id: int) -> void :
	var mid: = int(md.get("matchId", 0))
	if mid <= 0:
		_toast("暂时无法进入战斗画面")
		return
	var cached: = _cached_match_replay(mid)
	if not cached.is_empty():
		_start_shengsi_replay(cached, my_id)
		return
	if _match_has_log_payload(md):
		_remember_match_replay(md)
		_start_shengsi_replay(md, my_id)
		return
	if not bool(md.get("hasBattleLog", false)):
		_toast("暂无回放")
		return
	if mid == _pending_replay_match_id:
		_toast("正在读取战报…")
		return
	_pending_replay_match_id = mid
	_pending_replay_my_entry_id = my_id
	var n = _net()
	if n and n.has_method("get_shengsi_tower_match"):
		n.get_shengsi_tower_match(mid)
		_toast("正在读取战报…")
	else:
		_pending_replay_match_id = 0
		_toast("暂时无法读取战报")

func _on_match_detail(data: Dictionary) -> void :
	var battle = data.get("battle") if data else null
	if not (battle is Dictionary) or battle.is_empty():
		_on_match_detail_fail("加载失败")
		return
	_remember_match_replay(battle)
	var mid: = int(battle.get("matchId", 0))
	var my_id: = int(data.get("myEntryId", 0))
	if my_id <= 0:
		my_id = _pending_replay_my_entry_id
	if _pending_replay_match_id != 0 and mid != _pending_replay_match_id and mid != 0:
		return
	_pending_replay_match_id = 0
	_start_shengsi_replay(battle, my_id)

func _on_match_detail_fail(err: String) -> void :
	_pending_replay_match_id = 0
	_toast(_player_err(err) if not str(err).is_empty() else "暂时无法读取战报")

func _start_shengsi_replay(md: Dictionary, my_id: int) -> void :
	_close_stance_popup()
	if game_manager == null or not game_manager.has_method("start_shengsi_tower_replay"):
		_toast("暂时无法进入战斗画面")
		return
	if not _match_has_log_payload(md):
		_toast("暂无回放")
		return
	_remember_match_replay(md)
	_replay_opened_match_id = int(md.get("matchId", 0))
	_hide_flow_overlay()
	var a = md.get("a", {})
	var b = md.get("b", {})
	if not (a is Dictionary):
		a = {}
	if not (b is Dictionary):
		b = {}
	var a_id: = int(a.get("entryId", md.get("aEntryId", 0)))
	var spectator: = my_id <= 0 or (a_id != my_id and int(b.get("entryId", md.get("bEntryId", 0))) != my_id)
	var a_mine: = true if spectator else a_id == my_id
	var mine_d: Dictionary = a if a_mine else b
	var opp_d: Dictionary = b if a_mine else a
	var uid: = _local_user_id()
	var leader_snap: Dictionary = mine_d.get("leader") if mine_d.get("leader") is Dictionary else {}
	var member_snap: Dictionary = mine_d.get("member") if mine_d.get("member") is Dictionary else {}
	var viewer_is_leader: = spectator or uid <= 0 or int(mine_d.get("leaderId", 0)) == uid
	var my_snap: Dictionary = leader_snap if viewer_is_leader else member_snap
	var partner: Dictionary = member_snap if viewer_is_leader else leader_snap
	if my_snap.is_empty():
		my_snap = leader_snap if not leader_snap.is_empty() else member_snap
		partner = member_snap if my_snap == leader_snap else leader_snap
	if my_snap.is_empty():
		_toast("缺少战斗数据")
		return
	if partner == my_snap:
		partner = {}
	var payload: = {
		"battleLog": md.get("battleLog", []), 
		"victory": int(md.get("winnerEntryId", 0)) == int(mine_d.get("entryId", 0)), 
		"mySnapshot": my_snap, 
		"allyPartner": partner, 
		"allyLeader": mine_d.get("leader", {}), 
		"allyMember": mine_d.get("member", {}), 
		"enemyLeader": opp_d.get("leader", {}), 
		"enemyMember": opp_d.get("member", {}), 
		"opponentName": "%s/%s" % [str(opp_d.get("leaderNickname", "")), str(opp_d.get("memberNickname", ""))], 
		"matchId": int(md.get("matchId", 0)), 
		"myEntryId": my_id, 
		"viewerSide": "A" if a_mine else "B", 
		"viewerRole": "leader" if spectator or uid <= 0 or int(mine_d.get("leaderId", 0)) == uid else "member", 
		"round": int(md.get("round", md.get("roundNo", md.get("bracketRound", 0)))), 
		"allyName": "%s/%s" % [str(mine_d.get("leaderNickname", "")), str(mine_d.get("memberNickname", ""))], 
	}
	_close_toast("正在读取战报…")
	_hide_flow_overlay()
	game_manager.start_shengsi_tower_replay(payload)

func _on_floor_fail(_err: String) -> void :
	pass

func _on_floor(data: Dictionary) -> void :
	if int(data.get("floor", 0)) != _active_floor:
		return
	_floor_data = data
	if data.has("openRooms") and data.get("openRooms") is Array:
		_apply_open_rooms_payload(data.get("openRooms"))
		_refresh_lobby_actions()
	_maybe_adopt_registered_from_teams()
	_refresh_floor_header()
	_refresh_registered_button()
	_refresh_main_action()
	_refresh_champion_display()
	_sync_overlay_from_match_cache()
	_sync_poll_timer()

func _maybe_adopt_registered_from_teams() -> void :
	for t in _official_registered_teams():
		if not (t is Dictionary) or not bool(t.get("isMine", false)):
			continue
		var my_room = _overview.get("myRoom")
		if my_room is Dictionary:
			my_room = my_room.duplicate()
			my_room["status"] = "registered"
			var tm = t.get("members")
			var rm = my_room.get("members")
			if tm is Array and ( not (rm is Array) or tm.size() > rm.size()):
				my_room["members"] = tm
			_overview["myRoom"] = my_room
		else:
			var members = t.get("members")
			_overview["myRoom"] = {
				"status": "registered", 
				"floor": _active_floor, 
				"members": members if members is Array else [], 
			}
		if _my_entry_on_floor().is_empty():
			var entry: Dictionary = t.duplicate()
			entry["floor"] = _active_floor
			_overview["myEntry"] = entry
		_sync_overlay_from_match_cache()
		_refresh_main_action()
		return

func _should_apply_matchup_entry(incoming_entry) -> bool:
	if not (incoming_entry is Dictionary) or incoming_entry.is_empty():
		return false
	var mk: = _event_key_of(_match_data)
	var ck: = _public_event_key()
	if _is_new_event_round(mk, ck):
		return false
	var ov_entry = _overview.get("myEntry")
	if ov_entry is Dictionary and not ov_entry.is_empty():
		var a: = int(incoming_entry.get("entryId", 0))
		var b: = int(ov_entry.get("entryId", 0))
		if a > 0 and b > 0 and a != b:
			return false
		return true
	if str(_overview.get("phase", "")) == "signup":
		var room = _overview.get("myRoom")
		if not (room is Dictionary) or str(room.get("status", "")) != "registered":
			return false
	return true

func _on_matchup(data: Dictionary) -> void :
	_match_data = data if data else {}
	var incoming_entry = _match_data.get("myEntry")
	if _should_apply_matchup_entry(incoming_entry):
		_overview["myEntry"] = incoming_entry
	elif str(_overview.get("phase", "")) == "signup":
		if not _my_room_registered() and _my_entry_on_floor().is_empty():
			_match_data = {}
	var m = _match_data.get("match")
	if m is Dictionary:
		_remember_match_replay(m)
	if _active_floor <= 0:
		return
	if not _event_started_or_finished():
		_sync_flow_overlay({})
		_refresh_lobby_actions()
		_refresh_main_action()
		return
	_fill_prep(_match_data)
	_refresh_lobby_actions()
	_refresh_main_action()

func _on_feed(data: Dictionary) -> void :
	if _active_floor <= 0 or _feed_box == null:
		return
	var lines = data.get("lines", [])
	if not (lines is Array):
		return
	for c in _feed_box.get_children():
		c.queue_free()
	var shown: = 0
	var seen_msg: = {}
	for line in lines:
		if not (line is Dictionary):
			continue
		var fl: = int(line.get("floor", 0))
		if fl != 0 and fl != _active_floor:
			continue
		var msg: = str(line.get("message", "")).strip_edges()
		if msg.is_empty():
			continue
		if seen_msg.has(msg):
			continue
		seen_msg[msg] = true
		var stamp: = _format_feed_time(str(line.get("createdAt", line.get("created_at", ""))))
		var rtl: = RichTextLabel.new()
		rtl.bbcode_enabled = true
		rtl.fit_content = true
		rtl.scroll_active = false
		rtl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rtl.add_theme_font_size_override("normal_font_size", 13)
		rtl.add_theme_color_override("default_color", COLOR_FEED)
		rtl.text = "[%s] %s" % [stamp, _highlight_feed_names(msg)]
		_feed_box.add_child(rtl)
		shown += 1
	if shown <= 0:
		var empty: = Label.new()
		empty.text = "暂无动态，报名后将显示组队与对战信息"
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.add_theme_color_override("font_color", COLOR_MUTED)
		empty.add_theme_font_size_override("font_size", 13)
		_center_floor_label(empty)
		_feed_box.add_child(empty)
	_enable_floor_touch_scroll()

func _format_feed_time(raw: String) -> String:
	var s: = raw.strip_edges()
	if s.is_empty():
		return "--:--:--"
	if s.ends_with("Z"):
		var t_idx: = s.find("T")
		if t_idx > 0 and s.length() >= t_idx + 9:
			var hh: = int(s.substr(t_idx + 1, 2))
			var mm: = int(s.substr(t_idx + 4, 2))
			var ss: = int(s.substr(t_idx + 7, 2))
			return "%02d:%02d:%02d" % [int((hh + 8) % 24), mm, ss]
	var p: = s.find(" ")
	if p > 0 and s.length() >= p + 9:
		return s.substr(p + 1, 8)
	var t: = s.find("T")
	if t > 0 and s.length() >= t + 9:
		return s.substr(t + 1, 8)
	return s

func _highlight_feed_names(message: String) -> String:
	var result: = message.replace("[", "［").replace("]", "］")
	var regex: = RegEx.new()
	regex.compile("「([^」]+)」")
	return regex.sub(result, "[color=#FFD700]「$1」[/color]", true)

func _request_my_battles() -> void :
	if _event_fully_finished():
		_request_floor_battles_public()
		return
	var local: = {
		"battles": _local_battle_records(), 
		"myEntryId": _local_my_entry_id(), 
	}
	_show_my_battles_popup(local)
	var n = _net()
	if n and n.has_method("get_shengsi_tower_my_battles"):
		n.get_shengsi_tower_my_battles()

func _request_floor_battles_public() -> void :
	_sync_public_battle_cache_event()
	var key: = _floor_battles_cache_key(_active_floor)
	if _battles_list_cache.has(key):
		var cached = _battles_list_cache[key]
		if cached is Dictionary:
			_show_my_battles_popup(cached)
			return
	_show_my_battles_popup({"battles": [], "myEntryId": _local_my_entry_id(), "loading": true})
	var n = _net()
	if n and n.has_method("get_shengsi_tower_floor_battles"):
		n.get_shengsi_tower_floor_battles(_active_floor)
	else:
		_toast("暂时无法读取对战记录")

func _on_floor_battles(data: Dictionary) -> void :
	var payload: Dictionary = data.duplicate() if data else {}
	var fl: = int(payload.get("floor", 0))
	if fl > 0 and fl != _active_floor:
		return
	_sync_public_battle_cache_event()
	var ek: = str(payload.get("eventKey", "")).strip_edges()
	if not ek.is_empty() and ek != _public_event_key() and not _public_event_key().is_empty():
		return
	if payload.has("finished") and not bool(payload.get("finished", false)):
		_show_my_battles_popup({"battles": [], "myEntryId": int(payload.get("myEntryId", _local_my_entry_id()))})
		return
	var battles: = _battles_on_active_floor(payload.get("battles", []))
	payload["battles"] = battles
	if int(payload.get("myEntryId", 0)) <= 0:
		payload["myEntryId"] = _local_my_entry_id()
	payload.erase("loading")
	var key: = _floor_battles_cache_key(_active_floor if fl <= 0 else fl)
	_battles_list_cache[key] = payload.duplicate(true)
	_show_my_battles_popup(payload)

func _on_floor_battles_fail(err: String) -> void :
	_toast(_player_err(err) if not str(err).is_empty() else "暂时无法读取对战记录")
	if _find_popup_by_key("shengsi_my_battles"):
		_show_my_battles_popup({"battles": [], "myEntryId": _local_my_entry_id()})

func _on_my_battles_fail(err: String) -> void :
	if _find_popup_by_key("shengsi_my_battles") == null:
		_toast(_player_err(err) if not str(err).is_empty() else "暂时无法读取对战记录")

func _local_my_entry_id() -> int:
	var e: = _my_entry_on_floor()
	if not e.is_empty():
		return int(e.get("entryId", 0))
	var wrap_id: = int(_match_data.get("myEntryId", 0)) if _match_data else 0
	if wrap_id > 0:
		return wrap_id
	return int(_overview.get("myEntry", {}).get("entryId", 0)) if _overview.get("myEntry") is Dictionary else 0

func _local_battle_records() -> Array:
	var out: Array = []
	var seen: = {}
	var m = _match_data.get("match") if _match_data else null
	if m is Dictionary and not m.is_empty() and int(m.get("matchId", 0)) > 0:
		var mf: = int(m.get("floor", 0))
		if mf <= 0 or mf == _active_floor:
			out.append(m)
			seen[int(m.get("matchId", 0))] = true
	var floor_matches = _floor_data.get("matches") if _floor_data else null
	if floor_matches is Array:
		for fm in floor_matches:
			if not (fm is Dictionary):
				continue
			if not (fm.get("a") is Dictionary) and not (fm.get("b") is Dictionary):
				continue
			var mid: = int(fm.get("matchId", 0))
			if mid <= 0 or seen.has(mid):
				continue
			var ff: = int(fm.get("floor", 0))
			if ff > 0 and ff != _active_floor:
				continue
			seen[mid] = true
			out.append(fm)
	return out

func _battles_on_active_floor(raw) -> Array:
	var out: Array = []
	if not (raw is Array):
		return out
	for b in raw:
		if not (b is Dictionary):
			continue
		var fl: = int(b.get("floor", 0))
		if fl > 0 and fl != _active_floor:
			continue
		out.append(b)
	return out

func _on_my_battles(data: Dictionary) -> void :
	var payload: Dictionary = data if data else {}
	var battles: = _battles_on_active_floor(payload.get("battles", []))
	if battles.is_empty():
		battles = _local_battle_records()
	payload = payload.duplicate()
	payload["battles"] = battles
	if int(payload.get("myEntryId", 0)) <= 0:
		payload["myEntryId"] = _local_my_entry_id()
	for b in battles:
		if b is Dictionary:
			_remember_match_replay(b)
	_show_my_battles_popup(payload)

func _show_my_battles_popup(data: Dictionary) -> void :
	var existing: = _find_popup_by_key("shengsi_my_battles")
	if existing:
		existing.set_meta("popup_key", "")
		existing.queue_free()
	var pack: = _make_borderless_popup(Vector2i(480, 560), "shengsi_my_battles")
	if pack.is_empty():
		return
	var win: Window = pack.get("win")
	var v: VBoxContainer = pack.get("box")
	v.add_child(_popup_title("第 %d 层对战记录" % _active_floor))
	var scroll: = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	TouchScrollUtils.configure_scroll(scroll)
	var list: = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	TouchScrollUtils.bind_content_touch_scroll(scroll, list)
	var battles = _battles_on_active_floor(data.get("battles", []))
	if battles.is_empty():
		var empty: = Label.new()
		if bool(data.get("loading", false)):
			empty.text = "正在读取对战记录"
		else:
			empty.text = "暂无对战记录"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color", COLOR_MUTED)
		list.add_child(empty)
	else:
		var my_id: = int(data.get("myEntryId", 0))
		for b in battles:
			if not (b is Dictionary):
				continue
			list.add_child(_create_battle_record_row(b, my_id, win))
	for child in list.get_children():
		if child is Control:
			TouchScrollUtils.enable_touch_drag_passthrough(child as Control)
	var close_row: = HBoxContainer.new()
	close_row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(close_row)
	close_row.add_child(_popup_close_btn(win))
	_attach_popup(win)

func _create_battle_record_row(md: Dictionary, my_id: int, win: Window) -> Control:
	var card: = PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIStyle.create_item_style())
	var margin: = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)
	var col: = VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	margin.add_child(col)
	var a = md.get("a", {})
	var b = md.get("b", {})
	if not (a is Dictionary):
		a = {}
	if not (b is Dictionary):
		b = {}
	var a_name: = _team_pair_name(a)
	var b_name: = _team_pair_name(b)
	var win_id: = int(md.get("winnerEntryId", 0))
	var a_id: = int(a.get("entryId", md.get("aEntryId", 0)))
	var b_id: = int(b.get("entryId", md.get("bEntryId", 0)))
	var spectator: = my_id <= 0 or (a_id != my_id and b_id != my_id)
	var head: = Label.new()
	head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.add_theme_font_size_override("font_size", 14)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var round_n: = int(md.get("bracketRound", 0))
	var floor_n: = int(md.get("floor", _active_floor))
	if spectator:
		var result: = "平局"
		if win_id > 0:
			if win_id == a_id:
				result = "胜者  %s" % a_name
			elif win_id == b_id:
				result = "胜者  %s" % b_name
			else:
				result = "已分出胜负"
		head.text = "第%d层 · 第%d轮" % [floor_n, round_n]
		col.add_child(head)
		var vs_lbl: = Label.new()
		vs_lbl.text = "%s  vs  %s" % [a_name, b_name]
		vs_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vs_lbl.add_theme_font_size_override("font_size", 13)
		vs_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(vs_lbl)
		var res_lbl: = Label.new()
		res_lbl.text = result
		res_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		res_lbl.add_theme_font_size_override("font_size", 13)
		res_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(res_lbl)
	else:
		var a_mine: = a_id == my_id
		var mine_d: Dictionary = a if a_mine else b
		var opp_d: Dictionary = b if a_mine else a
		var result: = "平"
		if win_id == my_id:
			result = "胜"
		elif win_id > 0:
			result = "负"
		head.text = "第%d层 · 第%d轮 · %s" % [floor_n, round_n, result]
		col.add_child(head)
		var mine_lbl: = Label.new()
		mine_lbl.text = "己方  %s" % _team_pair_name(mine_d)
		mine_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		mine_lbl.add_theme_font_size_override("font_size", 13)
		mine_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(mine_lbl)
		var opp_lbl: = Label.new()
		opp_lbl.text = "敌方  %s" % _team_pair_name(opp_d)
		opp_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		opp_lbl.add_theme_font_size_override("font_size", 13)
		opp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(opp_lbl)
	var log = md.get("battleLog", [])
	var can_play: = (log is Array and not (log as Array).is_empty()) or bool(md.get("hasBattleLog", false))
	var btn_row: = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(btn_row)
	if can_play:
		_add_btn(btn_row, "观看回放", 140, func():
			if is_instance_valid(win):
				win.queue_free()
			_play_or_fetch_battle(md, my_id)
		, true)
	else:
		var no: = Label.new()
		no.text = "暂无回放"
		no.add_theme_color_override("font_color", COLOR_MUTED)
		btn_row.add_child(no)
	return card

func _on_action_ok(kind: String, data: Dictionary) -> void :
	if kind == "pin_snapshot":
		_snapshot_pin_pending = false
		_snapshot_pin_cooldown_until_ms = Time.get_ticks_msec() + SNAPSHOT_PIN_COOLDOWN_MS
		var summary = data.get("summary", {}) if data else {}
		if summary is Dictionary and not summary.is_empty():
			_overview["pinnedSnapshot"] = summary
		_toast("出战快照已更新")
		_refresh_lobby_actions()
	if kind == "room_create" or kind == "room_join" or kind == "room_leave" or kind == "room_disband":
		_apply_room_from_action(kind, data if data else {})
	if kind == "register":
		_apply_register_result(data if data else {})
	if kind == "unregister":
		_overview["myEntry"] = {}
		var my_room = _overview.get("myRoom")
		if my_room is Dictionary:
			my_room["status"] = "open"
			_overview["myRoom"] = my_room
		_refresh_lobby_actions()
		_refresh_registered_button()
		_refresh_main_action()
		_sync_flow_overlay({})
	_request_window()
	_request_overview()
	if _active_floor > 0:
		var n = _net()
		if n and n.has_method("get_shengsi_tower_floor"):
			n.get_shengsi_tower_floor(_active_floor)
		if n and n.has_method("get_shengsi_tower_room_list"):
			n.get_shengsi_tower_room_list(_active_floor)
		_request_matchup_if_started()

func _on_action_fail(_kind: String, err: String) -> void :
	if _kind == "pin_snapshot":
		_snapshot_pin_pending = false
		_refresh_lobby_actions()
	_toast(_player_err(err))

func _player_err(err: String) -> String:
	var e: = str(err)
	if e.contains("出战快照") or e.contains("更新人物"):
		return PIN_SNAPSHOT_REQUIRED_MSG
	if e.contains("队伍已满"):
		return "队伍已满"
	if e.contains("同层") or e.contains("所属层"):
		return "不在同一层"
	if e.contains("报名时间"):
		return "当前不在报名时间"
	if e.contains("暂未开放") or e.contains("尚未开启"):
		return "玩法开关未开，可先查看界面"
	if e.is_empty():
		return "操作失败，请稍后重试"
	return e

func _close_toast(msg: String) -> void :
	var win: = _find_popup_by_key("shengsi_toast:%s" % msg)
	if win != null and is_instance_valid(win):
		win.queue_free()

func _toast(msg: String) -> void :
	var pack: = _make_borderless_popup(Vector2i(360, 220), "shengsi_toast:%s" % msg)
	if pack.is_empty():
		return
	var win: Window = pack.get("win")
	var v: VBoxContainer = pack.get("box")
	v.add_child(_popup_title("提示"))
	var lbl: = Label.new()
	lbl.text = msg
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(lbl)
	var close_row: = HBoxContainer.new()
	close_row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(close_row)
	close_row.add_child(_popup_close_btn(win, "确定"))
	_attach_popup(win)

func _rules_bb_escape(s: String) -> String:
	return str(s).replace("[", "［").replace("]", "］")

func _rules_line(head: String, body: String) -> String:
	return "[color=#FFE073]%s[/color][color=#B8C0D4]%s[/color]" % [_rules_bb_escape(head), _rules_bb_escape(body)]

func _full_rules_text() -> String:
	var cfg = _overview.get("config", {})
	if not (cfg is Dictionary):
		cfg = {}
	var range_text: = _signup_range_text()
	if range_text.is_empty():
		range_text = "以后台配置为准"
	var daily: = int(cfg.get("dailyLimitPerUser", 1))
	var participate_fp: = int(cfg.get("participateFriendshipPoints", 5))
	var participate_gift: = str(cfg.get("participateGiftItem", "生死塔参与礼包")).strip_edges()
	if participate_gift.is_empty():
		participate_gift = "生死塔参与礼包"
	var participate_gift_on: = bool(cfg.get("participateGiftEnabled", true))
	var cap_parts: Array = []
	var floor_lines: Array = []
	var floors = cfg.get("floors", _overview.get("floors", []))
	if floors is Array:
		for f in floors:
			if not (f is Dictionary):
				continue
			var fl: = int(f.get("floor", 0))
			if fl <= 0:
				continue
			cap_parts.append(str(int(f.get("capacity", 8))))
			var gift: = str(f.get("championGiftItem", "塔%d礼包" % fl))
			floor_lines.append("第%d层（%s）：塔主队两人各获 %s（开箱随机）" % [fl, _reinc_hint_text(f), gift])
	if floor_lines.is_empty():
		floor_lines = [
			"第1层（投胎数:0-99）：塔1礼包", 
			"第2层（投胎数:100-199）：塔2礼包", 
			"第3层（投胎数:200-299）：塔3礼包", 
			"第4层（投胎数:300-399）：塔4礼包", 
			"第5层（投胎数:400以上）：塔5礼包", 
		]
	var cap_text: = "/".join(cap_parts) if not cap_parts.is_empty() else "8"
	var reward_body: = "开赛时仍在场的每人获得%d友情点。塔主队两人另各获得该层礼包（开箱随机）。" % participate_fp
	if participate_gift_on:
		reward_body = "开赛时仍在场的每人获得%d友情点，并获得%s（开箱随机）。塔主队两人另各获得该层礼包（开箱随机）。" % [participate_fp, participate_gift]
	var lines: PackedStringArray = PackedStringArray()
	lines.append(_rules_line("【玩法】", "入塔无回头。每天一场分层死战：2人组队报名，进入与自己投胎数匹配的那一层；败者当场出局，每层最后只留1队成为塔主。"))
	lines.append("")
	lines.append(_rules_line("【时间】", "报名%s，截止后统一开赛。每人每天限参加%d次。" % [range_text, daily]))
	lines.append("")
	lines.append(_rules_line("【分层】", "按投胎数严格分区，只能报名自己所属层，不能跨层。其它层可点开观战（看队伍和战况），不能报名。"))
	lines.append("")
	lines.append(_rules_line("【组队】", "必须满2人才能报名。队员须与队长同层。建队/加入/退出/解散与兄弟天关类似。"))
	lines.append("")
	lines.append(_rules_line("【报名】", "每层容量%s队（第1层至第5层），先到先得，报满即关闭。报名截止前可退出并释放名额。某层只有1队报名时，该队不战而胜成为塔主。" % cap_text))
	lines.append("")
	lines.append(_rules_line("【战斗】", "2人2宠对战。开战前有准备时间：可选猛攻/均衡/稳守，双方就绪后开打。"))
	lines.append("")
	lines.append(_rules_line("【奖励】", reward_body))
	lines.append("")
	lines.append(_rules_line("【分层门槛与礼包】", ""))
	for line in floor_lines:
		lines.append("[color=#B8C0D4]%s[/color]" % _rules_bb_escape(str(line)))
	var extra: = str(cfg.get("descriptionText", "")).strip_edges()
	if extra != "" and extra.length() > 20 and not extra.contains("分层淘汰"):
		lines.append("")
		lines.append("[color=#B8C0D4]%s[/color]" % _rules_bb_escape(extra))
	return "\n".join(lines)

func _on_rules_pressed() -> void :
	var pack: = _make_borderless_popup(Vector2i(520, 640), "shengsi_rules")
	if pack.is_empty():
		return
	var win: Window = pack.get("win")
	var vbox: VBoxContainer = pack.get("box")
	vbox.add_child(_popup_title("规则说明"))
	var scroll: = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	TouchScrollUtils.configure_scroll(scroll)
	var body: = RichTextLabel.new()
	body.bbcode_enabled = true
	body.fit_content = true
	body.scroll_active = false
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_font_size_override("normal_font_size", 16)
	body.add_theme_color_override("default_color", Color(0.770, 0.750, 0.689))
	body.text = _full_rules_text()
	scroll.add_child(body)
	TouchScrollUtils.bind_content_touch_scroll(scroll, body)
	var close_row: = HBoxContainer.new()
	close_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(close_row)
	close_row.add_child(_popup_close_btn(win))
	_attach_popup(win)
