extends Control
class_name TreasureCaveUI

const UIStyle = preload("res://scripts/ui_style.gd")

const FALLBACK_ROUND_CYCLE_MINUTES: = 21
const TREASURE_ROUND_GAP_SECONDS: = 60
const TREASURE_OPEN_SHANGHAI_START_HOUR: = 9
const TREASURE_OPEN_SHANGHAI_END_HOUR_EXCLUSIVE: = 24
const CHEST_IMAGE_PATH: = "res://assets/items/cangbaoxiang.png"
const COLOR_TITLE: = Color(1.0, 0.88, 0.45, 1.0)
const COLOR_STATUS_MAIN: = Color(0.90, 0.87, 0.78, 1.0)
const COLOR_JOIN_INFO: = Color(0.65, 0.95, 0.75, 1.0)
const COLOR_CARD_TITLE: = Color(1.0, 0.92, 0.62, 1.0)
const COLOR_CARD_STATUS: = Color(0.86, 0.84, 0.78, 1.0)
const COLOR_CARD_PARTICIPANTS: = Color(0.63, 1.0, 0.78, 1.0)
const COLOR_LOG_TITLE: = Color(0.96, 0.91, 0.74, 1.0)
const COLOR_LOG_TEXT: = Color(0.80, 0.79, 0.73, 1.0)
const COLOR_ACTIVITY_LOG: = Color(0.92, 0.82, 0.58, 1.0)
const COLOR_PREV_WINNER: = Color(0.86, 0.84, 0.78, 1.0)
const PREV_WINNER_TITLE_FONT_SIZE: = 13
const PREV_WINNER_NAME_FONT_SIZE: = 15

var game_manager = null
var status_label: Label
var card_row: HBoxContainer
var my_join_label: Label
var my_daily_count_label: Label
var refresh_btn: Button
var mirror_btn: Button
var rules_btn: Button
var _last_status_data: Dictionary = {}
var _countdown_timer: Timer
var log_container: VBoxContainer
var _chest_texture: Texture2D = null
var _joined_chest_id: int = 0
var _chest_ui_states: Array = []
var _last_winner_by_chest_no: Dictionary = {}
var _auto_status_poll_ticks: int = 0
var _round_data_invalid_logged: bool = false

const AUTO_STATUS_POLL_INTERVAL: = 28

const ACTIVITY_LOG_REFRESH_INTERVAL_SEC: = 5

const TREASURE_UI_ACTION_COOLDOWN_SEC: = 1.0
var _join_style_disabled_grey_cached: StyleBoxFlat = null
var _treasure_action_cooldown: bool = false
var _action_cooldown_timer: Timer = null
var _activity_log_dirty: bool = false
var _activity_log_tick_accum: int = 0
var _last_activity_log_render_ms: int = 0
var _join_style_disabled_joined_cached: StyleBoxFlat = null


func _treasure_safe_int(v: Variant, fallback: int = 0) -> int:
	if v == null:
		return fallback
	if v is int:
		return v
	if v is float:
		return int(v)
	if v is bool:
		return 1 if v else 0
	if v is String:
		var s: String = (v as String).strip_edges()
		if s.is_valid_int():
			return s.to_int()
		if s.is_valid_float():
			return int(s.to_float())
		return fallback
	return fallback

static func create_fullscreen(manager) -> TreasureCaveUI:
	var ui: = TreasureCaveUI.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.set_game_manager(manager)
	return ui

func set_game_manager(manager) -> void :
	game_manager = manager

func _stylebox_with_inner_padding(base: StyleBoxFlat, pad_h: int, pad_v: int) -> StyleBoxFlat:
	var s: = base.duplicate() as StyleBoxFlat
	s.content_margin_left = pad_h
	s.content_margin_right = pad_h
	s.content_margin_top = pad_v
	s.content_margin_bottom = pad_v
	return s

func _style_action_bar_button(btn: Button) -> void :
	var n: = StyleBoxFlat.new()
	n.bg_color = Color(0.072, 0.080, 0.079, 0.95)
	n.border_width_left = 2
	n.border_width_right = 2
	n.border_width_top = 2
	n.border_width_bottom = 2
	n.border_color = Color(0.894, 0.770, 0.467, 1)
	n.corner_radius_top_left = 0
	n.corner_radius_top_right = 0
	n.corner_radius_bottom_left = 0
	n.corner_radius_bottom_right = 0
	n = _stylebox_with_inner_padding(n, 14, 10)
	var h: = n.duplicate() as StyleBoxFlat
	h.bg_color = Color(0.072, 0.080, 0.079, 1)
	var p: = n.duplicate() as StyleBoxFlat
	p.bg_color = Color(0.072, 0.080, 0.079, 1)
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", p)

func _style_small_card_button(btn: Button) -> void :
	var n: = StyleBoxFlat.new()
	n.bg_color = Color(0.072, 0.080, 0.079, 0.92)
	n.border_width_left = 1
	n.border_width_right = 1
	n.border_width_top = 1
	n.border_width_bottom = 1
	n.border_color = Color(0.677, 0.549, 0.254, 1)
	n.corner_radius_top_left = 0
	n.corner_radius_top_right = 0
	n.corner_radius_bottom_left = 0
	n.corner_radius_bottom_right = 0
	n = _stylebox_with_inner_padding(n, 10, 8)
	var h: = n.duplicate() as StyleBoxFlat
	h.bg_color = Color(0.072, 0.080, 0.079, 1)
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", h)

func _ready() -> void :
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_chest_texture = load(CHEST_IMAGE_PATH)
	_build_ui()
	_setup_timer()
	_refresh_status(false)

func _build_ui() -> void :
	var root: = VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 18
	root.offset_top = 18
	root.offset_right = -18
	root.offset_bottom = -18
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var title: = Label.new()
	title.text = "🗺 藏宝洞"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", COLOR_TITLE)
	root.add_child(title)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", COLOR_STATUS_MAIN)
	root.add_child(status_label)

	my_join_label = Label.new()
	my_join_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	my_join_label.add_theme_font_size_override("font_size", 15)
	my_join_label.add_theme_color_override("font_color", COLOR_JOIN_INFO)
	root.add_child(my_join_label)

	my_daily_count_label = Label.new()
	my_daily_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	my_daily_count_label.add_theme_font_size_override("font_size", 15)
	my_daily_count_label.add_theme_color_override("font_color", COLOR_JOIN_INFO)
	root.add_child(my_daily_count_label)

	var action_row: = HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 10)
	root.add_child(action_row)

	refresh_btn = Button.new()
	refresh_btn.text = "刷新状态"
	refresh_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	refresh_btn.custom_minimum_size = Vector2(0, 40)
	refresh_btn.add_theme_font_size_override("font_size", 15)
	_style_action_bar_button(refresh_btn)
	refresh_btn.pressed.connect( func(): _refresh_status(true))
	action_row.add_child(refresh_btn)

	mirror_btn = Button.new()
	mirror_btn.text = "更新镜像"
	mirror_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mirror_btn.custom_minimum_size = Vector2(0, 40)
	mirror_btn.add_theme_font_size_override("font_size", 15)
	UIStyle.apply_golden_button_style(mirror_btn)
	mirror_btn.pressed.connect(_open_treasure_mirror)
	action_row.add_child(mirror_btn)

	rules_btn = Button.new()
	rules_btn.text = "规则说明"
	rules_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rules_btn.custom_minimum_size = Vector2(0, 40)
	rules_btn.add_theme_font_size_override("font_size", 15)
	_style_action_bar_button(rules_btn)
	rules_btn.pressed.connect(_show_rules)
	action_row.add_child(rules_btn)

	var card_wrap: = PanelContainer.new()
	card_wrap.custom_minimum_size = Vector2(0, 288)
	card_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var card_wrap_style: = StyleBoxFlat.new()
	card_wrap_style.bg_color = Color(0.072, 0.080, 0.079, 0.92)
	card_wrap_style.border_width_left = 2
	card_wrap_style.border_width_right = 2
	card_wrap_style.border_width_top = 2
	card_wrap_style.border_width_bottom = 2
	card_wrap_style.border_color = Color(0.677, 0.549, 0.254, 1)
	card_wrap_style.corner_radius_top_left = 0
	card_wrap_style.corner_radius_top_right = 0
	card_wrap_style.corner_radius_bottom_left = 0
	card_wrap_style.corner_radius_bottom_right = 0
	card_wrap.add_theme_stylebox_override("panel", card_wrap_style)
	root.add_child(card_wrap)

	var card_margin: = MarginContainer.new()
	card_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	card_margin.add_theme_constant_override("margin_left", 12)
	card_margin.add_theme_constant_override("margin_right", 12)
	card_margin.add_theme_constant_override("margin_top", 12)
	card_margin.add_theme_constant_override("margin_bottom", 12)
	card_wrap.add_child(card_margin)

	card_row = HBoxContainer.new()
	card_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_row.add_theme_constant_override("separation", 6)
	card_margin.add_child(card_row)

	var log_panel: = PanelContainer.new()
	log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var log_style: = StyleBoxFlat.new()
	log_style.bg_color = Color(0.060, 0.068, 0.069, 0.95)
	log_style.border_width_left = 2
	log_style.border_width_right = 2
	log_style.border_width_top = 2
	log_style.border_width_bottom = 2
	log_style.border_color = Color(0.655, 0.531, 0.245, 1)
	log_style.corner_radius_top_left = 0
	log_style.corner_radius_top_right = 0
	log_style.corner_radius_bottom_left = 0
	log_style.corner_radius_bottom_right = 0
	log_panel.add_theme_stylebox_override("panel", log_style)
	root.add_child(log_panel)

	var log_margin: = MarginContainer.new()
	log_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	log_margin.add_theme_constant_override("margin_left", 12)
	log_margin.add_theme_constant_override("margin_right", 12)
	log_margin.add_theme_constant_override("margin_top", 10)
	log_margin.add_theme_constant_override("margin_bottom", 12)
	log_panel.add_child(log_margin)

	var log_vbox: = VBoxContainer.new()
	log_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_vbox.add_theme_constant_override("separation", 8)
	log_margin.add_child(log_vbox)

	var log_title: = Label.new()
	log_title.text = "📜 藏宝洞日志"
	log_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	log_title.add_theme_font_size_override("font_size", 20)
	log_title.add_theme_color_override("font_color", COLOR_LOG_TITLE)
	log_vbox.add_child(log_title)

	var log_scroll: = ScrollContainer.new()
	log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_vbox.add_child(log_scroll)

	log_container = VBoxContainer.new()
	log_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_container.add_theme_constant_override("separation", 4)
	log_scroll.add_child(log_container)

func _setup_timer() -> void :
	_countdown_timer = Timer.new()
	_countdown_timer.wait_time = 1.0
	_countdown_timer.autostart = true
	_countdown_timer.one_shot = false
	add_child(_countdown_timer)
	_countdown_timer.timeout.connect(_on_tick)

	_action_cooldown_timer = Timer.new()
	_action_cooldown_timer.one_shot = true
	_action_cooldown_timer.wait_time = TREASURE_UI_ACTION_COOLDOWN_SEC
	_action_cooldown_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_action_cooldown_timer)
	_action_cooldown_timer.timeout.connect(_on_treasure_ui_action_cooldown_end)

func _on_tick() -> void :
	if not _last_status_data.is_empty() and _last_status_data.has("secondsToNextRoundStart"):
		var sn: = _treasure_safe_int(_last_status_data.get("secondsToNextRoundStart", 0), 0)
		if sn > 0:
			_last_status_data["secondsToNextRoundStart"] = sn - 1
	_update_header_text()
	_tick_chest_countdowns()
	_activity_log_tick_accum += 1
	if _activity_log_tick_accum >= ACTIVITY_LOG_REFRESH_INTERVAL_SEC:
		_activity_log_tick_accum = 0
		if _activity_log_dirty and not _last_status_data.is_empty():
			var act_refresh = _last_status_data.get("activityLog", [])
			if act_refresh is Array:
				_render_activity_log_from_server(act_refresh)
			_activity_log_dirty = false
			_last_activity_log_render_ms = Time.get_ticks_msec()
	_auto_status_poll_ticks += 1
	if _auto_status_poll_ticks >= AUTO_STATUS_POLL_INTERVAL:
		_auto_status_poll_ticks = 0
		if game_manager and game_manager.network:
			_refresh_status(false)

func _refresh_status(use_action_cooldown: bool = false) -> void :
	if not game_manager or not game_manager.network:
		status_label.text = "网络未初始化"
		return
	if use_action_cooldown and not _begin_treasure_ui_action_or_return():
		return
	game_manager.network.treasure_status_loaded.connect(_on_status_loaded, CONNECT_ONE_SHOT)
	game_manager.network.treasure_get_status()

func _resolve_joined_chest_no(data: Dictionary, joined_chest_id: int) -> int:
	var from_api: = _treasure_safe_int(data.get("joinedChestNo", 0), 0)
	if from_api > 0:
		return from_api
	if joined_chest_id <= 0:
		return 0
	for ch in data.get("chests", []):
		if ch is Dictionary and _treasure_safe_int(ch.get("id", 0), 0) == joined_chest_id:
			return _treasure_safe_int(ch.get("chest_no", 0), 0)
	return 0

func _format_my_join_line(data: Dictionary, joined_chest_id: int) -> String:
	var no: = _resolve_joined_chest_no(data, joined_chest_id)
	if no > 0:
		return "你已入%d号秘箱战序，争夺将启" % no
	if joined_chest_id <= 0:
		return "你本轮尚未择定任一秘箱入阵"
	return "你已入阵，秘箱编号同步中"

func _format_daily_join_line(data: Dictionary) -> String:
	var used: = _treasure_safe_int(data.get("todayJoinCount", 0), 0)
	var limit: = _treasure_safe_int(data.get("dailyJoinLimit", 0), 0)
	if limit <= 0:
		return "今日夺宝次数：0/0"
	used = clampi(used, 0, limit)
	return "今日夺宝次数：%d/%d" % [used, limit]

func _on_status_loaded(data: Dictionary) -> void :
	_last_status_data = data.duplicate(true)
	_chest_ui_states.clear()
	for c in card_row.get_children():
		c.queue_free()
	if data.is_empty():
		status_label.text = "暂时无法获取藏宝洞状态"
		my_join_label.text = ""
		my_daily_count_label.text = ""
		_last_winner_by_chest_no.clear()
		_render_placeholder_cards(0)
		_add_log("状态同步失败，显示占位卡片")
		return
	_last_winner_by_chest_no.clear()
	var raw_round = data.get("round", null)
	if not (raw_round is Dictionary):
		if not _round_data_invalid_logged:
			push_warning("TreasureCaveUI: 状态字段 round 缺失或异常，已使用默认轮次显示")
			_round_data_invalid_logged = true
	else:
		_round_data_invalid_logged = false
	for w in data.get("lastRoundChestWinners", []):
		if w is Dictionary:
			var cn: = _treasure_safe_int(w.get("chest_no", 0), 0)
			if cn > 0:
				_last_winner_by_chest_no[cn] = str(w.get("winner_name", "")).strip_edges()
	_update_header_text()
	var joined_id = _treasure_safe_int(data.get("joinedChestId", 0), 0)
	_joined_chest_id = joined_id
	my_join_label.text = _format_my_join_line(data, joined_id)
	my_daily_count_label.text = _format_daily_join_line(data)
	var act_log = data.get("activityLog", [])
	if act_log is Array:
		if _last_activity_log_render_ms == 0 and not act_log.is_empty():
			_render_activity_log_from_server(act_log)
			_last_activity_log_render_ms = Time.get_ticks_msec()
			_activity_log_dirty = false
		else:
			_activity_log_dirty = true
	var chests: Array = data.get("chests", [])
	if chests.is_empty():
		_render_placeholder_cards(joined_id)
		_add_log("状态刷新完成")
		return
	var cards: Array = chests.duplicate()
	while cards.size() < 3:
		cards.append({
			"id": 0, 
			"chest_no": cards.size() + 1, 
			"status": "pending", 
			"participants": 0, 
			"remain_sec": _seconds_to_next_round()
		})
	cards = cards.slice(0, 3)
	for chest in cards:
		card_row.add_child(_build_chest_card(chest, joined_id))
	_add_log("状态刷新完成")

func _render_placeholder_cards(joined_id: int) -> void :
	var remain = _seconds_to_next_round()
	for i in range(1, 4):
		var placeholder = {
			"id": 0, 
			"chest_no": i, 
			"status": "pending", 
			"participants": 0, 
			"remain_sec": remain
		}
		card_row.add_child(_build_chest_card(placeholder, joined_id))

func _seconds_to_next_round() -> int:
	if not _last_status_data.is_empty() and _last_status_data.has("secondsToNextRoundStart"):
		var v = _last_status_data.get("secondsToNextRoundStart", -1)
		var iv: = -1
		if v is int or v is float:
			iv = int(v)
		elif v is String:
			iv = int(str(v).strip_edges())
		if iv > 0:
			return iv
	if not _last_status_data.is_empty() and _last_status_data.get("round") is Dictionary:
		var round_dict: Dictionary = _last_status_data.get("round", {})
		var be_unix: = _parse_datetime_to_unix(str(round_dict.get("battle_ends_at", "")))
		if be_unix > 0:
			var now_unix: = int(Time.get_unix_time_from_system())
			var remain_server: int = maxi(0, be_unix + TREASURE_ROUND_GAP_SECONDS - now_unix)
			if remain_server > 0:
				return remain_server
	var by_hour_schedule: = _seconds_to_next_hour_round_by_schedule()
	if by_hour_schedule >= 0:
		return by_hour_schedule
	var t = Time.get_datetime_dict_from_system()
	var minute_of_day: int = int(t.hour) * 60 + int(t.minute)
	var cyc: = FALLBACK_ROUND_CYCLE_MINUTES
	var next_bucket_start = ((minute_of_day / cyc) + 1) * cyc
	var delta_minutes = next_bucket_start - minute_of_day
	var remain = delta_minutes * 60 - int(t.second)
	if remain <= 0:
		remain += cyc * 60
	return remain

func _seconds_to_next_hour_round_by_schedule() -> int:
	var now_dt: = Time.get_datetime_dict_from_system()
	var now_unix: = int(Time.get_unix_time_from_system())
	var hour: = int(now_dt.hour)
	var minute: = int(now_dt.minute)
	var second: = int(now_dt.second)
	var this_hour_start_unix: = now_unix - minute * 60 - second
	if hour >= TREASURE_OPEN_SHANGHAI_START_HOUR and hour < TREASURE_OPEN_SHANGHAI_END_HOUR_EXCLUSIVE:
		if hour >= TREASURE_OPEN_SHANGHAI_END_HOUR_EXCLUSIVE - 1:
			var next_open_unix: = _today_at_hour_to_unix(TREASURE_OPEN_SHANGHAI_START_HOUR, true)
			return maxi(0, next_open_unix - now_unix)
		var next_hour_unix: = this_hour_start_unix + 3600
		return maxi(0, next_hour_unix - now_unix)
	var next_open_today: = _today_at_hour_to_unix(TREASURE_OPEN_SHANGHAI_START_HOUR, false)
	if now_unix < next_open_today:
		return maxi(0, next_open_today - now_unix)
	var next_open_tomorrow: = _today_at_hour_to_unix(TREASURE_OPEN_SHANGHAI_START_HOUR, true)
	return maxi(0, next_open_tomorrow - now_unix)

func _today_at_hour_to_unix(hour: int, next_day: bool) -> int:
	var dt: = Time.get_datetime_dict_from_system()
	var y: = int(dt.year)
	var m: = int(dt.month)
	var d: = int(dt.day)
	if next_day:
		var now_u: = int(Time.get_unix_time_from_system())
		var tomorrow_u: = now_u + 24 * 60 * 60
		var td: = Time.get_datetime_dict_from_unix_time(tomorrow_u)
		y = int(td.year)
		m = int(td.month)
		d = int(td.day)
	var iso: = "%04d-%02d-%02dT%02d:00:00" % [y, m, d, hour]
	return int(Time.get_unix_time_from_datetime_string(iso))

func _parse_datetime_to_unix(raw: String) -> int:
	var s: = raw.strip_edges()
	if s.is_empty():
		return 0
	var normalized: = s
	if normalized.find("T") < 0 and normalized.find(" ") >= 0:
		normalized = normalized.replace(" ", "T")
	var ts: = int(Time.get_unix_time_from_datetime_string(normalized))
	if ts > 0:
		return ts
	var dot_idx: = normalized.find(".")
	if dot_idx > 0:
		var trimmed: = normalized.substr(0, dot_idx)
		if normalized.ends_with("Z"):
			trimmed += "Z"
		ts = int(Time.get_unix_time_from_datetime_string(trimmed))
		if ts > 0:
			return ts
	return 0

func _format_seconds(sec: int) -> String:
	var s = maxi(0, sec)
	var m = s / 60
	var r = s % 60
	return "%02d:%02d" % [m, r]

func _joined_phase_join_button_text(chest_status: String, remain_sec: int) -> String:
	var cd: = _format_seconds(remain_sec)
	if chest_status == "signup_open":
		return "准备中 %s" % cd
	if chest_status == "battle_running":
		return "争夺中 %s" % cd
	return ""

func _status_to_cn(status: String) -> String:
	match status:
		"pending":
			return "未刷新"
		"signup_open":
			return "备战期"
		"battle_running":
			return "争夺期"
		"finished":
			return "已结算"
		_:
			return "未知"

func _ensure_join_disabled_styles() -> void :
	if _join_style_disabled_grey_cached != null:
		return
	_join_style_disabled_grey_cached = StyleBoxFlat.new()
	_join_style_disabled_grey_cached.bg_color = Color(0.072, 0.080, 0.079, 0.9)
	_join_style_disabled_grey_cached.border_width_left = 1
	_join_style_disabled_grey_cached.border_width_right = 1
	_join_style_disabled_grey_cached.border_width_top = 1
	_join_style_disabled_grey_cached.border_width_bottom = 1
	_join_style_disabled_grey_cached.border_color = Color(0.655, 0.531, 0.245, 1)
	_join_style_disabled_grey_cached.corner_radius_top_left = 0
	_join_style_disabled_grey_cached.corner_radius_top_right = 0
	_join_style_disabled_grey_cached.corner_radius_bottom_left = 0
	_join_style_disabled_grey_cached.corner_radius_bottom_right = 0
	_join_style_disabled_grey_cached = _stylebox_with_inner_padding(_join_style_disabled_grey_cached, 10, 8)
	_join_style_disabled_joined_cached = StyleBoxFlat.new()
	_join_style_disabled_joined_cached.bg_color = Color(0.18, 0.52, 0.42, 0.98)
	_join_style_disabled_joined_cached.border_width_left = 1
	_join_style_disabled_joined_cached.border_width_right = 1
	_join_style_disabled_joined_cached.border_width_top = 1
	_join_style_disabled_joined_cached.border_width_bottom = 1
	_join_style_disabled_joined_cached.border_color = Color(0.45, 0.85, 0.7, 1)
	_join_style_disabled_joined_cached.corner_radius_top_left = 0
	_join_style_disabled_joined_cached.corner_radius_top_right = 0
	_join_style_disabled_joined_cached.corner_radius_bottom_left = 0
	_join_style_disabled_joined_cached.corner_radius_bottom_right = 0
	_join_style_disabled_joined_cached = _stylebox_with_inner_padding(_join_style_disabled_joined_cached, 10, 8)

func _apply_join_btn_disabled_style(join_btn: Button, joined_active: bool) -> void :
	if not is_instance_valid(join_btn):
		return
	_ensure_join_disabled_styles()
	if joined_active:
		join_btn.add_theme_stylebox_override("disabled", _join_style_disabled_joined_cached)
	else:
		join_btn.add_theme_stylebox_override("disabled", _join_style_disabled_grey_cached)

func _update_header_text() -> void :
	if _last_status_data.is_empty():
		status_label.text = "正在同步藏宝洞状态..."
		return
	var open_now = bool(_last_status_data.get("openNow", false))
	var raw_round = _last_status_data.get("round", null)
	var round_dict: Dictionary = raw_round if raw_round is Dictionary else {}
	var round_idx: = _treasure_safe_int(round_dict.get("round_index_today", 0), 0)
	var round_disp: = ("%d轮" % round_idx) if round_idx > 0 else "—"
	var cd = _format_seconds(_seconds_to_next_round())
	status_label.text = "开放状态: %s  当前轮次: %s  下轮倒计时: %s" % ["开启中" if open_now else "未开启", round_disp, cd]

func _build_chest_card(chest: Dictionary, joined_id: int) -> PanelContainer:
	var panel: = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 278)
	var style: = StyleBoxFlat.new()
	style.bg_color = Color(0.072, 0.080, 0.079, 0.95)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.714, 0.578, 0.267, 1)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	panel.add_theme_stylebox_override("panel", style)
	var vb: = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	panel.add_child(vb)

	var chest_id = _treasure_safe_int(chest.get("id", 0), 0)
	var chest_no = _treasure_safe_int(chest.get("chest_no", 0), 0)
	var prev_name: = str(_last_winner_by_chest_no.get(chest_no, "")).strip_edges()
	var prev_title_lbl: = Label.new()
	prev_title_lbl.text = "上轮得主"
	prev_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prev_title_lbl.add_theme_font_size_override("font_size", PREV_WINNER_TITLE_FONT_SIZE)
	prev_title_lbl.add_theme_color_override("font_color", COLOR_PREV_WINNER)
	vb.add_child(prev_title_lbl)
	var prev_name_lbl: = Label.new()
	prev_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prev_name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prev_name_lbl.add_theme_font_size_override("font_size", PREV_WINNER_NAME_FONT_SIZE)
	prev_name_lbl.add_theme_color_override("font_color", COLOR_PREV_WINNER)
	prev_name_lbl.text = "—" if prev_name.is_empty() else prev_name
	vb.add_child(prev_name_lbl)

	var image_placeholder: = TextureRect.new()
	image_placeholder.custom_minimum_size = Vector2(0, 130)
	image_placeholder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	image_placeholder.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image_placeholder.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image_placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _chest_texture:
		image_placeholder.texture = _chest_texture
		image_placeholder.modulate = Color(1, 1, 1, 1)
	else:
		image_placeholder.modulate = Color(0.791, 0.769, 0.708, 0.2)
	vb.add_child(image_placeholder)
	var chest_status = str(chest.get("status", "unknown"))
	var participants = _treasure_safe_int(chest.get("participants", 0), 0)
	var remain_sec = _treasure_safe_int(chest.get("remain_sec", _seconds_to_next_round()), 0)

	var title: = Label.new()
	title.text = "藏宝匣 #%d" % chest_no
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", COLOR_CARD_TITLE)
	vb.add_child(title)

	var stat_row: = HBoxContainer.new()
	stat_row.add_theme_constant_override("separation", 8)
	vb.add_child(stat_row)

	var status_tag: = Label.new()
	status_tag.text = "状态: %s" % _status_to_cn(chest_status)
	status_tag.add_theme_font_size_override("font_size", 14)
	status_tag.add_theme_color_override("font_color", COLOR_CARD_STATUS)
	status_tag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stat_row.add_child(status_tag)

	var participant_tag: = Label.new()
	if chest_status == "signup_open" and chest_id > 0:
		participant_tag.text = "参与: —"
	else:
		participant_tag.text = "参与: %d" % participants
	participant_tag.add_theme_font_size_override("font_size", 14)
	participant_tag.add_theme_color_override("font_color", COLOR_CARD_PARTICIPANTS)
	participant_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	participant_tag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stat_row.add_child(participant_tag)

	var join_btn: = Button.new()
	var is_joined_chest: = joined_id > 0 and chest_id == joined_id
	join_btn.text = "参与抢夺"
	join_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	join_btn.custom_minimum_size = Vector2(0, 38)
	join_btn.add_theme_font_size_override("font_size", 15)
	var join_style: = StyleBoxFlat.new()
	join_style.bg_color = Color(0.118, 0.100, 0.058, 0.95)
	join_style.border_width_left = 1
	join_style.border_width_right = 1
	join_style.border_width_top = 1
	join_style.border_width_bottom = 1
	join_style.border_color = Color(1, 0.78, 0.45, 1)
	join_style.corner_radius_top_left = 0
	join_style.corner_radius_top_right = 0
	join_style.corner_radius_bottom_left = 0
	join_style.corner_radius_bottom_right = 0
	join_style = _stylebox_with_inner_padding(join_style, 10, 8)
	join_btn.add_theme_stylebox_override("normal", join_style)
	var join_hover: = join_style.duplicate()
	join_hover.bg_color = Color(0.118, 0.100, 0.058, 1)
	join_btn.add_theme_stylebox_override("hover", join_hover)
	_ensure_join_disabled_styles()
	join_btn.add_theme_stylebox_override("disabled", _join_style_disabled_grey_cached)
	var can_join = chest_status == "signup_open" and chest_id > 0 and (joined_id == 0 or joined_id == chest_id)
	if chest_status == "finished":
		join_btn.text = "本轮已结算"
		join_btn.disabled = true
		_apply_join_btn_disabled_style(join_btn, false)
	elif is_joined_chest and (chest_status == "signup_open" or chest_status == "battle_running"):
		join_btn.text = _joined_phase_join_button_text(chest_status, remain_sec)
		join_btn.disabled = true
		_apply_join_btn_disabled_style(join_btn, true)
	else:
		join_btn.disabled = not can_join
		var phase_btn: = _joined_phase_join_button_text(chest_status, remain_sec)
		if not phase_btn.is_empty():
			join_btn.text = phase_btn
		else:
			join_btn.text = "参与抢夺"
		if join_btn.disabled:
			_apply_join_btn_disabled_style(join_btn, false)
	join_btn.pressed.connect( func(): _on_join_chest_button(chest_id, chest_no))
	vb.add_child(join_btn)

	var btn_row: = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 4)
	vb.add_child(btn_row)

	var list_btn: = Button.new()
	list_btn.text = "查看参与名单"
	list_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_btn.custom_minimum_size = Vector2(0, 34)
	list_btn.add_theme_font_size_override("font_size", 13)
	_style_small_card_button(list_btn)
	list_btn.disabled = chest_id <= 0 or chest_status == "signup_open"
	list_btn.pressed.connect( func(): _show_participants(chest_id, chest_no))
	btn_row.add_child(list_btn)

	var log_btn: = Button.new()
	log_btn.text = "查看战斗日志"
	log_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_btn.custom_minimum_size = Vector2(0, 34)
	log_btn.add_theme_font_size_override("font_size", 13)
	_style_small_card_button(log_btn)
	log_btn.disabled = chest_id <= 0
	log_btn.pressed.connect( func(): _show_battle_log(chest_id, chest_no))
	btn_row.add_child(log_btn)

	_chest_ui_states.append({
		"chest_id": chest_id, 
		"chest_no": chest_no, 
		"status": chest_status, 
		"remain_sec": remain_sec, 
		"join_btn": join_btn, 
		"list_btn": list_btn, 
		"log_btn": log_btn, 
	})

	return panel

func _begin_treasure_ui_action_or_return() -> bool:
	if _treasure_action_cooldown:
		return false
	if _action_cooldown_timer == null:
		return true
	_treasure_action_cooldown = true
	refresh_btn.disabled = true
	if is_instance_valid(mirror_btn):
		mirror_btn.disabled = true
	rules_btn.disabled = true
	for st in _chest_ui_states:
		if not (st is Dictionary):
			continue
		for k in ["join_btn", "list_btn", "log_btn"]:
			var b: Button = st.get(k)
			if is_instance_valid(b):
				b.disabled = true
	_action_cooldown_timer.start()
	return true

func _on_treasure_ui_action_cooldown_end() -> void :
	_treasure_action_cooldown = false
	if not is_instance_valid(refresh_btn):
		return
	refresh_btn.disabled = false
	if is_instance_valid(mirror_btn):
		mirror_btn.disabled = false
	rules_btn.disabled = false
	_reapply_secondary_card_buttons()
	_tick_chest_countdowns()

func _reapply_secondary_card_buttons() -> void :
	for st in _chest_ui_states:
		if not (st is Dictionary):
			continue
		var cid: = _treasure_safe_int(st.get("chest_id", 0), 0)
		var cst: = str(st.get("status", ""))
		var lb: Button = st.get("list_btn")
		if is_instance_valid(lb):
			lb.disabled = cid <= 0 or cst == "signup_open"
		var gb: Button = st.get("log_btn")
		if is_instance_valid(gb):
			gb.disabled = cid <= 0

func _on_join_chest_button(chest_id: int, chest_no: int) -> void :
	if not _begin_treasure_ui_action_or_return():
		return
	_join_chest(chest_id, chest_no)

func _join_chest(chest_id: int, chest_no: int) -> void :
	game_manager.network.treasure_join_success.connect( func(data: Dictionary):
		var cn: = _treasure_safe_int(data.get("joinedChestNo", 0), 0)
		var used: = _treasure_safe_int(data.get("todayJoinCount", 0), -1)
		var limit: = _treasure_safe_int(data.get("dailyLimit", 0), -1)
		if used >= 0 and limit > 0:
			my_daily_count_label.text = "今日夺宝次数：%d/%d" % [clampi(used, 0, limit), limit]
		if cn > 0:
			_show_message("已入%d号宝箱战序，静待争杀开启" % cn)
		else:
			_show_message("已入此箱战序，静待争杀开启")
		_add_log("已择定%d号秘箱入阵" % chest_no)
		_refresh_status(false)
	, CONNECT_ONE_SHOT)
	game_manager.network.treasure_join_failed.connect( func(err: String):
		_show_message("入阵失败：%s" % err)
		_add_log("择定%d号秘箱失败：%s" % [chest_no, err])
	, CONNECT_ONE_SHOT)
	game_manager.network.treasure_join(chest_id)

func _show_participants(chest_id: int, chest_no: int) -> void :
	if not _last_status_data.is_empty():
		var rr = _last_status_data.get("round", null)
		if rr is Dictionary and str(rr.get("status", "")) == "signup_open":
			_show_message("争夺开始后方可查看参与名单")
			return
		for ch in _last_status_data.get("chests", []):
			if ch is Dictionary and _treasure_safe_int(ch.get("id", 0), 0) == chest_id:
				if str(ch.get("status", "")) == "signup_open":
					_show_message("争夺开始后方可查看参与名单")
					return
				break
	if not _begin_treasure_ui_action_or_return():
		return
	game_manager.network.treasure_participants_loaded.connect( func(rows: Array):
		var lines: Array[String] = []
		for row in rows:
			lines.append("%s (战力:%s)" % [str(row.get("nickname", "未知")), str(row.get("seed_score", 0))])
		if lines.is_empty():
			lines.append("暂无修士入列此箱")
		_show_message("第%d号宝箱争夺名册：\n%s" % [chest_no, "\n".join(lines)])
		_add_log("查看了藏宝匣 #%d 参与名单（%d人）" % [chest_no, rows.size()])
	, CONNECT_ONE_SHOT)
	game_manager.network.treasure_get_participants(chest_id)

func _treasure_user_id_field(v: Variant) -> int:
	return _treasure_safe_int(v, 0)


func _parse_treasure_battle_log_json(raw: Variant) -> Array:
	if raw == null:
		return []
	var v: Variant = raw
	if typeof(v) == TYPE_STRING:
		var s: = str(v).strip_edges()
		if s.is_empty():
			return []
		var pj: = JSON.new()
		if pj.parse(s) != OK:
			return []
		v = pj.data
	if v is Array:
		return v as Array
	return []


func _treasure_battle_log_has_combat_steps(log: Array) -> bool:
	for e in log:
		if not (e is Dictionary):
			continue
		var t: = str((e as Dictionary).get("type", ""))
		if t == "round" or t == "attack" or t == "triple_shot_hit" or t == "kuihua_hit":
			return true
	return false


func _format_treasure_battle_log_line(entry: Dictionary, side_map: Dictionary = {}) -> String:
	var t: = str(entry.get("type", ""))
	var ally_color: = "#66E08A"
	var enemy_color: = "#FF7FB3"
	var neutral_color: = "#E8E8E8"
	var accent_color: = "#FFD27A"
	match t:
		"start", "info":
			return "[color=%s]%s[/color]" % [neutral_color, _bbcode_escape(str(entry.get("message", "")).strip_edges())]
		"player_info":
			return "[color=%s]【我方修士】%s：HP %s/%s 攻%s 防%s 敏%s 属%s[/color]" % [
				ally_color, 
				_bbcode_escape(str(entry.get("name", "?"))), 
				_fmt_battle_int(entry.get("hp", "?")), 
				_fmt_battle_int(entry.get("maxHp", "?")), 
				_fmt_battle_int(entry.get("attack", "?")), 
				_fmt_battle_int(entry.get("defense", "?")), 
				_fmt_battle_int(entry.get("agility", "?")), 
				_bbcode_escape(str(entry.get("element", "?"))), 
			]
		"pet_info":
			return "[color=%s]【我方灵兽】%s：HP %s/%s 攻%s 防%s 敏%s 属%s[/color]" % [
				ally_color, 
				_bbcode_escape(str(entry.get("name", "?"))), 
				_fmt_battle_int(entry.get("hp", "?")), 
				_fmt_battle_int(entry.get("maxHp", "?")), 
				_fmt_battle_int(entry.get("attack", "?")), 
				_fmt_battle_int(entry.get("defense", "?")), 
				_fmt_battle_int(entry.get("agility", "?")), 
				_bbcode_escape(str(entry.get("element", "?"))), 
			]
		"enemy_info", "enemy_pet_info":
			return "[color=%s]【敌方】%s：HP %s/%s 攻%s 防%s 敏%s 属%s[/color]" % [
				enemy_color, 
				_bbcode_escape(str(entry.get("name", "?"))), 
				_fmt_battle_int(entry.get("hp", "?")), 
				_fmt_battle_int(entry.get("maxHp", "?")), 
				_fmt_battle_int(entry.get("attack", "?")), 
				_fmt_battle_int(entry.get("defense", "?")), 
				_fmt_battle_int(entry.get("agility", "?")), 
				_bbcode_escape(str(entry.get("element", "?"))), 
			]
		"round":
			# JSON 里的数字到 GDScript 是 float，直接 str() 会印成「第 1.0 回合」
			return "[color=%s]—— 第 %s 回合 ——[/color]" % [accent_color, _bbcode_escape(_fmt_battle_int(entry.get("round", "?")))]
		"miss":
			var miss_attacker: = str(entry.get("attacker", "?"))
			var miss_color: = _battle_side_color(str(entry.get("attackerRole", "")), miss_attacker, ally_color, enemy_color, side_map)
			return "[color=%s]【%s】对【%s】出手未中[/color]" % [miss_color, _bbcode_escape(miss_attacker), _bbcode_escape(str(entry.get("target", "?")))]
		"dodge":
			var dodge_target: = str(entry.get("target", "?"))
			var dodge_color: = _battle_side_color(str(entry.get("targetRole", "")), dodge_target, ally_color, enemy_color, side_map)
			return "[color=%s]【%s】闪过了【%s】的攻势[/color]" % [dodge_color, _bbcode_escape(dodge_target), _bbcode_escape(str(entry.get("attacker", "?")))]
		"attack", "triple_shot_hit", "kuihua_hit":
			var dmg: = _fmt_battle_int(entry.get("damage", 0))
			var attacker: = str(entry.get("attacker", "?"))
			var target: = str(entry.get("target", "?"))
			var side_color: = _battle_side_color(str(entry.get("attackerRole", "")), attacker, ally_color, enemy_color, side_map)
			var skill_name: = str(entry.get("skillName", entry.get("skill_name", ""))).strip_edges()
			if skill_name.is_empty() and t == "triple_shot_hit":
				skill_name = "一击三伤"
			elif skill_name.is_empty() and t == "kuihua_hit":
				skill_name = "点穴手"
			var skill_prefix: = ("【%s】" % _bbcode_escape(skill_name)) if not skill_name.is_empty() else ""
			var line: = "[color=%s]%s【%s】攻【%s】造成 %s 伤害" % [side_color, skill_prefix, _bbcode_escape(attacker), _bbcode_escape(target), dmg]
			if entry.has("targetHp"):
				var thp = entry.get("targetHp")
				var tmh = entry.get("targetMaxHp", null)
				if tmh != null:
					line += "（目标剩余 HP %s/%s）" % [_fmt_battle_int(thp), _fmt_battle_int(tmh)]
				else:
					line += "（目标剩余 HP %s）" % _fmt_battle_int(thp)
			var em: = str(entry.get("elementMsg", "")).strip_edges()
			var noble_pct: = int(entry.get("noblePetBonusPercent", 0))
			if noble_pct > 0 and entry.get("isPetAttack", false) and em.find("贵族+") < 0:
				if em.is_empty():
					em = "（贵族+%d%%）" % noble_pct
				else:
					em = "%s （贵族+%d%%）" % [em, noble_pct]
			if not em.is_empty():
				line += " %s" % _bbcode_escape(em)
			line += "[/color]"
			return line
		"combo_trigger":
			return "[color=%s]%s[/color]" % [accent_color, _bbcode_escape(str(entry.get("message", "连击触发")).strip_edges())]
		"combo_attack":
			var combo_attacker: = str(entry.get("attacker", "?"))
			var combo_color: = _battle_side_color(str(entry.get("attackerRole", "")), combo_attacker, ally_color, enemy_color, side_map)
			return "[color=%s]连击追击：【%s】[/color]" % [combo_color, _bbcode_escape(combo_attacker)]
		"joint_attack":
			return "[color=%s]合击：【%s】与【%s】齐攻【%s】[/color]" % [
				ally_color, 
				_bbcode_escape(str(entry.get("player", "?"))), 
				_bbcode_escape(str(entry.get("pet", "?"))), 
				_bbcode_escape(str(entry.get("target", "?"))), 
			]
		"enemy_dead":
			return "[color=%s]【%s】败退离场[/color]" % [enemy_color, _bbcode_escape(str(entry.get("name", "?")))]
		"pet_dead":
			return "[color=%s]【%s】灵兽力竭[/color]" % [ally_color, _bbcode_escape(str(entry.get("name", "?")))]
		"player_dead":
			return "[color=%s]【%s】修士力竭[/color]" % [ally_color, _bbcode_escape(str(entry.get("name", "?")))]
		"victory", "defeat":
			return "[color=%s]%s[/color]" % [accent_color, _bbcode_escape(str(entry.get("message", t)).strip_edges())]
		"empty", "solo_win", "bye":
			return "[color=%s]%s[/color]" % [neutral_color, _bbcode_escape(str(entry.get("text", "")).strip_edges())]
		"skill_splash":
			var ms: = str(entry.get("message", "")).strip_edges()
			if not ms.is_empty():
				return "[color=#7FD4FF]%s[/color]" % _bbcode_escape(ms)
			return "[color=#7FD4FF]【溅墨】[color=#E8E8E8]%s[/color] 波及 [color=#E8E8E8]%s[/color]，伤害 [color=#FFB86B]%s[/color]（剩余 HP %s/%s）[/color]" % [
				_bbcode_escape(str(entry.get("attacker", "?"))), 
				_bbcode_escape(str(entry.get("target", "?"))), 
				_fmt_battle_int(entry.get("damage", 0)), 
				_fmt_battle_int(entry.get("targetHp", "?")), 
				_fmt_battle_int(entry.get("targetMaxHp", "?")), 
			]
		"skill_double_shot":
			var md: = str(entry.get("message", "")).strip_edges()
			if not md.is_empty():
				return "[color=#FFD27A]%s[/color]" % _bbcode_escape(md)
			return "[color=#FFD27A]【连击】第 %s 段 [color=#E8E8E8]%s[/color] → [color=#E8E8E8]%s[/color]，伤害 [color=#FFB86B]%s[/color]（剩余 HP %s/%s）[/color]" % [
				_bbcode_escape(str(entry.get("hitIndex", "?"))), 
				_bbcode_escape(str(entry.get("attacker", "?"))), 
				_bbcode_escape(str(entry.get("target", "?"))), 
				_fmt_battle_int(entry.get("damage", 0)), 
				_fmt_battle_int(entry.get("targetHp", "?")), 
				_fmt_battle_int(entry.get("targetMaxHp", "?")), 
			]
		"skill_divine_protect":
			var mdv: = str(entry.get("message", "")).strip_edges()
			if not mdv.is_empty():
				return "[color=#B8F28A]%s[/color]" % _bbcode_escape(mdv)
			return "[color=#B8F28A]【护主】[color=#E8E8E8]%s[/color] 触发，恢复后生命约 [color=#FFB86B]%s[/color][/color]" % [
				_bbcode_escape(str(entry.get("target", "?"))), 
				_fmt_battle_int(entry.get("hpRestored", "?")), 
			]
		"skill_counter_attack":
			var mc: = str(entry.get("message", "")).strip_edges()
			if not mc.is_empty():
				return "[color=#FFB86B]%s[/color]" % _bbcode_escape(mc)
			return "[color=#FFB86B]【反打】[color=#E8E8E8]%s[/color] 反击 [color=#E8E8E8]%s[/color]，伤害 [color=#FF9F7A]%s[/color]（目标剩余 HP %s/%s）[/color]" % [
				_bbcode_escape(str(entry.get("attacker", "?"))), 
				_bbcode_escape(str(entry.get("target", "?"))), 
				_fmt_battle_int(entry.get("damage", 0)), 
				_fmt_battle_int(entry.get("targetHp", "?")), 
				_fmt_battle_int(entry.get("targetMaxHp", "?")), 
			]
		_:
			var msg_only: = str(entry.get("message", "")).strip_edges()
			if not msg_only.is_empty():
				return "[color=%s]%s[/color]" % [neutral_color, _bbcode_escape(msg_only)]
			return "[color=%s]战斗记录：%s[/color]" % [neutral_color, _bbcode_escape(str(entry.get("type", "未知")))]


func _bbcode_escape(text: String) -> String:
	return text.replace("[", "\\[").replace("]", "\\]")

func _fmt_battle_int(v: Variant) -> String:
	if v == null:
		return "0"
	match typeof(v):
		TYPE_INT:
			return str(int(v))
		TYPE_FLOAT:
			return str(int(round(float(v))))
		TYPE_STRING:
			var s: = str(v).strip_edges()
			if s.is_empty():
				return "0"
			return str(int(round(s.to_float())))
		_:
			return _bbcode_escape(str(v))

func _battle_side_color(role_raw: String, actor_name: String, ally_color: String, enemy_color: String, side_map: Dictionary = {}) -> String:
	var role: = role_raw.strip_edges().to_lower()
	if role == "enemy":
		return enemy_color
	if role == "ally" or role == "self" or role == "player":
		return ally_color
	var n: = actor_name.strip_edges()
	if not side_map.is_empty():
		var key: = _normalize_battle_actor_name(n)
		if side_map.has(n):
			return enemy_color if str(side_map.get(n, "ally")) == "enemy" else ally_color
		if side_map.has(key):
			return enemy_color if str(side_map.get(key, "ally")) == "enemy" else ally_color
	if n.find("敌方") >= 0:
		return enemy_color
	return ally_color

func _normalize_battle_actor_name(raw_name: String) -> String:
	var n: = raw_name.strip_edges()
	n = n.replace("【", "").replace("】", "")
	n = n.replace("我方修士·", "").replace("我方灵兽·", "")
	n = n.replace("敌方修士·", "").replace("敌方灵兽·", "")
	n = n.replace("我方·", "").replace("敌方·", "")
	n = n.replace("我方", "").replace("敌方", "")
	return n.strip_edges()

func _build_treasure_battle_side_map(log: Array) -> Dictionary:
	var out: = {}
	for e in log:
		if not (e is Dictionary):
			continue
		var d: = e as Dictionary
		var t: = str(d.get("type", ""))
		var side: = ""
		if t == "player_info" or t == "pet_info":
			side = "ally"
		elif t == "enemy_info" or t == "enemy_pet_info":
			side = "enemy"
		if side.is_empty():
			continue
		var name_raw: = str(d.get("name", "")).strip_edges()
		if name_raw.is_empty():
			continue
		out[name_raw] = side
		var norm: = _normalize_battle_actor_name(name_raw)
		if not norm.is_empty():
			out[norm] = side
	return out


func _format_treasure_battle_report(log: Array) -> String:
	var parts: PackedStringArray = PackedStringArray()
	var side_map: Dictionary = _build_treasure_battle_side_map(log)
	for e in log:
		if e is Dictionary:
			var s: = _format_treasure_battle_log_line(e as Dictionary, side_map)
			if not s.is_empty():
				parts.append(s)
		else:
			parts.append(str(e))
	var joined: = "\n".join(parts)
	if joined.strip_edges().is_empty():
		return "（战报为空或无法解析）"
	return joined


func _treasure_match_summary_line(m: Dictionary) -> String:
	var sl: = str(m.get("summary_line", "")).strip_edges()
	if not sl.is_empty():
		return sl
	var an: = str(m.get("a_nickname", "")).strip_edges()
	if an.is_empty():
		an = "修士"
	var b_uid: = _treasure_user_id_field(m.get("b_user_id"))
	var bn: = str(m.get("b_nickname", "")).strip_edges()
	if bn.is_empty() and b_uid > 0:
		bn = "修士"
	var vs: = ("【%s】" % bn) if b_uid > 0 else "轮空"
	var wn: = str(m.get("winner_nickname", "")).strip_edges()
	if wn.is_empty():
		wn = "—"
	var br: = _treasure_safe_int(m.get("bracket_round", 0), 0)
	var mn: = _treasure_safe_int(m.get("match_no", 0), 0)
	return "第%d轮 第%d场：【%s】 vs %s → 胜者【%s】" % [br, mn, an, vs, wn]


func _strip_bbcode(bbcode_text: String) -> String:
	var result: = ""
	var in_tag: = false
	for ch in bbcode_text:
		if ch == "[":
			in_tag = true
		elif ch == "]":
			in_tag = false
		elif not in_tag:
			result += ch
	return result


func _battle_log_entry_color(entry: Dictionary, side_map: Dictionary) -> Color:
	var entry_type: String = str(entry.get("type", ""))
	var is_mine: = false
	var attacker: = str(entry.get("attacker", ""))
	var target: = str(entry.get("target", ""))
	if attacker != "" and side_map.has(attacker):
		is_mine = str(side_map.get(attacker, "")) == "ally"
	elif target != "" and side_map.has(target):
		is_mine = str(side_map.get(target, "")) == "ally"
	match entry_type:
		"start", "combo_trigger":
			return Color(1, 0.9, 0.5)
		"player_info", "pet_info":
			return Color(0.4, 1.0, 0.4)
		"enemy_info", "enemy_pet_info":
			return Color(1.0, 0.4, 0.4)
		"info":
			return Color(0.072, 0.080, 0.079)
		"round":
			return Color(0.9, 0.85, 0.6)
		"combo_attack":
			return Color(1, 0.85, 0.4)
		"joint_attack":
			return Color(0.072, 0.080, 0.079)
		"miss", "dodge":
			return Color(1, 0.6, 0.6) if not is_mine else Color(0.4, 1.0, 0.4)
		"attack", "triple_shot_hit", "kuihua_hit":
			if entry.get("isEnemyAttack", false):
				return Color(1, 0.6, 0.6)
			return Color(0.4, 1.0, 0.4)
		"enemy_dead", "pet_dead", "player_dead":
			return Color(1, 0.85, 0.3)
		"victory":
			return Color(0.3, 1.0, 0.3)
		"defeat":
			return Color(1.0, 0.3, 0.3)
		"skill_splash":
			return Color(0.072, 0.080, 0.079)
		"skill_double_shot":
			return Color(1.0, 0.82, 0.45)
		"skill_divine_protect":
			return Color(0.75, 1.0, 0.55)
		"skill_counter_attack":
			return Color(1.0, 0.65, 0.45)
		_:
			return Color(0.7, 0.7, 0.7)


func _show_treasure_battle_replay_dialog(bracket_round: int, match_no: int, log_arr: Array) -> void :
	var popup: = Control.new()
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg: = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.7)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.gui_input.connect( func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			popup.queue_free()
	)
	popup.add_child(bg)
	var panel: = PanelContainer.new()
	# 500 高装不下「标题 + 十几回合的战斗记录 + 关闭」：内容会把按钮顶出下沿，
	# 最后一行战报被按钮压住。这里加高到 620，并给滚动区一个下限。
	panel.custom_minimum_size = Vector2(600, 620)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -300
	panel.offset_top = -310
	panel.offset_right = 300
	panel.offset_bottom = 310
	popup.add_child(panel)
	var style: = StyleBoxFlat.new()
	style.bg_color = Color(0.057, 0.066, 0.067, 0.98)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.6, 0.5, 0.3)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	panel.add_theme_stylebox_override("panel", style)
	var main_margin: = MarginContainer.new()
	main_margin.add_theme_constant_override("margin_left", 20)
	main_margin.add_theme_constant_override("margin_right", 20)
	main_margin.add_theme_constant_override("margin_top", 15)
	main_margin.add_theme_constant_override("margin_bottom", 15)
	panel.add_child(main_margin)
	var vbox: = VBoxContainer.new()
	main_margin.add_child(vbox)
	var title_label: = Label.new()
	title_label.text = "战斗回放（第%d轮 第%d场）" % [bracket_round, match_no]
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(title_label)
	var sc: = ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.custom_minimum_size = Vector2(0, 460)
	sc.clip_contents = true
	vbox.add_child(sc)
	var log_margin: = MarginContainer.new()
	log_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_margin.add_theme_constant_override("margin_left", 10)
	log_margin.add_theme_constant_override("margin_right", 10)
	log_margin.add_theme_constant_override("margin_top", 5)
	log_margin.add_theme_constant_override("margin_bottom", 5)
	sc.add_child(log_margin)
	var log_container: = VBoxContainer.new()
	log_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_container.add_theme_constant_override("separation", 2)
	log_margin.add_child(log_container)
	for entry in log_arr:
		var entry_label: = Label.new()
		entry_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		entry_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		entry_label.add_theme_font_size_override("font_size", 15)
		var entry_type: String = str(entry.get("type", ""))
		var side_map: = _build_treasure_battle_side_map(log_arr)
		var formatted: = _format_treasure_battle_log_line(entry, side_map)

		var plain_text: = _strip_bbcode(formatted)
		entry_label.text = plain_text
		entry_label.add_theme_color_override("font_color", _battle_log_entry_color(entry, side_map))
		match entry_type:
			"start", "round", "combo_trigger", "victory", "defeat", "info":
				entry_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		log_container.add_child(entry_label)
	var btn_row: = HBoxContainer.new()
	btn_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(btn_row)
	var ok_btn: = Button.new()
	ok_btn.text = "关闭"
	ok_btn.custom_minimum_size = Vector2(150, 45)
	ok_btn.add_theme_font_size_override("font_size", 18)
	ok_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	var btn_normal: = StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.072, 0.080, 0.079)
	btn_normal.border_width_left = 2
	btn_normal.border_width_right = 2
	btn_normal.border_width_top = 2
	btn_normal.border_width_bottom = 2
	btn_normal.border_color = Color(0.714, 0.578, 0.267)
	btn_normal.corner_radius_top_left = 0
	btn_normal.corner_radius_top_right = 0
	btn_normal.corner_radius_bottom_left = 0
	btn_normal.corner_radius_bottom_right = 0
	ok_btn.add_theme_stylebox_override("normal", btn_normal)
	var btn_hover: = btn_normal.duplicate()
	btn_hover.bg_color = Color(0.072, 0.080, 0.079)
	ok_btn.add_theme_stylebox_override("hover", btn_hover)
	ok_btn.pressed.connect( func(): popup.queue_free())
	btn_row.add_child(ok_btn)
	add_child(popup)


func _show_battle_log_list_dialog(chest_no: int, payload: Dictionary) -> void :
	var matches: Array = payload.get("matches", [])
	var total: = _treasure_safe_int(payload.get("total", matches.size()), matches.size())
	var page: = _treasure_safe_int(payload.get("page", 1), 1)
	var page_size: = _treasure_safe_int(payload.get("pageSize", maxi(1, matches.size())), maxi(1, matches.size()))
	var dialog: = Window.new()
	dialog.title = ""
	dialog.size = Vector2i(620, 560)
	dialog.transparent = true
	dialog.borderless = true
	dialog.unresizable = true
	dialog.close_requested.connect( func(): dialog.queue_free())
	var main_panel: = Panel.new()
	main_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_panel.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	dialog.add_child(main_panel)
	var vbox: = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 12)
	main_panel.add_child(vbox)
	var title_label: = Label.new()
	title_label.text = "战斗日志 · 第%d号宝箱" % chest_no
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(title_label)
	var hint: = Label.new()
	if total > matches.size():
		hint.text = "第 %d 页，每页 %d 场；本页 %d 条，共 %d 场" % [page, page_size, matches.size(), total]
	else:
		hint.text = "共 %d 场" % total
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
	vbox.add_child(hint)
	var scroll: = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	var list_vb: = VBoxContainer.new()
	list_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vb.custom_minimum_size = Vector2(560, 0)
	list_vb.add_theme_constant_override("separation", 8)
	scroll.add_child(list_vb)
	for m in matches:
		if not (m is Dictionary):
			continue
		var md: = m as Dictionary
		var row: = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var lab: = Label.new()
		lab.text = _treasure_match_summary_line(md)
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lab.add_theme_font_size_override("font_size", 14)
		lab.add_theme_color_override("font_color", Color(0.894, 0.864, 0.803))
		row.add_child(lab)
		var log_arr: = _parse_treasure_battle_log_json(md.get("battle_log_json", null))
		if _treasure_battle_log_has_combat_steps(log_arr):
			var rb: = Button.new()
			rb.text = "查看本场回放"
			rb.custom_minimum_size = Vector2(118, 32)
			rb.add_theme_font_size_override("font_size", 13)
			_style_small_card_button(rb)
			var br: = _treasure_safe_int(md.get("bracket_round", 0), 0)
			var mn: = _treasure_safe_int(md.get("match_no", 0), 0)
			rb.pressed.connect( func(): dialog.queue_free();_show_treasure_battle_replay_dialog(br, mn, log_arr))
			row.add_child(rb)
		list_vb.add_child(row)
	var ok_btn: = Button.new()
	ok_btn.text = "关闭"
	UIStyle.style_popup_button(ok_btn, true)
	ok_btn.pressed.connect( func(): dialog.queue_free())
	vbox.add_child(ok_btn)
	add_child(dialog)
	dialog.popup_centered()


func _show_battle_log(chest_id: int, chest_no: int) -> void :
	if not _begin_treasure_ui_action_or_return():
		return
	game_manager.network.treasure_battle_log_loaded.connect( func(payload: Dictionary):
		var matches: Array = payload.get("matches", [])
		if matches.is_empty():
			_show_message("暂无战斗日志")
			_add_log("藏宝匣 #%d 暂无战斗日志" % chest_no)
			return
		_show_battle_log_list_dialog(chest_no, payload)
		_add_log("查看了藏宝匣 #%d 战斗日志（%d场）" % [chest_no, matches.size()])
	, CONNECT_ONE_SHOT)
	game_manager.network.treasure_get_battle_log(chest_id, 1, 50)

func _open_treasure_mirror() -> void :
	if not _begin_treasure_ui_action_or_return():
		return
	if game_manager == null or not game_manager.has_method("open_treasure_mirror_popup_from_ui"):
		_show_message("镜像功能未就绪")
		return
	game_manager.open_treasure_mirror_popup_from_ui(self)

func _show_rules() -> void :
	if not _begin_treasure_ui_action_or_return():
		return
	_add_log("查看规则说明")
	var rules_text: = ""
	if game_manager and game_manager.has_method("get_treasure_runtime_config"):
		var cfg: Dictionary = game_manager.get_treasure_runtime_config()
		if not cfg.is_empty() and str(cfg.get("descriptionText", "")).strip_edges() != "":
			rules_text = str(cfg.get("descriptionText"))
	if rules_text.is_empty():
		rules_text = (
			"藏宝洞规则说明：\n"
			+ "1. 每日开放时段为 9:00-24:00（北京时间），每个整点开启一轮（9:00~23:00 共15轮）。\n"
			+ "2. 每轮固定3个藏宝匣，互不影响。\n"
			+ "3. 每轮前10分钟可选箱入阵，后10分钟为争夺阶段；每轮总时长约20分钟。\n"
			+ "4. 每名玩家每轮只能参加其中一个箱子。\n"
			+ "5. 每日参与次数：非VIP2次、青铜VIP4次、白银VIP5次、黄金VIP8次（按成功入阵计数）。\n"
			+ "6. 须先点「更新镜像」，争夺用该镜像互打；入阵后本轮不再随你改阵容。\n"
			+ "7. 结算后若你获胜，系统会发邮件，附件为【藏宝匣】道具，在背包中使用即可开奖。\n"
			+ "8. 开箱奖励随机发放，越稀有的东西概率越低。\n"
			+ "\n【开箱奖励与概率】\n"
			+ "五阶宠物锦囊 31.58%\n"
			+ "极限装备池 21.05%（池内5件均分，各4.21%）\n"
			+ "六阶可进化宠锦囊 14.79%\n"
			+ "1亿金币 10.53%\n"
			+ "五行属性宠物蛋 7.27%（金木水火土各1.45%）\n"
			+ "5亿金币 5.26%\n"
			+ "宠物经验丹 3.51%\n"
			+ "人物经验丹 2.76%\n"
			+ "10亿金币 1.50%\n"
			+ "七阶可进化宠锦囊 1.00%\n"
			+ "八阶可进化宠锦囊 0.50%\n"
			+ "硬皮lv1技能书 0.25%"
		)
	_show_message(rules_text)

func _show_message(message: String) -> void :
	var dialog: = Window.new()
	dialog.title = ""
	var vph: = int(get_viewport().get_visible_rect().size.y)
	var dlg_h: int = clampi(int(vph * 0.62), 320, 540)
	dialog.size = Vector2i(540, dlg_h)
	dialog.transparent = true
	dialog.borderless = true
	dialog.unresizable = true
	dialog.close_requested.connect( func(): dialog.queue_free())
	var main_panel: = Panel.new()
	main_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_panel.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	dialog.add_child(main_panel)
	var margin: = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	main_panel.add_child(margin)
	var vbox: = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	var title_label: = Label.new()
	title_label.text = "藏宝洞"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(title_label)
	var scroll: = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	vbox.add_child(scroll)
	var content_label: = Label.new()
	content_label.text = message
	content_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_label.add_theme_font_size_override("font_size", 18)
	content_label.add_theme_color_override("font_color", Color(0.894, 0.864, 0.803))
	content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_label.custom_minimum_size = Vector2(480, 0)
	scroll.add_child(content_label)
	var ok_btn: = Button.new()
	ok_btn.text = "确定"
	UIStyle.style_popup_button(ok_btn, true)
	ok_btn.pressed.connect( func(): dialog.queue_free())
	vbox.add_child(ok_btn)
	add_child(dialog)
	dialog.popup_centered()

func _now_stamp() -> String:
	var now = Time.get_datetime_dict_from_system()
	return "%02d:%02d:%02d" % [int(now.hour), int(now.minute), int(now.second)]

func _format_activity_time(raw: String) -> String:
	var s: = raw.strip_edges()
	if s.is_empty():
		return _now_stamp()

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

func _append_log_label(stamp: String, message: String, is_activity: bool) -> void :
	if not log_container:
		return
	var label: = Label.new()
	label.text = "[%s] %s" % [stamp, message]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", COLOR_ACTIVITY_LOG if is_activity else COLOR_LOG_TEXT)
	log_container.add_child(label)
	if log_container.get_child_count() > 120:
		log_container.get_child(0).queue_free()

func _normalize_activity_round_text(message: String) -> String:
	var msg: = message
	if msg.find("轮已现") < 0:
		return msg
	if msg.find("第「") < 0 or msg.find("」轮") < 0:
		return msg
	if _last_status_data.is_empty() or not (_last_status_data.get("round") is Dictionary):
		return msg
	var round_info: Dictionary = _last_status_data.get("round", {})
	var today_idx: = _treasure_safe_int(round_info.get("round_index_today", 0), 0)
	if today_idx <= 0:
		return msg
	var seg_start: = msg.find("第「")
	var seg_end: = msg.find("」轮", seg_start)
	if seg_start < 0 or seg_end < 0 or seg_end < seg_start:
		return msg
	var before: = msg.substr(0, seg_start)
	var after: = msg.substr(seg_end + 2)
	return "%s今日第%d轮%s" % [before, today_idx, after]

func _render_activity_log_from_server(entries: Array) -> void :
	if not log_container:
		return
	for c in log_container.get_children():
		c.queue_free()
	for e in entries:
		if not (e is Dictionary):
			continue
		var msg: = str(e.get("message", "")).strip_edges()
		if msg.is_empty():
			continue
		msg = _normalize_activity_round_text(msg)
		var stamp: = _format_activity_time(str(e.get("at", "")))
		_append_log_label(stamp, msg, true)

func _add_log(message: String) -> void :
	_append_log_label(_now_stamp(), message, false)

func _tick_chest_countdowns() -> void :
	if _treasure_action_cooldown:
		return
	for state in _chest_ui_states:
		if not (state is Dictionary):
			continue
		var remain_sec = _treasure_safe_int(state.get("remain_sec", 0), 0)
		if remain_sec > 0:
			remain_sec -= 1
			state["remain_sec"] = remain_sec
		var chest_status = str(state.get("status", ""))
		var chest_no = _treasure_safe_int(state.get("chest_no", 0), 0)
		var chest_id = _treasure_safe_int(state.get("chest_id", 0), 0)
		var join_btn: Button = state.get("join_btn")
		if is_instance_valid(join_btn):
			if chest_status == "finished":
				join_btn.text = "本轮已结算"
				join_btn.disabled = true
				_apply_join_btn_disabled_style(join_btn, false)
			elif _joined_chest_id > 0 and chest_id == _joined_chest_id and (chest_status == "signup_open" or chest_status == "battle_running"):
				join_btn.text = _joined_phase_join_button_text(chest_status, remain_sec)
				join_btn.disabled = true
				_apply_join_btn_disabled_style(join_btn, true)
			elif chest_status == "signup_open" and chest_id > 0 and (_joined_chest_id == 0 or _joined_chest_id == chest_id):
				var phase_ok: = _joined_phase_join_button_text(chest_status, remain_sec)
				join_btn.text = phase_ok if not phase_ok.is_empty() else "参与抢夺"
				join_btn.disabled = false
			else:
				var phase_dis: = _joined_phase_join_button_text(chest_status, remain_sec)
				join_btn.text = phase_dis if not phase_dis.is_empty() else "参与抢夺"
				join_btn.disabled = true
				_apply_join_btn_disabled_style(join_btn, false)
		state["chest_no"] = chest_no
