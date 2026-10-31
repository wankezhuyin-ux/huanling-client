class_name BrotherTowerUI
extends RefCounted

const UIStyle = preload("res://scripts/ui_style.gd")
const PlayerCharacterConfig = preload("res://scripts/player_character_config.gd")
const BattleSnapshotDisplay = preload("res://scripts/ui/battle_snapshot_display.gd")

const POLL_SEC_LOBBY: = 4.5
const POLL_SEC_IN_ROOM: = 2.5
const OPTIMISTIC_ROOM_GUARD_MS: = 5000
const TOKEN_NAME: = "兄弟天关令牌"
const MEMBER_SLOT_WIDTH: = 120
const MEMBER_AVATAR_FRAME_SIZE: = 64
const MEMBER_AVATAR_BORDER: = 2
const DAILY_REWARD_MAX_FALLBACK: = 1
const DAILY_CLEAR_MAX_FALLBACK: = 15
const SNAPSHOT_PIN_COOLDOWN_MS: = 3000
const PIN_SNAPSHOT_REQUIRED_MSG: = "请先在兄弟天关界面更新人物与出战宠快照"
const TEAM_SORT_CFG_PATH: = "user://brother_tower_ui.cfg"
const TEAM_SORT_CFG_SECTION: = "lobby"
const TEAM_SORT_CFG_KEY: = "team_sort"

static func _daily_reward_count() -> int:
	var raw: = int(_status_data.get("dailyRewardCount", _list_data.get("dailyRewardCount", 0)))
	return mini(raw, _daily_reward_max())

static func _daily_reward_max() -> int:
	return int(_status_data.get("dailyRewardMax", _list_data.get("dailyRewardMax", DAILY_REWARD_MAX_FALLBACK)))

static func _daily_clear_count() -> int:
	return int(_status_data.get("dailyClearCount", _list_data.get("dailyClearCount", 0)))

static func _daily_clear_max() -> int:
	return int(_status_data.get("dailyClearMax", _list_data.get("dailyClearMax", DAILY_CLEAR_MAX_FALLBACK)))

static func _is_daily_clear_full() -> bool:
	return _daily_clear_count() >= _daily_clear_max()

static var _list_data: Dictionary = {}
static var _status_data: Dictionary = {}
static var _poll_timer: Timer = null
static var _selected_difficulty: String = "easy"
static var _last_missing_members_poll_ms: int = 0
static var _start_pending: bool = false
static var _lobby_op_pending: bool = false
static var _snapshot_pin_pending: bool = false
static var _snapshot_pin_cooldown_until_ms: int = 0
static var _optimistic_room_id: int = 0
static var _optimistic_guard_until_ms: int = 0
static var _team_sort_desc: bool = true
static var _team_sort_loaded: bool = false
static var _last_room_expired_notice_ms: int = 0

static func set_start_pending(pending: bool) -> void :
	_start_pending = pending

static func is_start_pending() -> bool:
	return _start_pending

static func set_lobby_op_pending(pending: bool) -> void :
	_lobby_op_pending = pending
	if _active_game_manager and _active_parent_panel and is_instance_valid(_active_parent_panel):
		refresh_panel(_active_game_manager, _active_parent_panel)

static func is_lobby_op_pending() -> bool:
	return _lobby_op_pending

static func is_snapshot_pin_pending() -> bool:
	return _snapshot_pin_pending

static func is_mirror_on_cooldown() -> bool:
	return _is_snapshot_pin_cooldown()

static func get_mirror_cooldown_label() -> String:
	var remain_ms: = _snapshot_pin_cooldown_until_ms - Time.get_ticks_msec()
	if remain_ms <= 0:
		return ""
	var sec: = ceili(remain_ms / 1000.0)
	return "%d秒" % maxi(1, sec)

static func set_mirror_update_pending(pending: bool) -> void :
	_snapshot_pin_pending = pending
	if _active_parent_panel and is_instance_valid(_active_parent_panel):
		_refresh_snapshot_panel(_active_parent_panel)

static func get_mirror_preview(game_manager = null) -> Dictionary:
	var pin: = _pinned_snapshot_summary()
	var out: Dictionary = pin.duplicate() if not pin.is_empty() else {}
	out["mirrorMode"] = "brother_tower"
	out["mirrorTitle"] = "当前兄弟天关出战快照"
	out["hasMirror"] = bool(pin.get("hasPinned", false))
	if str(out.get("updatedAt", "")).is_empty():
		out["updatedAt"] = str(pin.get("pinnedAt", ""))
	if game_manager:
		if int(out.get("characterId", out.get("character_id", 0))) <= 0 and game_manager.get("player") and game_manager.player:
			out["characterId"] = int(game_manager.player.player_character_id)
		if str(out.get("playerRealm", "")).is_empty() and game_manager.get("player") and game_manager.player:
			out["playerRealm"] = str(game_manager.player.realm)
		if not out.has("playerReincarnation") and game_manager.get("player") and game_manager.player:
			out["playerReincarnation"] = int(game_manager.player.reincarnation)
	return out

static func apply_pinned_summary(summary: Dictionary) -> void :
	if summary.is_empty():
		return
	var pinned: Dictionary = {}
	var raw_pinned = _status_data.get("pinnedSnapshot", {})
	if raw_pinned is Dictionary:
		pinned = raw_pinned.duplicate(true)
	for key in summary.keys():
		pinned[key] = summary[key]
	pinned["hasPinned"] = true
	_status_data["pinnedSnapshot"] = pinned
	if _active_parent_panel and is_instance_valid(_active_parent_panel):
		_refresh_snapshot_panel(_active_parent_panel)

static func _has_pinned_snapshot() -> bool:
	var raw = _status_data.get("pinnedSnapshot", {})
	if raw is Dictionary:
		return bool(raw.get("hasPinned", false))
	return false

static func _pinned_snapshot_summary() -> Dictionary:
	var raw = _status_data.get("pinnedSnapshot", {})
	return raw if raw is Dictionary else {}

static func _ensure_pinned_snapshot(parent_panel: Control) -> bool:
	if _has_pinned_snapshot():
		return true
	_show_msg(parent_panel, PIN_SNAPSHOT_REQUIRED_MSG)
	return false

static func _is_snapshot_pin_cooldown() -> bool:
	return Time.get_ticks_msec() < _snapshot_pin_cooldown_until_ms

static func _format_pinned_snapshot_text() -> String:
	return BattleSnapshotDisplay.format_summary(
		_pinned_snapshot_summary(), 
		"hasPinned", 
		"尚未设置人物与出战宠快照，请先更新"
	)

static func _refresh_snapshot_panel(parent_panel: Control) -> void :
	if not is_instance_valid(parent_panel):
		return
	var status_lbl = parent_panel.get_meta("bt_snapshot_status_label", null)
	var pin_btn = parent_panel.get_meta("bt_snapshot_pin_btn", null)
	if is_instance_valid(status_lbl):
		status_lbl.text = _format_pinned_snapshot_text()
		if _has_pinned_snapshot():
			status_lbl.add_theme_color_override("font_color", Color(0.75, 0.9, 0.75))
		else:
			status_lbl.add_theme_color_override("font_color", Color(1.0, 0.7, 0.45))
	if pin_btn is Button:
		if _snapshot_pin_pending:
			pin_btn.text = "更新中…"
			pin_btn.disabled = true
		elif _is_snapshot_pin_cooldown():
			pin_btn.text = "冷却中…"
			pin_btn.disabled = true
		else:
			pin_btn.text = "查看/更新镜像"
			pin_btn.disabled = false

static func create_content(game_manager, parent_panel: Control) -> Control:
	var panel: = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", UIStyle.create_panel_style())

	var vbox: = UIStyle.create_base_vbox()
	panel.add_child(vbox)

	var title: = UIStyle.create_title_label("🤝 兄弟天关")
	vbox.add_child(title)

	var info_panel: = _create_info_panel(game_manager)
	vbox.add_child(info_panel)

	var snapshot_panel: = _create_snapshot_panel(game_manager, parent_panel)
	vbox.add_child(snapshot_panel)

	var scroll: = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	TouchScrollUtils.configure_scroll(scroll)
	vbox.add_child(scroll)

	var scroll_content: = VBoxContainer.new()
	scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_content.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	scroll_content.add_theme_constant_override("separation", 10)
	scroll.add_child(scroll_content)

	var challenge_card: = _create_challenge_card(game_manager)
	scroll_content.add_child(challenge_card)
	_enable_touch_drag_passthrough(challenge_card)

	var drop_panel: = _create_gift_showcase_panel(game_manager, parent_panel)
	scroll_content.add_child(drop_panel)
	_enable_touch_drag_passthrough(drop_panel)

	_ensure_team_sort_loaded()
	var header: = Control.new()
	header.custom_minimum_size = Vector2(0, 44)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll_content.add_child(header)
	var teams_title: = Label.new()
	teams_title.text = "── 组队大厅 ──"
	teams_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	teams_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	teams_title.add_theme_font_size_override("font_size", 18)
	teams_title.add_theme_color_override("font_color", UIStyle.COLORS.title_color)
	teams_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	teams_title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	header.add_child(teams_title)
	var sort_btn: = Button.new()
	sort_btn.name = "bt_team_sort_btn"
	sort_btn.text = _team_sort_button_text()
	sort_btn.custom_minimum_size = Vector2(140, 44)
	sort_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	sort_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sort_btn.anchor_left = 1.0
	sort_btn.anchor_right = 1.0
	sort_btn.anchor_top = 0.5
	sort_btn.anchor_bottom = 0.5
	sort_btn.offset_left = -148
	sort_btn.offset_right = -8
	sort_btn.offset_top = -22
	sort_btn.offset_bottom = 22
	_style_secondary_button(sort_btn)
	TouchScrollUtils.bind_tap(sort_btn, func():
		_toggle_team_sort(game_manager, parent_panel)
	)
	header.add_child(sort_btn)
	parent_panel.set_meta("bt_team_sort_btn", sort_btn)

	var teams_box: = VBoxContainer.new()
	teams_box.name = "bt_teams_box"
	teams_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	teams_box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	teams_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	teams_box.add_theme_constant_override("separation", 10)
	scroll_content.add_child(teams_box)

	parent_panel.set_meta("bt_root", panel)
	parent_panel.set_meta("bt_teams_box", teams_box)
	parent_panel.set_meta("bt_challenge_card", challenge_card)
	parent_panel.set_meta("bt_info_left", info_panel.get_meta("bt_info_left"))
	parent_panel.set_meta("bt_info_right", info_panel.get_meta("bt_info_right"))
	parent_panel.set_meta("bt_game_manager", game_manager)

	ensure_signals_connected(game_manager, parent_panel)
	_setup_poll(game_manager, parent_panel)
	refresh_panel(game_manager, parent_panel)
	if game_manager and game_manager.has_method("get_brother_tower_runtime_config"):
		var existing_cfg: Variant = game_manager.get_brother_tower_runtime_config()
		if existing_cfg is Dictionary and not existing_cfg.is_empty():
			_sync_challenge_card_difficulty(parent_panel)
	if game_manager and game_manager.network and game_manager.network.has_method("fetch_gameplay_runtime_config"):
		game_manager.network.fetch_gameplay_runtime_config()
		if game_manager.network and game_manager.network.has_signal("gameplay_runtime_config_loaded"):
			var cfg_cb: = _on_bt_runtime_config_loaded.bind(game_manager, parent_panel)
			if not game_manager.network.gameplay_runtime_config_loaded.is_connected(cfg_cb):
				game_manager.network.gameplay_runtime_config_loaded.connect(cfg_cb)
	if game_manager and game_manager.network:
		game_manager.network.get_brother_tower_poll("lobby")
		game_manager.network.get_brother_tower_status()
	return panel

static func _create_snapshot_panel(game_manager, parent_panel: Control) -> Panel:
	var panel: = Panel.new()
	panel.custom_minimum_size = Vector2(0, 88)
	panel.add_theme_stylebox_override("panel", UIStyle.create_item_style())

	var margin: = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	var text_v: = VBoxContainer.new()
	text_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_v.add_theme_constant_override("separation", 4)
	row.add_child(text_v)

	var title: = _styled_label("人物与出战快照", 15, Color(0.072, 0.080, 0.079))
	var status_lbl: = _styled_label(_format_pinned_snapshot_text(), 12, Color(1.0, 0.7, 0.45))
	status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_v.add_child(title)
	text_v.add_child(status_lbl)

	var pin_btn: = Button.new()
	pin_btn.custom_minimum_size = Vector2(220, 50)
	pin_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pin_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style_primary_button(pin_btn)
	TouchScrollUtils.bind_tap(pin_btn, func(): _on_open_mirror(game_manager, parent_panel))
	row.add_child(pin_btn)

	parent_panel.set_meta("bt_snapshot_status_label", status_lbl)
	parent_panel.set_meta("bt_snapshot_pin_btn", pin_btn)
	_refresh_snapshot_panel(parent_panel)
	return panel

static func _on_open_mirror(game_manager, parent_panel: Control) -> void :
	if game_manager and game_manager.has_method("open_brother_tower_mirror_popup_from_ui"):
		game_manager.open_brother_tower_mirror_popup_from_ui(parent_panel)

static func _on_pin_snapshot(game_manager, parent_panel: Control) -> void :
	_on_pin_snapshot_async(game_manager, parent_panel)

static func _on_pin_snapshot_async(game_manager, parent_panel: Control) -> void :
	if not game_manager or not game_manager.network:
		return
	if _snapshot_pin_pending or _is_snapshot_pin_cooldown():
		return
	if not game_manager.player:
		_show_msg(parent_panel, "人物数据未加载，请稍后再试")
		return
	if not game_manager.pet_manager or not game_manager.pet_manager.get_active_pet():
		_show_msg(parent_panel, "请先选择出战宠物后再更新快照")
		return
	_snapshot_pin_pending = true
	_refresh_snapshot_panel(parent_panel)
	var snap: Dictionary = BrotherTowerManager.build_local_snapshot(game_manager)
	var op: = "bt_pin_%d" % Time.get_unix_time_from_system()
	game_manager.network.brother_tower_pin_snapshot(snap, op)

static func _create_gift_showcase_panel(game_manager, parent_panel: Control) -> Control:
	var drop_panel: = PanelContainer.new()
	var drop_style: = UIStyle.create_item_style()
	drop_style.content_margin_left = 14
	drop_style.content_margin_right = 14
	drop_style.content_margin_top = 10
	drop_style.content_margin_bottom = 10
	drop_panel.add_theme_stylebox_override("panel", drop_style)

	var drop_vbox: = VBoxContainer.new()
	drop_vbox.add_theme_constant_override("separation", 8)
	drop_panel.add_child(drop_vbox)

	var drop_title: = Label.new()
	drop_title.text = "🎁 可能掉落"
	drop_title.add_theme_font_size_override("font_size", 17)
	drop_title.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
	drop_vbox.add_child(drop_title)

	var drop_text: = Label.new()
	drop_text.name = "bt_gift_showcase_label"
	drop_text.text = _bt_gift_showcase_text(game_manager)
	drop_text.add_theme_font_size_override("font_size", 16)
	drop_text.add_theme_color_override("font_color", Color(0.85, 0.85, 0.6))
	drop_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	drop_vbox.add_child(drop_text)
	parent_panel.set_meta("bt_gift_showcase_label", drop_text)
	return drop_panel

static func _bt_wave_count(game_manager) -> int:
	if game_manager != null and game_manager.has_method("get_brother_tower_wave_count"):
		return maxi(1, game_manager.get_brother_tower_wave_count())
	return BrotherTowerManager.WAVE_COUNT

static func _bt_monsters_per_wave(game_manager) -> int:
	return BrotherTowerManager.monsters_per_wave(game_manager)

static func _bt_battle_rounds(game_manager) -> int:
	return BrotherTowerManager.battle_max_rounds(game_manager)

static func _bt_level_range_text(game_manager, difficulty: String) -> String:
	var key: String = str(difficulty).strip_edges().to_lower()
	if game_manager != null and game_manager.has_method("get_brother_tower_runtime_config"):
		var cfg: Variant = game_manager.get_brother_tower_runtime_config()
		if cfg is Dictionary and not cfg.is_empty():
			var diffs: Variant = cfg.get("difficulties", [])
			if diffs is Array:
				for row in diffs:
					if row is Dictionary and str(row.get("id", "")) == key:
						var level_start: int = int(row.get("levelStart", 5100))
						var level_end: int = int(row.get("levelEnd", 10000))
						return "%d → %d" % [level_start, level_end]
	if game_manager != null and game_manager.has_method("get_brother_tower_level_range_text"):
		return str(game_manager.get_brother_tower_level_range_text(difficulty))
	return BrotherTowerManager.difficulty_level_range_text(difficulty, game_manager)

static func _bt_wave_summary_line(game_manager, _difficulty: String = "") -> String:
	return "%d波 × %d怪 | 创建队伍时选择难度" % [
		_bt_wave_count(game_manager), 
		_bt_monsters_per_wave(game_manager), 
	]

static func _bt_battle_summary_line(game_manager) -> String:
	return "%d回合/波 | 自动连打 | 双人组队" % _bt_battle_rounds(game_manager)

static func _bt_difficulty_preset(game_manager, difficulty: String) -> Dictionary:
	if game_manager != null and game_manager.has_method("get_brother_tower_difficulty_preset"):
		return game_manager.get_brother_tower_difficulty_preset(difficulty)
	return BrotherTowerManager.get_difficulty_preset(difficulty, game_manager)

static func _bt_reward_summary_line(game_manager) -> String:
	var cfg: Dictionary = {}
	if game_manager != null and game_manager.has_method("get_brother_tower_runtime_config"):
		cfg = game_manager.get_brother_tower_runtime_config()
	var diffs: Array = BrotherTowerManager.list_difficulties(game_manager)
	var gift_parts: PackedStringArray = PackedStringArray()
	var friend_parts: PackedStringArray = PackedStringArray()
	for row in diffs:
		if not (row is Dictionary):
			continue
		var lab: = str(row.get("label", row.get("id", "")))
		gift_parts.append("%s%d" % [lab, int(row.get("giftCount", 1))])
		friend_parts.append("+%d" % int(row.get("friendshipGain", 1)))
	var daily_reward: = int(cfg.get("dailyRewardMax", DAILY_REWARD_MAX_FALLBACK))
	var daily_clear: = int(cfg.get("dailyClearMax", DAILY_CLEAR_MAX_FALLBACK))
	var noble_bonus: = int(cfg.get("nobleClearBonusPerLevel", 1))
	var gift_text: = "、".join(gift_parts) if gift_parts.size() > 0 else "按难度"
	var friend_text: = "/".join(friend_parts) if friend_parts.size() > 0 else "+友情点"
	return "每日前%d次通关按难度发礼包(%s)，之后%s友情点，基础%d次/日，贵族每级+%d次" % [
		daily_reward, gift_text, friend_text, daily_clear, noble_bonus, 
	]

static func _bt_gift_showcase_text(game_manager) -> String:
	if game_manager == null or not game_manager.has_method("get_brother_tower_runtime_config"):
		return "加载中..."
	var cfg: Dictionary = game_manager.get_brother_tower_runtime_config()
	if cfg.is_empty():
		return "登录后同步服务端掉落表"
	var names_raw: Variant = cfg.get("giftShowcaseNames", [])
	if names_raw is Array:
		var names: PackedStringArray = PackedStringArray()
		for entry in names_raw:
			var n: = str(entry).strip_edges()
			if not n.is_empty():
				names.append(n)
		if not names.is_empty():
			return "、".join(names)
	return "暂无掉落配置"

static func _refresh_bt_gift_showcase(game_manager, parent_panel: Control) -> void :
	var label: Label = parent_panel.get_meta("bt_gift_showcase_label", null)
	if label and is_instance_valid(label):
		label.text = _bt_gift_showcase_text(game_manager)

static func _on_bt_runtime_config_loaded(config: Dictionary, game_manager, parent_panel: Control) -> void :
	if game_manager and game_manager.has_method("_on_gameplay_runtime_config_loaded"):
		game_manager._on_gameplay_runtime_config_loaded(config)
	_refresh_bt_gift_showcase(game_manager, parent_panel)
	_sync_challenge_card_difficulty(parent_panel)

static func _create_info_panel(game_manager) -> Panel:
	var info_panel: = Panel.new()
	info_panel.custom_minimum_size = Vector2(0, 100)
	info_panel.add_theme_stylebox_override("panel", UIStyle.create_item_style())

	var info_hbox: = HBoxContainer.new()
	info_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	info_hbox.offset_left = 15
	info_hbox.offset_top = 10
	info_hbox.offset_right = -15
	info_hbox.offset_bottom = -10
	info_hbox.add_theme_constant_override("separation", 16)
	info_panel.add_child(info_hbox)

	var left_info: = VBoxContainer.new()
	left_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_info.add_theme_constant_override("separation", 4)
	info_hbox.add_child(left_info)

	var player_name: = _styled_label("玩家: —", 14, Color(0.072, 0.080, 0.079))
	var player_level: = _styled_label("等级: — | 投胎: —", 12, Color(0.072, 0.080, 0.079))
	var player_rule: = _styled_label("需投胎≥1 | 2人组队 | 队长消耗【%s】" % TOKEN_NAME, 12, Color(0.072, 0.080, 0.079))
	left_info.add_child(player_name)
	left_info.add_child(player_level)
	left_info.add_child(player_rule)

	var right_info: = VBoxContainer.new()
	right_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_info.add_theme_constant_override("separation", 4)
	info_hbox.add_child(right_info)

	var daily_label: = _styled_label("今日奖励: —/—", 14, Color(0.072, 0.080, 0.079))
	daily_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var daily_clear_label: = _styled_label("今日通关: —/—", 14, Color(0.072, 0.080, 0.079))
	daily_clear_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var fp_label: = _styled_label("友情点: —", 12, Color(1.0, 0.85, 0.3))
	fp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right_info.add_child(daily_label)
	right_info.add_child(daily_clear_label)
	right_info.add_child(fp_label)

	if game_manager and game_manager.player:
		var p = game_manager.player
		player_name.text = "玩家: %s" % p.player_name
		player_level.text = "等级: %d | 境界: %s | 投胎: %d" % [p.level, p.realm, p.reincarnation]

	info_panel.set_meta("bt_info_left", [player_name, player_level])
	info_panel.set_meta("bt_info_right", [daily_label, daily_clear_label, fp_label])
	return info_panel

static func _create_challenge_card(game_manager) -> Control:
	var card: = PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIStyle.create_item_style())
	var margin: = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var hbox: = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	margin.add_child(hbox)

	var text_v: = VBoxContainer.new()
	text_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_v.add_theme_constant_override("separation", 4)
	hbox.add_child(text_v)

	var t: = _styled_label("⚔️ 兄弟天关挑战", 18, UIStyle.COLORS.title_color)
	var d1: = _styled_label(
		_bt_wave_summary_line(game_manager, _selected_difficulty), 
		13, 
		Color(0.85, 0.6, 0.4)
	)
	var d2: = _styled_label(_bt_battle_summary_line(game_manager), 12, Color(0.072, 0.080, 0.079))
	var d3: = _styled_label(_bt_reward_summary_line(game_manager), 11, Color(0.072, 0.080, 0.079))
	text_v.add_child(t)
	text_v.add_child(d1)
	text_v.add_child(d2)
	text_v.add_child(d3)
	card.set_meta("bt_level_range_label", d1)
	card.set_meta("bt_battle_summary_label", d2)
	card.set_meta("bt_reward_summary_label", d3)
	return card

static func _difficulty_option_ids() -> Array:
	return [BrotherTowerManager.DIFFICULTY_EASY, BrotherTowerManager.DIFFICULTY_HARD, BrotherTowerManager.DIFFICULTY_HELL]

static func _populate_difficulty_option_button(menu: OptionButton, selected: String, game_manager = null) -> void :
	menu.clear()
	var ids: = _difficulty_option_ids()
	var select_idx: = 0
	var normalized: String = BrotherTowerManager.normalize_difficulty(selected)
	for i in range(ids.size()):
		var diff_id: String = ids[i]
		menu.add_item(BrotherTowerManager.difficulty_label(diff_id, game_manager), i)
		menu.set_item_metadata(i, diff_id)
		if diff_id == normalized:
			select_idx = i
	menu.select(select_idx)

static func _difficulty_from_option_button(menu: OptionButton) -> String:
	var idx: = menu.selected
	if idx < 0:
		return BrotherTowerManager.DIFFICULTY_EASY
	var meta = menu.get_item_metadata(idx)
	if meta != null:
		return BrotherTowerManager.normalize_difficulty(meta)
	return BrotherTowerManager.DIFFICULTY_EASY

static func _room_difficulty_label(room: Dictionary) -> String:
	if room.has("difficultyLabel"):
		return str(room.get("difficultyLabel"))
	return BrotherTowerManager.difficulty_label(str(room.get("difficulty", BrotherTowerManager.DIFFICULTY_EASY)))

static func _room_join_mode(room: Dictionary) -> String:
	var mode: = str(room.get("joinMode", room.get("join_mode", "auto"))).strip_edges().to_lower()
	return "review" if mode == "review" else "auto"

static func _has_pending_application(room_id: int) -> bool:
	if room_id <= 0:
		return false
	var raw: Variant = _list_data.get("myPendingApplicationRoomIds", [])
	if raw is Array:
		for entry in raw:
			if _safe_int(entry, 0) == room_id:
				return true
	return false

static func _room_pending_application_count(room: Dictionary) -> int:
	var apps: Variant = room.get("applications", [])
	if apps is Array:
		return apps.size()
	return int(room.get("applicationCount", 0))

static func _collect_room_applications(room: Dictionary) -> Array:
	var apps: Variant = room.get("applications", [])
	if apps is Array:
		return apps
	var my_room: Variant = _list_data.get("myRoom", {})
	if my_room is Dictionary and _safe_int(my_room.get("roomId"), 0) == _safe_int(room.get("roomId"), 0):
		var mine: Variant = my_room.get("applications", [])
		if mine is Array:
			return mine
	return []

static func _inline_label(text: String, font_size: int, color: Color) -> Label:
	var lbl: = Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	lbl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	return lbl

static func _style_difficulty_option_button(menu: OptionButton) -> void :
	menu.custom_minimum_size = Vector2(108, 36)
	menu.add_theme_font_size_override("font_size", 14)
	menu.add_theme_color_override("font_color", Color(0.894, 0.864, 0.803))
	var normal: = UIStyle.create_item_style()
	var hover: = UIStyle.create_item_style()
	hover.bg_color = Color(0.072, 0.080, 0.079, 1.0)
	hover.border_color = Color(0.894, 0.770, 0.467, 1.0)
	menu.add_theme_stylebox_override("normal", normal)
	menu.add_theme_stylebox_override("hover", hover)
	menu.add_theme_stylebox_override("pressed", hover)
	menu.add_theme_stylebox_override("focus", normal)
	var popup: = menu.get_popup()
	popup.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	popup.add_theme_font_size_override("font_size", 14)

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

static func _styled_label(text: String, font_size: int, color: Color) -> Label:
	var lbl: = Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	return lbl

static func _style_primary_button(btn: Button) -> void :
	btn.add_theme_font_size_override("font_size", 16)
	UIStyle.apply_golden_button_style(btn)
	UIStyle.setup_button_animation(btn)

static func _style_secondary_button(btn: Button) -> void :
	btn.add_theme_font_size_override("font_size", 15)
	UIStyle.apply_button_style(btn)
	UIStyle.setup_button_animation(btn)

static func _team_sort_button_text() -> String:
	return "时间 新→旧" if _team_sort_desc else "时间 旧→新"

static func _ensure_team_sort_loaded() -> void :
	if _team_sort_loaded:
		return
	_team_sort_loaded = true
	_team_sort_desc = true
	var cfg: = ConfigFile.new()
	if cfg.load(TEAM_SORT_CFG_PATH) != OK:
		return
	var raw: = str(cfg.get_value(TEAM_SORT_CFG_SECTION, TEAM_SORT_CFG_KEY, "desc")).strip_edges().to_lower()
	if raw == "asc":
		_team_sort_desc = false

static func _save_team_sort() -> void :
	var cfg: = ConfigFile.new()
	cfg.load(TEAM_SORT_CFG_PATH)
	cfg.set_value(TEAM_SORT_CFG_SECTION, TEAM_SORT_CFG_KEY, "desc" if _team_sort_desc else "asc")
	cfg.save(TEAM_SORT_CFG_PATH)

static func _toggle_team_sort(game_manager, parent_panel: Control) -> void :
	_ensure_team_sort_loaded()
	_team_sort_desc = not _team_sort_desc
	_save_team_sort()
	if is_instance_valid(parent_panel):
		refresh_panel(game_manager, parent_panel)

static func _room_display_no(room) -> int:
	if not room is Dictionary:
		return 0
	return _safe_int(room.get("displayNo", room.get("roomId", 0)), 0)

static func _room_created_at_ms(room) -> int:
	if not room is Dictionary:
		return 0
	return _safe_int(room.get("createdAt", 0), 0)

static func _rooms_have_created_at(rooms: Array) -> bool:
	for room in rooms:
		if _room_created_at_ms(room) > 0:
			return true
	return false

static func _sort_rooms_by_display_no(rooms: Array) -> void :
	rooms.sort_custom( func(a, b):
		var na: = _room_display_no(a)
		var nb: = _room_display_no(b)
		if _team_sort_desc:
			return na > nb
		return na < nb
	)

static func _sort_rooms_by_created_at(rooms: Array) -> void :
	if not _rooms_have_created_at(rooms):
		_sort_rooms_by_display_no(rooms)
		return
	rooms.sort_custom( func(a, b):
		var ka: = _room_created_at_ms(a)
		var kb: = _room_created_at_ms(b)
		if ka == kb:
			var na: = _room_display_no(a)
			var nb: = _room_display_no(b)
			if _team_sort_desc:
				return na > nb
			return na < nb
		if _team_sort_desc:
			return ka > kb
		return ka < kb
	)

static func _update_poll_interval() -> void :
	if _poll_timer and is_instance_valid(_poll_timer):
		_poll_timer.wait_time = POLL_SEC_IN_ROOM if _resolve_my_room_id() > 0 else POLL_SEC_LOBBY

static func _setup_poll(game_manager, parent_panel: Control) -> void :
	if _poll_timer and is_instance_valid(_poll_timer):
		_poll_timer.queue_free()
	_poll_timer = Timer.new()
	_poll_timer.wait_time = POLL_SEC_LOBBY
	_poll_timer.autostart = true
	parent_panel.add_child(_poll_timer)
	_poll_timer.timeout.connect( func():
		if not is_instance_valid(parent_panel) or not parent_panel.visible:
			return
		var gm = parent_panel.get_meta("bt_game_manager", null)
		if gm == null or gm.network == null:
			return
		if gm.is_brother_tower_battle or gm.is_brother_tower_settling:
			return
		var in_room: = _resolve_my_room_id() > 0
		var scope: = "in_room" if in_room else "lobby"
		if in_room:
			gm.network.get_brother_tower_list()
		gm.network.get_brother_tower_poll(scope)
		_update_poll_interval()
	)

static func refresh_panel(game_manager, parent_panel: Control) -> void :
	if not is_instance_valid(parent_panel):
		return
	var easy_start: int = int(_bt_difficulty_preset(game_manager, "easy").get("levelStart", 0))
	var cfg_size: int = 0
	if game_manager != null and game_manager.has_method("get_brother_tower_runtime_config"):
		var cfg: Variant = game_manager.get_brother_tower_runtime_config()
		if cfg is Dictionary:
			var diffs: Variant = cfg.get("difficulties", [])
			cfg_size = diffs.size() if diffs is Array else 0
	print("[BrotherTowerUI] ui_rev=20260620_207 level=%s easy_start=%d diffs=%d" % [
		_bt_level_range_text(game_manager, _selected_difficulty), 
		easy_start, 
		cfg_size, 
	])
	var info_left: Array = parent_panel.get_meta("bt_info_left", [])
	var info_right: Array = parent_panel.get_meta("bt_info_right", [])
	var teams_box: VBoxContainer = parent_panel.get_meta("bt_teams_box", null)
	if game_manager and game_manager.player:
		var p = game_manager.player
		var daily: = _daily_reward_count()
		var daily_max: = _daily_reward_max()
		var clears: = _daily_clear_count()
		var clear_max: = _daily_clear_max()
		var fp: = int(_status_data.get("friendshipPoints", p.friendship_points if "friendship_points" in p else 0))
		var clear_full: = clears >= clear_max
		if info_left.size() >= 2:
			var player_name: Label = info_left[0]
			var player_level: Label = info_left[1]
			player_name.text = "玩家: %s" % p.player_name
			player_level.text = "等级: %d | 境界: %s | 投胎: %d" % [p.level, p.realm, p.reincarnation]
		if info_right.size() >= 3:
			var daily_label: Label = info_right[0]
			var daily_clear_label: Label = info_right[1]
			var fp_label: Label = info_right[2]
			daily_label.text = "今日奖励: %d/%d" % [daily, daily_max]
			daily_clear_label.text = "今日通关: %d/%d" % [clears, clear_max]
			if clear_full:
				daily_clear_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45))
			else:
				daily_clear_label.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
			fp_label.text = "友情点: %d" % fp
	if teams_box:
		_rebuild_team_cards(game_manager, parent_panel, teams_box)
	_sync_challenge_card_difficulty(parent_panel)
	_refresh_snapshot_panel(parent_panel)

static func _sync_challenge_card_difficulty(parent_panel: Control) -> void :
	if not is_instance_valid(parent_panel):
		return
	var game_manager = parent_panel.get_meta("bt_game_manager", null)
	var card = parent_panel.get_meta("bt_challenge_card", null)
	if not is_instance_valid(card):
		return
	var d1 = card.get_meta("bt_level_range_label", null)
	var d2 = card.get_meta("bt_battle_summary_label", null)
	var d3 = card.get_meta("bt_reward_summary_label", null)
	if is_instance_valid(d1):
		d1.text = _bt_wave_summary_line(game_manager, _selected_difficulty)
	if is_instance_valid(d2):
		d2.text = _bt_battle_summary_line(game_manager)
	if is_instance_valid(d3):
		d3.text = _bt_reward_summary_line(game_manager)

static func _room_exists_in_open_list(room_id: int) -> bool:
	if room_id <= 0:
		return false
	var rooms_raw = _list_data.get("rooms")
	if rooms_raw == null or not rooms_raw is Array:
		return false
	for room in rooms_raw:
		if room is Dictionary and _safe_int(room.get("roomId"), 0) == room_id:
			return true
	return false

static func _my_room_dict_is_empty(my_room) -> bool:
	if my_room == null:
		return true
	if not my_room is Dictionary:
		return true
	return (my_room as Dictionary).is_empty()

static func _is_optimistic_room_guard_active(room_id: int = 0) -> bool:
	var rid: = room_id if room_id > 0 else _resolve_my_room_id()
	if rid <= 0 or _optimistic_room_id != rid:
		return false
	return Time.get_ticks_msec() < _optimistic_guard_until_ms

static func _begin_optimistic_room_guard(room_id: int) -> void :
	if room_id <= 0:
		return
	_optimistic_room_id = room_id
	_optimistic_guard_until_ms = Time.get_ticks_msec() + OPTIMISTIC_ROOM_GUARD_MS

static func _clear_optimistic_room_guard(room_id: int = 0) -> void :
	if room_id > 0 and room_id != _optimistic_room_id:
		return
	_optimistic_room_id = 0
	_optimistic_guard_until_ms = 0

static func _patch_room_in_open_list(my_room: Dictionary) -> void :
	if my_room.is_empty():
		return
	var room_id: = _safe_int(my_room.get("roomId"), 0)
	if room_id <= 0:
		return
	var rooms_raw = _list_data.get("rooms")
	var rooms: Array = []
	if rooms_raw is Array:
		rooms = (rooms_raw as Array).duplicate(true)
	var found: = false
	for i in range(rooms.size()):
		var room = rooms[i]
		if room is Dictionary and _safe_int(room.get("roomId"), 0) == room_id:
			rooms[i] = my_room.duplicate(true)
			found = true
			break
	if not found:
		rooms.append(my_room.duplicate(true))
	_list_data["rooms"] = rooms

static func _apply_status_data(data: Dictionary) -> void :
	if data == null or not data is Dictionary:
		return
	var prev_room_id: = _resolve_my_room_id()
	var merged: = data.duplicate(true)
	var incoming_room_id: = _safe_int(merged.get("myRoomId"), 0)
	if incoming_room_id <= 0 and prev_room_id > 0:
		if _is_optimistic_room_guard_active(prev_room_id):
			merged["myRoomId"] = prev_room_id
		else:
			merged["myRoomId"] = 0
			_list_data["myRoom"] = {}
			_clear_optimistic_room_guard(prev_room_id)
	elif merged.get("myRoomId") == null:
		merged["myRoomId"] = 0
	if incoming_room_id > 0 and incoming_room_id == _optimistic_room_id:
		_clear_optimistic_room_guard(incoming_room_id)
	_status_data = merged
	_reconcile_my_room_with_open_list()

static func _merge_my_room_from_rooms_list(room_id: int = 0) -> void :
	var target_id: = room_id if room_id > 0 else _resolve_my_room_id()
	if target_id <= 0:
		return
	var rooms_raw = _list_data.get("rooms")
	if rooms_raw == null or not rooms_raw is Array:
		return
	for room in rooms_raw:
		if room is Dictionary and _safe_int(room.get("roomId"), 0) == target_id:
			var merged: Dictionary = (room as Dictionary).duplicate(true)
			var existing = _list_data.get("myRoom")
			if existing is Dictionary and not existing.is_empty():
				for k in existing.keys():
					if not merged.has(k) or merged.get(k) == null:
						merged[k] = existing[k]
			_list_data["myRoom"] = merged
			if _safe_int(_status_data.get("myRoomId"), 0) <= 0:
				_status_data["myRoomId"] = target_id
			return

static func _try_apply_my_room_from_rooms_as_leader(leader_id: int) -> bool:
	if leader_id <= 0:
		return false
	var rooms_raw = _list_data.get("rooms")
	if rooms_raw == null or not rooms_raw is Array:
		return false
	for room in rooms_raw:
		if room is Dictionary and _safe_int(room.get("leaderId"), 0) == leader_id:
			var rid: = _safe_int(room.get("roomId"), 0)
			if rid > 0:
				_apply_my_room_optimistic(rid, _safe_int(room.get("displayNo"), 0), leader_id)
				return true
	return false

static func _reconcile_my_room_with_open_list() -> void :
	var room_id: = _resolve_my_room_id()
	if room_id <= 0:
		return
	var auth_id: = _safe_int(_status_data.get("myRoomId"), 0)
	var my_room_raw = _list_data.get("myRoom")
	if auth_id <= 0 and _my_room_dict_is_empty(my_room_raw):
		if not _is_optimistic_room_guard_active(room_id):
			clear_my_room_local_state()
		return
	if _room_exists_in_open_list(room_id):
		return
	if auth_id > 0:
		return
	if _is_optimistic_room_guard_active(room_id):
		return
	clear_my_room_local_state()

static func _apply_list_data(data: Dictionary) -> void :
	if data == null or not data is Dictionary:
		return
	var local_room_id: = _resolve_my_room_id()
	var had_authoritative_my_room: = data.has("myRoom")
	if data.has("myPendingApplicationRoomIds"):
		_list_data["myPendingApplicationRoomIds"] = data.get("myPendingApplicationRoomIds")
	if data.has("rooms"):
		var incoming_rooms = data.get("rooms")
		if incoming_rooms is Array:
			_list_data["rooms"] = (incoming_rooms as Array).duplicate(true)
		else:
			_list_data["rooms"] = []
	if had_authoritative_my_room:
		var incoming_my_room = data.get("myRoom")
		if incoming_my_room is Dictionary and not incoming_my_room.is_empty():
			_list_data["myRoom"] = incoming_my_room
			_patch_room_in_open_list(incoming_my_room)
			var confirmed_id: = _safe_int(incoming_my_room.get("roomId"), 0)
			if confirmed_id > 0:
				_clear_optimistic_room_guard(confirmed_id)
		elif local_room_id <= 0:
			_list_data["myRoom"] = {} if incoming_my_room == null or incoming_my_room is Dictionary else {}
		elif not _is_optimistic_room_guard_active(local_room_id):
			clear_my_room_local_state()
			_clear_optimistic_room_guard(local_room_id)
	if not had_authoritative_my_room and _resolve_my_room_id() > 0:
		_merge_my_room_from_rooms_list()
	var my_room_raw = _list_data.get("myRoom")
	if my_room_raw == null or not my_room_raw is Dictionary:
		if _resolve_my_room_id() <= 0:
			_list_data["myRoom"] = {}
	elif not my_room_raw.is_empty() and my_room_raw.has("difficulty"):
		_selected_difficulty = BrotherTowerManager.normalize_difficulty(my_room_raw.get("difficulty"))
	var rooms_raw = _list_data.get("rooms")
	if rooms_raw == null or not rooms_raw is Array:
		if data.has("rooms"):
			_list_data["rooms"] = []
	_reconcile_my_room_with_open_list()
	_update_poll_interval()

static func _apply_my_room_optimistic(room_id: int, display_no: int = 0, leader_user_id: int = 0) -> void :
	if room_id <= 0:
		return
	_status_data["myRoomId"] = room_id
	var my_room: Dictionary = {}
	var existing = _list_data.get("myRoom")
	if existing is Dictionary:
		my_room = (existing as Dictionary).duplicate(true)
	my_room["roomId"] = room_id
	if display_no > 0:
		my_room["displayNo"] = display_no
	if leader_user_id > 0:
		my_room["leaderId"] = leader_user_id
	if not my_room.has("difficulty"):
		my_room["difficulty"] = _selected_difficulty
	_list_data["myRoom"] = my_room
	_begin_optimistic_room_guard(room_id)
	_update_poll_interval()

static func _patch_member_ready_in_array(members: Array, user_id: int, ready: bool) -> Array:
	var out: Array = []
	var found: = false
	for entry in members:
		if entry is Dictionary and _safe_int(entry.get("userId"), -1) == user_id:
			var patched: Dictionary = (entry as Dictionary).duplicate(true)
			patched["isReady"] = ready
			patched["is_ready"] = ready
			out.append(patched)
			found = true
		elif entry is Dictionary:
			out.append(entry)
	if not found and user_id > 0:
		out.append({"userId": user_id, "isReady": ready, "is_ready": ready})
	return out

static func _mark_local_member_ready(user_id: int, ready: bool = true) -> void :
	if user_id <= 0:
		return
	var my_room_raw = _list_data.get("myRoom")
	if my_room_raw is Dictionary:
		var my_room: Dictionary = (my_room_raw as Dictionary).duplicate(true)
		var members_raw = my_room.get("members")
		var members: Array = members_raw if members_raw is Array else []
		my_room["members"] = _patch_member_ready_in_array(members, user_id, ready)
		_list_data["myRoom"] = my_room
	var room_id: = _resolve_my_room_id()
	if room_id <= 0:
		return
	var rooms_raw = _list_data.get("rooms")
	if rooms_raw == null or not rooms_raw is Array:
		return
	var rooms: Array = []
	for room in rooms_raw:
		if room is Dictionary and _safe_int(room.get("roomId"), 0) == room_id:
			var patched_room: Dictionary = (room as Dictionary).duplicate(true)
			var r_members_raw = patched_room.get("members")
			var r_members: Array = r_members_raw if r_members_raw is Array else []
			patched_room["members"] = _patch_member_ready_in_array(r_members, user_id, ready)
			rooms.append(patched_room)
		elif room is Dictionary:
			rooms.append(room)
	_list_data["rooms"] = rooms

static func clear_my_room_local_state() -> void :
	var cleared_id: = _resolve_my_room_id()
	_status_data["myRoomId"] = 0
	_list_data["myRoom"] = {}
	_clear_optimistic_room_guard(cleared_id)
	_update_poll_interval()

static func clear_lobby_after_battle_end(game_manager = null) -> void :
	clear_my_room_local_state()
	var gm = game_manager if game_manager else _active_game_manager
	if gm and gm.network:
		gm.network.get_brother_tower_poll("lobby")
	if gm and _active_parent_panel and is_instance_valid(_active_parent_panel):
		refresh_panel(gm, _active_parent_panel)


static func reset_lobby_state_for_account_switch() -> void :
	_list_data = {}
	_status_data = {}
	_selected_difficulty = BrotherTowerManager.DIFFICULTY_EASY
	_last_missing_members_poll_ms = 0
	_lobby_op_pending = false
	_optimistic_room_id = 0
	_optimistic_guard_until_ms = 0
	_last_room_expired_notice_ms = 0
	if _poll_timer and is_instance_valid(_poll_timer):
		_poll_timer.queue_free()
	_poll_timer = null

static func _refresh_lobby_after_room_exit() -> void :
	if _active_game_manager and _active_game_manager.network:
		_active_game_manager.network.get_brother_tower_poll("lobby")
	if _active_game_manager and _active_parent_panel and is_instance_valid(_active_parent_panel):
		refresh_panel(_active_game_manager, _active_parent_panel)

static func on_status_loaded(_game_manager, parent_panel: Control, data: Dictionary) -> void :
	_apply_status_data(data)
	if _active_game_manager and is_instance_valid(parent_panel):
		refresh_panel(_active_game_manager, parent_panel)

static func on_list_loaded(game_manager, parent_panel: Control, data: Dictionary) -> void :
	_apply_list_data(data)
	_notify_my_room_expired(data, parent_panel)
	if game_manager and is_instance_valid(parent_panel):
		refresh_panel(game_manager, parent_panel)

static func get_my_room_id() -> int:
	return _resolve_my_room_id()

static func _resolve_my_room_dict(rooms: Array, my_room_id: int) -> Dictionary:
	if my_room_id <= 0:
		return {}
	var my_room_raw = _list_data.get("myRoom")
	var my_room: Dictionary = my_room_raw if my_room_raw is Dictionary else {}
	if _safe_int(my_room.get("roomId"), 0) == my_room_id and not my_room.is_empty():
		return my_room
	for room in rooms:
		if room is Dictionary and _safe_int(room.get("roomId"), 0) == my_room_id:
			return room
	var placeholder: = {"roomId": my_room_id}
	if my_room.has("displayNo"):
		placeholder["displayNo"] = my_room.get("displayNo")
	if my_room.has("difficulty"):
		placeholder["difficulty"] = my_room.get("difficulty")
	elif _selected_difficulty != "":
		placeholder["difficulty"] = _selected_difficulty
	return placeholder

static func _room_members_array(room: Dictionary) -> Array:
	var members = room.get("members", [])
	return members if members is Array else []

static func _room_member_count(room: Dictionary) -> int:
	var members: = _room_members_array(room)
	if not members.is_empty():
		return members.size()
	return maxi(0, _safe_int(room.get("memberCount"), 0))

static func _my_room_needs_member_refresh(my_room: Dictionary) -> bool:
	if my_room.is_empty():
		return true
	if not my_room.has("members"):
		return true
	var members: = _room_members_array(my_room)
	if members.is_empty():
		return true
	var max_m: = maxi(1, _safe_int(my_room.get("maxMembers"), 2))
	return members.size() < max_m

static func _rebuild_team_cards(game_manager, parent_panel: Control, box: VBoxContainer) -> void :
	for c in box.get_children():
		c.queue_free()
	_ensure_team_sort_loaded()
	var sort_btn = parent_panel.get_meta("bt_team_sort_btn", null) if is_instance_valid(parent_panel) else null
	if sort_btn is Button and is_instance_valid(sort_btn):
		sort_btn.text = _team_sort_button_text()
	var rooms_raw = _list_data.get("rooms")
	var rooms: Array = (rooms_raw if rooms_raw is Array else []).duplicate()
	_sort_rooms_by_created_at(rooms)
	var my_room_id: = _resolve_my_room_id()
	var my_room: Dictionary = _resolve_my_room_dict(rooms, my_room_id)
	if my_room_id > 0 and _my_room_needs_member_refresh(my_room):
		var now_ms: = Time.get_ticks_msec()
		if now_ms - _last_missing_members_poll_ms >= 2000:
			_last_missing_members_poll_ms = now_ms
			if game_manager and game_manager.network:
				game_manager.network.get_brother_tower_poll("in_room")
				game_manager.network.get_brother_tower_list()
	if my_room_id > 0:
		box.add_child(_create_team_card(game_manager, parent_panel, my_room, true, my_room_id))
		var sep: = Label.new()
		sep.text = "其他队伍"
		sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sep.add_theme_font_size_override("font_size", 14)
		sep.add_theme_color_override("font_color", Color(0.669, 0.649, 0.598))
		box.add_child(sep)
	else:
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
		var create_btn: = Button.new()
		if _lobby_op_pending:
			create_btn.text = "处理中…"
			create_btn.disabled = true
		else:
			create_btn.text = "创建队伍（需令牌）" if not _is_daily_clear_full() else "今日通关已满"
			create_btn.disabled = _is_daily_clear_full()
		create_btn.custom_minimum_size = Vector2(220, 50)
		_style_primary_button(create_btn)
		create_btn.pressed.connect( func(): _on_create_team(game_manager, parent_panel))
		create_col.add_child(create_btn)
		box.add_child(create_panel)
	for room in rooms:
		if not room is Dictionary:
			continue
		if int(room.get("roomId", 0)) == my_room_id:
			continue
		box.add_child(_create_team_card(game_manager, parent_panel, room, false, my_room_id))
	for child in box.get_children():
		if child is Control:
			_enable_touch_drag_passthrough(child as Control)

static func _safe_int(value, default_value: int = 0) -> int:
	if value == null:
		return default_value
	if value is int:
		return value
	if value is float:
		return int(value)
	if value is String:
		var text: = str(value).strip_edges()
		if text.is_empty():
			return default_value
		return int(float(text))
	return default_value

static func _resolve_my_room_id() -> int:
	var my_room_raw = _list_data.get("myRoom")
	if my_room_raw is Dictionary:
		var rid: = _safe_int(my_room_raw.get("roomId"), 0)
		if rid > 0:
			return rid
	return _safe_int(_status_data.get("myRoomId"), 0)

static func _create_team_card(game_manager, parent_panel: Control, room: Dictionary, is_mine: bool, my_room_id: int) -> Control:
	var card: = PanelContainer.new()
	var card_style: = UIStyle.create_item_style()
	if is_mine:
		card_style.bg_color = Color(0.092, 0.076, 0.044, 0.92)
		card_style.border_color = Color(0.8, 0.6, 0.2, 1.0)
	card.add_theme_stylebox_override("panel", card_style)
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
	if members == null or not members is Array:
		members = []
	var max_m: = int(room.get("maxMembers", 2))
	var count: = int(room.get("memberCount", members.size()))
	var diff_text: = _room_difficulty_label(room)
	var display_no: = _safe_int(room.get("displayNo", room.get("roomId", 0)), 0)
	var join_mode: = _room_join_mode(room)
	var join_hint: = "需审核" if join_mode == "review" else "自动加入"
	var title_lbl: = _line_label("队伍 #%d  【%s】  %s  人数 %d/%d" % [display_no, diff_text, join_hint, count, max_m], 16)
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
		members_row.add_child(_create_member_slot(game_manager, slot_member, i >= members.size()))

	var btn_v: = VBoxContainer.new()
	btn_v.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_v.add_theme_constant_override("separation", 8)
	row.add_child(btn_v)
	var room_id: = _safe_int(room.get("roomId"), 0)
	var leader_id: = _safe_int(room.get("leaderId"), 0)
	var my_id: int = -1
	if game_manager and game_manager.network:
		my_id = _safe_int(game_manager.network.user_id, -1)
	var i_am_leader: bool = is_mine and my_id > 0 and (
		(leader_id > 0 and leader_id == my_id) or bool(_find_member_by_user_id(members, my_id).get("isLeader", false))
	)
	var ready_info: = _get_teammate_ready_info(members)

	if is_mine:
		if i_am_leader:
			var ready_lbl: = _line_label(ready_info.text, 13)
			ready_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			ready_lbl.add_theme_color_override("font_color", ready_info.color)
			btn_v.add_child(ready_lbl)
			var start_btn: = Button.new()
			if _start_pending:
				start_btn.text = "开战同步中…"
				start_btn.disabled = true
			else:
				start_btn.text = "⚔️ 开始挑战"
				start_btn.disabled = count < max_m or not ready_info.all_ready
			start_btn.custom_minimum_size = Vector2(120, 48)
			_style_primary_button(start_btn)
			start_btn.pressed.connect( func(): _on_start(game_manager, parent_panel, room_id))
			btn_v.add_child(start_btn)
			if join_mode == "review" and count < max_m:
				var app_count: = _room_pending_application_count(room)
				var app_btn: = Button.new()
				app_btn.text = "查看申请(%d)" % app_count if app_count > 0 else "查看申请"
				app_btn.custom_minimum_size = Vector2(120, 40)
				_style_secondary_button(app_btn)
				app_btn.pressed.connect( func(): _show_application_list_popup(game_manager, parent_panel, room))
				btn_v.add_child(app_btn)
			var dis_btn: = Button.new()
			dis_btn.text = "解散"
			dis_btn.custom_minimum_size = Vector2(120, 40)
			_style_secondary_button(dis_btn)
			dis_btn.pressed.connect( func(): _on_disband(game_manager, room_id))
			btn_v.add_child(dis_btn)
		else:
			var my_ready: = _is_member_ready(_find_member_by_user_id(members, my_id))
			var ready_btn: = Button.new()
			ready_btn.custom_minimum_size = Vector2(120, 48)
			if _lobby_op_pending:
				ready_btn.text = "处理中…"
				ready_btn.disabled = true
				_style_secondary_button(ready_btn)
			elif my_ready:
				ready_btn.text = "已准备"
				_style_secondary_button(ready_btn)
			else:
				ready_btn.text = "准备"
				_style_primary_button(ready_btn)
			ready_btn.pressed.connect( func(): _on_ready(game_manager, parent_panel))
			btn_v.add_child(ready_btn)
			var leave_btn: = Button.new()
			leave_btn.text = "退出"
			leave_btn.custom_minimum_size = Vector2(120, 40)
			_style_secondary_button(leave_btn)
			leave_btn.pressed.connect( func(): _on_leave(game_manager, room_id))
			btn_v.add_child(leave_btn)
	else:
		var join_btn: = Button.new()
		var clear_full: = _is_daily_clear_full()
		var already_applied: = _has_pending_application(room_id)
		if _lobby_op_pending:
			join_btn.text = "处理中…"
			join_btn.disabled = true
		elif clear_full:
			join_btn.text = "次数已满"
			join_btn.disabled = true
		elif already_applied:
			join_btn.text = "已申请"
			join_btn.disabled = true
		else:
			join_btn.text = "申请"
			join_btn.disabled = count >= max_m or my_room_id > 0
		join_btn.custom_minimum_size = Vector2(120, 48)
		_style_primary_button(join_btn)
		join_btn.pressed.connect( func(): _on_join(game_manager, parent_panel, room_id))
		btn_v.add_child(join_btn)
	return card

static func _member_is_ready(member: Dictionary) -> bool:
	if member.is_empty():
		return false
	return bool(member.get("isReady", member.get("is_ready", false)))

static func _find_member_by_user_id(members: Array, user_id: int) -> Dictionary:
	for entry in members:
		if entry is Dictionary and _safe_int(entry.get("userId"), -1) == user_id:
			return entry
	return {}

static func _get_non_leader_members(members: Array) -> Array:
	var out: Array = []
	for entry in members:
		if entry is Dictionary and not bool(entry.get("isLeader", false)):
			out.append(entry)
	return out

static func _get_teammate_ready_info(members: Array) -> Dictionary:
	var teammates: = _get_non_leader_members(members)
	if teammates.is_empty():
		return {
			"text": "队友：等待加入", 
			"color": Color(0.6, 0.65, 0.75, 1.0), 
			"all_ready": false, 
		}
	for tm in teammates:
		if not _member_is_ready(tm):
			return {
				"text": "队友：未准备", 
				"color": Color(0.95, 0.75, 0.45, 1.0), 
				"all_ready": false, 
			}
	return {
		"text": "队友：已准备", 
		"color": Color(0.55, 0.9, 0.65, 1.0), 
		"all_ready": true, 
	}

static func _is_member_ready(member: Dictionary) -> bool:
	return _member_is_ready(member)

static func _format_member_level_text(level_value) -> String:
	if level_value == null:
		return "?"
	var text: = str(level_value).strip_edges()
	if text.is_empty() or text == "?":
		return "?"
	return str(int(float(text)))

static func _line_label(text: String, size: int) -> Label:
	var l: = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(0.894, 0.864, 0.803))
	return l

static func _resolve_member_character_id(game_manager, member: Dictionary) -> int:
	var cid: = int(member.get("playerCharacterId", member.get("player_character_id", -1)))
	if cid >= 0:
		return PlayerCharacterConfig.normalize_id(cid)
	if game_manager and game_manager.network and game_manager.player:
		if int(member.get("userId", -1)) == int(game_manager.network.user_id):
			return PlayerCharacterConfig.normalize_id(game_manager.player.player_character_id)
	return 0

static func _load_player_avatar_texture(character_id: int) -> Texture2D:
	var cid: = PlayerCharacterConfig.normalize_id(character_id)
	var path: = PlayerCharacterConfig.get_avatar_tx_path(cid)
	if not ResourceLoader.exists(path):
		path = PlayerCharacterConfig.get_avatar_tx_path(0)
	return load(path) as Texture2D

static func _create_avatar_frame() -> Panel:
	var frame: = Panel.new()
	frame.custom_minimum_size = Vector2(MEMBER_AVATAR_FRAME_SIZE, MEMBER_AVATAR_FRAME_SIZE)
	frame.clip_contents = true
	var style: = UIStyle.create_item_style()
	style.bg_color = Color(0.072, 0.080, 0.079, 1.0)
	style.border_color = UIStyle.COLORS.item_border
	frame.add_theme_stylebox_override("panel", style)
	return frame

static func _fill_avatar_frame(frame: Panel, tex: Texture2D = null, show_plus: bool = false) -> void :
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

static func _create_member_slot(game_manager, member: Dictionary, is_empty: bool) -> Control:
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

	var detail_lbl: = _line_label("", 11)
	detail_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	detail_lbl.custom_minimum_size = Vector2(MEMBER_SLOT_WIDTH - 8, 0)
	detail_lbl.add_theme_color_override("font_color", Color(0.760, 0.740, 0.680))
	col.add_child(detail_lbl)

	if is_empty or member.is_empty():
		_fill_avatar_frame(avatar_frame, null, true)
		name_lbl.text = "空位"
		detail_lbl.text = "等待加入"
		detail_lbl.add_theme_color_override("font_color", Color(0.631, 0.611, 0.564))
		return col

	var cid: = _resolve_member_character_id(game_manager, member)
	_fill_avatar_frame(avatar_frame, _load_player_avatar_texture(cid), false)

	if bool(member.get("isLeader", false)):
		var crown: = Label.new()
		crown.text = "👑"
		crown.position = Vector2(-2, -8)
		crown.z_index = 2
		crown.add_theme_font_size_override("font_size", 14)
		avatar_frame.add_child(crown)

	name_lbl.text = str(member.get("nickname", "?"))
	detail_lbl.text = "Lv.%s %s" % [_format_member_level_text(member.get("level", "?")), str(member.get("realm", ""))]
	return col

static func _find_existing_child_popup(parent_control: Control, popup_key: String) -> Control:
	if not is_instance_valid(parent_control):
		return null
	for child in parent_control.get_children():
		if child is Control and str(child.get_meta("popup_key", "")) == popup_key:
			return child
	return null

static func _mark_popup_key(popup: Node, popup_key: String) -> void :
	if popup:
		popup.set_meta("popup_key", popup_key)

static func _center_popup_in_parent(popup: Control, parent_control: Control) -> void :
	if not is_instance_valid(popup) or not is_instance_valid(parent_control):
		return
	popup.reset_size()
	var popup_size: Vector2 = popup.size
	if popup_size.x <= 0 or popup_size.y <= 0:
		popup_size = popup.custom_minimum_size
	popup.position = (parent_control.size - popup_size) / 2

static func _schedule_center_popup_in_parent(popup: Control, parent_control: Control) -> void :
	_center_popup_in_parent(popup, parent_control)
	if not is_instance_valid(parent_control):
		return
	var tree = parent_control.get_tree()
	if tree == null:
		return
	tree.create_timer(0.0).timeout.connect( func() -> void :
		_center_popup_in_parent(popup, parent_control)
	, CONNECT_ONE_SHOT)

static func _is_mirror_popup_open(parent_panel: Control = null) -> bool:
	var host: = parent_panel if is_instance_valid(parent_panel) else _active_parent_panel
	if not is_instance_valid(host):
		return false
	var existing: Variant = host.get_meta("arena_mirror_popup", null)
	return existing is Window and is_instance_valid(existing)

static func _show_msg(parent_panel: Control, msg: String) -> void :
	print("[BrotherTowerUI] ", msg)
	if not is_instance_valid(parent_panel):
		return
	var popup_key: = "brother_tower_message_popup:%s" % msg
	var existing: = _find_existing_child_popup(parent_panel, popup_key)
	if existing and is_instance_valid(existing):
		existing.show()
		return
	var popup: = Panel.new()
	_mark_popup_key(popup, popup_key)
	var line_count: int = msg.split("\n").size()
	var content_height: int = maxi(80, line_count * 24)
	var popup_height: int = clampi(140 + content_height, 220, 560)
	popup.custom_minimum_size = Vector2(420, popup_height)
	popup.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	parent_panel.add_child(popup)

	var vbox: = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 25
	vbox.offset_top = 25
	vbox.offset_right = -25
	vbox.offset_bottom = -25
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	popup.add_child(vbox)

	var title_lbl: = Label.new()
	title_lbl.text = "兄弟天关"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", UIStyle.COLORS.title_color)
	vbox.add_child(title_lbl)

	var msg_label: = RichTextLabel.new()
	msg_label.bbcode_enabled = true
	msg_label.text = msg
	msg_label.fit_content = true
	msg_label.scroll_active = false
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.add_theme_font_size_override("normal_font_size", 18)
	msg_label.add_theme_color_override("default_color", Color(0.894, 0.864, 0.803))
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	msg_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(msg_label)

	var ok_btn: = Button.new()
	ok_btn.text = "确定"
	UIStyle.style_popup_button(ok_btn, true)
	ok_btn.pressed.connect( func(): popup.queue_free())
	vbox.add_child(ok_btn)
	_schedule_center_popup_in_parent(popup, parent_panel)

static func _popup_option_style(selected: bool) -> StyleBoxFlat:
	var st: = StyleBoxFlat.new()
	st.bg_color = Color(0.118, 0.100, 0.058, 0.98) if selected else Color(0.070, 0.062, 0.046, 0.96)
	st.corner_radius_top_left = 0
	st.corner_radius_top_right = 0
	st.corner_radius_bottom_left = 0
	st.corner_radius_bottom_right = 0
	st.border_width_left = 1
	st.border_width_top = 1
	st.border_width_right = 1
	st.border_width_bottom = 1
	st.border_color = Color(1, 0.82, 0.45, 0.95) if selected else Color(0.873, 0.743, 0.432, 0.9)
	return st

static func _make_overlay_panel(parent_panel: Control, title_text: String, size: Vector2) -> Dictionary:
	var overlay: = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.offset_left = 0
	overlay.offset_top = 0
	overlay.offset_right = 0
	overlay.offset_bottom = 0
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	parent_panel.add_child(overlay)
	var center: = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel: = PanelContainer.new()
	panel.custom_minimum_size = size
	center.add_child(panel)
	var panel_style: = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.060, 0.068, 0.069, 0.98)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.947, 0.837, 0.553, 0.95)
	panel_style.corner_radius_top_left = 0
	panel_style.corner_radius_top_right = 0
	panel_style.corner_radius_bottom_left = 0
	panel_style.corner_radius_bottom_right = 0
	panel_style.content_margin_left = 16
	panel_style.content_margin_top = 16
	panel_style.content_margin_right = 16
	panel_style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", panel_style)
	var root: = VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)
	var title: = Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", UIStyle.COLORS.title_color)
	root.add_child(title)
	return {"overlay": overlay, "root": root}

static func _show_create_options_popup(game_manager, parent_panel: Control) -> void :
	if not is_instance_valid(parent_panel):
		return
	var shell: = _make_overlay_panel(parent_panel, "创建队伍", Vector2(460, 520))
	var overlay: ColorRect = shell["overlay"]
	var root: VBoxContainer = shell["root"]
	var selected: = {"difficulty": "", "joinMode": ""}
	var scroll: = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	TouchScrollUtils.configure_scroll(scroll)
	var content: = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)
	var diff_hint: = Label.new()
	diff_hint.text = "选择难度"
	diff_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	diff_hint.add_theme_font_size_override("font_size", 16)
	content.add_child(diff_hint)
	var diff_buttons: Array = []
	var confirm_btn: = Button.new()
	confirm_btn.text = "确定创建"
	confirm_btn.disabled = true
	confirm_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	confirm_btn.custom_minimum_size = Vector2(140, 44)
	var apply_diff_visuals: = func() -> void :
		for child in diff_buttons:
			if not (child is Button) or not is_instance_valid(child):
				continue
			var b: = child as Button
			var is_sel: = str(b.get_meta("bt_diff_id", "")) == str(selected["difficulty"])
			var st: = _popup_option_style(is_sel)
			b.add_theme_stylebox_override("normal", st)
			b.add_theme_stylebox_override("hover", st)
			b.add_theme_stylebox_override("pressed", st)
		confirm_btn.disabled = str(selected["difficulty"]).is_empty() or str(selected["joinMode"]).is_empty()
	for row in BrotherTowerManager.list_difficulties(game_manager):
		if not (row is Dictionary):
			continue
		var diff_id: = str(row.get("id", "")).strip_edges()
		if diff_id.is_empty():
			continue
		var opt_btn: = Button.new()
		opt_btn.text = "%s  %d→%d  礼包×%d  友情+%d" % [
			str(row.get("label", diff_id)), 
			int(row.get("levelStart", 0)), 
			int(row.get("levelEnd", 0)), 
			int(row.get("giftCount", 1)), 
			int(row.get("friendshipGain", 1)), 
		]
		opt_btn.focus_mode = Control.FOCUS_NONE
		opt_btn.custom_minimum_size = Vector2(0, 48)
		opt_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		opt_btn.add_theme_font_size_override("font_size", 16)
		opt_btn.set_meta("bt_diff_id", diff_id)
		TouchScrollUtils.bind_tap(opt_btn, func():
			selected["difficulty"] = diff_id
			apply_diff_visuals.call()
		)
		content.add_child(opt_btn)
		diff_buttons.append(opt_btn)
	var mode_hint: = Label.new()
	mode_hint.text = "入队方式"
	mode_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode_hint.add_theme_font_size_override("font_size", 16)
	content.add_child(mode_hint)
	var mode_buttons: Array = []
	var apply_mode_visuals: = func() -> void :
		for child in mode_buttons:
			if not (child is Button) or not is_instance_valid(child):
				continue
			var b: = child as Button
			var is_sel: = str(b.get_meta("bt_join_mode", "")) == str(selected["joinMode"])
			var st: = _popup_option_style(is_sel)
			b.add_theme_stylebox_override("normal", st)
			b.add_theme_stylebox_override("hover", st)
			b.add_theme_stylebox_override("pressed", st)
		confirm_btn.disabled = str(selected["difficulty"]).is_empty() or str(selected["joinMode"]).is_empty()
	for mode_pair in [["auto", "自动允许加入"], ["review", "需要审核"]]:
		var mode_id: = str(mode_pair[0])
		var mode_btn: = Button.new()
		mode_btn.text = str(mode_pair[1])
		mode_btn.focus_mode = Control.FOCUS_NONE
		mode_btn.custom_minimum_size = Vector2(0, 48)
		mode_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mode_btn.add_theme_font_size_override("font_size", 16)
		mode_btn.set_meta("bt_join_mode", mode_id)
		TouchScrollUtils.bind_tap(mode_btn, func():
			selected["joinMode"] = mode_id
			apply_mode_visuals.call()
		)
		content.add_child(mode_btn)
		mode_buttons.append(mode_btn)
	apply_diff_visuals.call()
	apply_mode_visuals.call()
	var btn_row: = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	root.add_child(btn_row)
	var cancel_btn: = Button.new()
	cancel_btn.text = "取消"
	cancel_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cancel_btn.custom_minimum_size = Vector2(120, 44)
	_style_secondary_button(cancel_btn)
	cancel_btn.pressed.connect( func():
		if is_instance_valid(overlay):
			overlay.queue_free()
	)
	btn_row.add_child(cancel_btn)
	_style_primary_button(confirm_btn)
	confirm_btn.pressed.connect( func():
		var diff_id: = str(selected["difficulty"])
		var mode_id: = str(selected["joinMode"])
		if diff_id.is_empty() or mode_id.is_empty():
			return
		if is_instance_valid(overlay):
			overlay.queue_free()
		_do_create_team(game_manager, diff_id, mode_id)
	)
	btn_row.add_child(confirm_btn)

static func _show_application_list_popup(game_manager, parent_panel: Control, room: Dictionary) -> void :
	if not is_instance_valid(parent_panel):
		return
	var apps: = _collect_room_applications(room)
	var room_id: = _safe_int(room.get("roomId"), 0)
	var popup_h: = 220
	if not apps.is_empty():
		popup_h = clampi(168 + apps.size() * 96, 240, 480)
	var shell: = _make_overlay_panel(parent_panel, "入队申请", Vector2(480, popup_h))
	var overlay: ColorRect = shell["overlay"]
	var root: VBoxContainer = shell["root"]
	var scroll: = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	TouchScrollUtils.configure_scroll(scroll)
	var content: = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)
	if apps.is_empty():
		var empty: = Label.new()
		empty.text = "暂无申请"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_font_size_override("font_size", 16)
		content.add_child(empty)
	for app in apps:
		if not (app is Dictionary):
			continue
		var row: = PanelContainer.new()
		row.add_theme_stylebox_override("panel", UIStyle.create_item_style())
		var pad: = MarginContainer.new()
		pad.add_theme_constant_override("margin_left", 8)
		pad.add_theme_constant_override("margin_right", 8)
		pad.add_theme_constant_override("margin_top", 8)
		pad.add_theme_constant_override("margin_bottom", 8)
		row.add_child(pad)
		var inner: = HBoxContainer.new()
		inner.add_theme_constant_override("separation", 10)
		pad.add_child(inner)
		var frame: = _create_avatar_frame()
		frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var cid: = int(app.get("playerCharacterId", app.get("player_character_id", 0)))
		_fill_avatar_frame(frame, _load_player_avatar_texture(cid), false)
		inner.add_child(frame)
		var info: = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		info.add_theme_constant_override("separation", 2)
		inner.add_child(info)
		info.add_child(_line_label(str(app.get("nickname", "修士")), 16))
		info.add_child(_line_label("等级 %s | %s | 投胎 %d" % [
			_format_member_level_text(app.get("level", app.get("player_level", "?"))), 
			str(app.get("realm", app.get("player_realm", "凡人"))), 
			int(app.get("reincarnation", 0)), 
		], 13))
		var act: = VBoxContainer.new()
		act.alignment = BoxContainer.ALIGNMENT_CENTER
		act.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		act.add_theme_constant_override("separation", 6)
		inner.add_child(act)
		var uid: = _safe_int(app.get("userId"), 0)
		var agree_btn: = Button.new()
		agree_btn.text = "同意"
		agree_btn.custom_minimum_size = Vector2(88, 40)
		_style_primary_button(agree_btn)
		TouchScrollUtils.bind_tap(agree_btn, func():
			if _lobby_op_pending:
				return
			set_lobby_op_pending(true)
			if is_instance_valid(overlay):
				overlay.queue_free()
			game_manager.network.brother_tower_decide_application(room_id, uid, true)
		)
		act.add_child(agree_btn)
		var reject_btn: = Button.new()
		reject_btn.text = "拒绝"
		reject_btn.custom_minimum_size = Vector2(88, 36)
		_style_secondary_button(reject_btn)
		TouchScrollUtils.bind_tap(reject_btn, func():
			if _lobby_op_pending:
				return
			set_lobby_op_pending(true)
			if is_instance_valid(overlay):
				overlay.queue_free()
			game_manager.network.brother_tower_decide_application(room_id, uid, false)
		)
		act.add_child(reject_btn)
		content.add_child(row)
	var close_row: = HBoxContainer.new()
	close_row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(close_row)
	var close_btn: = Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(120, 44)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_style_secondary_button(close_btn)
	close_btn.pressed.connect( func():
		if is_instance_valid(overlay):
			overlay.queue_free()
	)
	close_row.add_child(close_btn)

static func _on_create_team(game_manager, parent_panel: Control) -> void :
	if not game_manager or not game_manager.network:
		return
	if _lobby_op_pending:
		return
	if game_manager.player.reincarnation < 1:
		_show_msg(parent_panel, "需要投胎数≥1")
		return
	if _is_daily_clear_full():
		_show_msg(parent_panel, "今日兄弟天关通关次数已满（%d/%d），无法创建队伍" % [_daily_clear_count(), _daily_clear_max()])
		return
	if game_manager.inventory_manager == null or not game_manager.inventory_manager.has_item(TOKEN_NAME, 1):
		_show_msg(parent_panel, "需要【%s】" % TOKEN_NAME)
		return
	if not _ensure_pinned_snapshot(parent_panel):
		return
	_show_create_options_popup(game_manager, parent_panel)

static func _do_create_team(game_manager, difficulty: String, join_mode: String) -> void :
	if not game_manager or not game_manager.network:
		return
	if _lobby_op_pending:
		return
	_selected_difficulty = BrotherTowerManager.normalize_difficulty(difficulty, game_manager)
	var mode: = "review" if str(join_mode) == "review" else "auto"
	set_lobby_op_pending(true)
	var op: = "bt_create_%d" % Time.get_unix_time_from_system()
	game_manager.network.brother_tower_create(op, _selected_difficulty, mode)

static func _on_join(game_manager, parent_panel: Control, room_id: int) -> void :
	_on_join_async(game_manager, parent_panel, room_id)

static func _on_join_async(game_manager, parent_panel: Control, room_id: int) -> void :
	if not game_manager or not game_manager.network:
		return
	if _lobby_op_pending:
		return
	if game_manager.player.reincarnation < 1:
		_show_msg(parent_panel, "需要投胎数≥1")
		return
	if _is_daily_clear_full():
		_show_msg(parent_panel, "今日兄弟天关通关次数已满（%d/%d），无法申请入队" % [_daily_clear_count(), _daily_clear_max()])
		return
	if not _ensure_pinned_snapshot(parent_panel):
		return
	set_lobby_op_pending(true)
	var op: = "bt_join_%d_%d" % [room_id, Time.get_unix_time_from_system()]
	game_manager.network.brother_tower_join(room_id, op)

static func _on_leave(game_manager, _room_id: int) -> void :
	if game_manager and game_manager.network:
		game_manager.network.brother_tower_leave()

static func _on_disband(game_manager, _room_id: int) -> void :
	if game_manager and game_manager.network:
		game_manager.network.brother_tower_disband()

static func _on_start(game_manager, parent_panel: Control, room_id: int) -> void :
	if not game_manager:
		return
	if not _ensure_pinned_snapshot(parent_panel):
		return
	var block_msg: = ""
	if game_manager.has_method("get_instanced_challenge_block_message"):
		block_msg = str(game_manager.get_instanced_challenge_block_message("brother_tower"))
	elif game_manager.has_method("is_in_instanced_challenge") and game_manager.is_in_instanced_challenge():
		block_msg = "其他挑战正在进行中，请先完成或停止当前挑战后再试"
	if not block_msg.is_empty():
		_show_msg(parent_panel, block_msg)
		return
	if game_manager.inventory_manager == null or not game_manager.inventory_manager.has_item(TOKEN_NAME, 1):
		_show_msg(parent_panel, "需要【%s】，队长开战时消耗 1 个" % TOKEN_NAME)
		return
	if game_manager.has_method("request_brother_tower_start"):
		set_start_pending(true)
		game_manager.request_brother_tower_start(room_id)
	else:
		_show_msg(parent_panel, "战斗模块未就绪，请重试")

static func _on_ready(game_manager, parent_panel: Control) -> void :
	_on_ready_async(game_manager, parent_panel)

static func _on_ready_async(game_manager, parent_panel: Control) -> void :
	if not game_manager or not game_manager.network:
		return
	if _lobby_op_pending:
		return
	if not _ensure_pinned_snapshot(parent_panel):
		return
	set_lobby_op_pending(true)
	game_manager.network.brother_tower_ready()

static func game_manager_dialog(_parent_panel: Control) -> bool:
	return false

static func notify_start_error(msg: String) -> void :
	set_start_pending(false)
	print("[BrotherTowerUI] ", msg)
	if _active_parent_panel and is_instance_valid(_active_parent_panel):
		_show_msg(_active_parent_panel, msg)

static func notify_info(msg: String) -> void :
	print("[BrotherTowerUI] ", msg)
	if _active_parent_panel and is_instance_valid(_active_parent_panel):
		_show_msg(_active_parent_panel, msg)

static var _signals_connected: bool = false
static var _active_game_manager = null
static var _active_parent_panel: Control = null

static func refresh_active_panel_if_open(game_manager) -> void :
	if game_manager == null:
		return
	if _active_game_manager != game_manager:
		return
	if _active_parent_panel == null or not is_instance_valid(_active_parent_panel):
		return
	refresh_panel(game_manager, _active_parent_panel)

static func ensure_signals_connected(game_manager, parent_panel: Control) -> void :
	_active_game_manager = game_manager
	_active_parent_panel = parent_panel
	if _signals_connected or game_manager == null or game_manager.network == null:
		return
	_signals_connected = true
	var net = game_manager.network
	net.brother_tower_list_loaded.connect(_on_list_signal)
	net.brother_tower_list_failed.connect(_on_list_failed_signal)
	net.brother_tower_poll_failed.connect(_on_poll_failed_signal)
	net.brother_tower_status_loaded.connect(_on_status_signal)
	net.brother_tower_create_success.connect(_on_create_success_signal)
	net.brother_tower_join_success.connect(_on_join_success_signal)
	net.brother_tower_create_failed.connect(_on_op_failed_signal)
	net.brother_tower_join_failed.connect(_on_op_failed_signal)
	if net.has_signal("brother_tower_application_decide_success") and not net.brother_tower_application_decide_success.is_connected(_on_application_decide_success_signal):
		net.brother_tower_application_decide_success.connect(_on_application_decide_success_signal)
	if net.has_signal("brother_tower_application_decide_failed") and not net.brother_tower_application_decide_failed.is_connected(_on_op_failed_signal):
		net.brother_tower_application_decide_failed.connect(_on_op_failed_signal)
	net.brother_tower_leave_success.connect(_on_leave_success_signal)
	net.brother_tower_leave_failed.connect(_on_leave_failed_signal)
	net.brother_tower_disband_success.connect(_on_disband_success_signal)
	net.brother_tower_disband_failed.connect(_on_disband_failed_signal)
	net.brother_tower_ready_success.connect(_on_ready_success_signal)
	net.brother_tower_ready_failed.connect(_on_op_failed_signal)
	net.brother_tower_pin_snapshot_success.connect(_on_pin_snapshot_success_signal)
	net.brother_tower_pin_snapshot_failed.connect(_on_pin_snapshot_failed_signal)

static func _on_pin_snapshot_success_signal(data: Dictionary) -> void :
	_snapshot_pin_pending = false
	_snapshot_pin_cooldown_until_ms = Time.get_ticks_msec() + SNAPSHOT_PIN_COOLDOWN_MS
	var summary = data.get("summary", {})
	if summary is Dictionary and not summary.is_empty():
		var pinned: Dictionary = {}
		var raw_pinned = _status_data.get("pinnedSnapshot", {})
		if raw_pinned is Dictionary:
			pinned = raw_pinned.duplicate(true)
		for key in summary.keys():
			pinned[key] = summary[key]
		pinned["hasPinned"] = true
		var pinned_at: = str(data.get("pinnedAt", pinned.get("pinnedAt", "")))
		if not pinned_at.is_empty():
			pinned["pinnedAt"] = pinned_at
		_status_data["pinnedSnapshot"] = pinned
	if _active_game_manager and _active_game_manager.network:
		_active_game_manager.network.get_brother_tower_status()
	if _active_game_manager and _active_parent_panel and is_instance_valid(_active_parent_panel):
		_refresh_snapshot_panel(_active_parent_panel)
		if not _is_mirror_popup_open(_active_parent_panel):
			_show_msg(_active_parent_panel, "人物与出战宠快照已更新")

static func _on_pin_snapshot_failed_signal(err: String) -> void :
	_snapshot_pin_pending = false
	if _active_parent_panel and is_instance_valid(_active_parent_panel):
		_refresh_snapshot_panel(_active_parent_panel)
		if not _is_mirror_popup_open(_active_parent_panel):
			_show_msg(_active_parent_panel, err if not err.is_empty() else "更新人物与出战宠快照失败")

static func _notify_my_room_expired(data: Dictionary, parent_panel: Control) -> void :
	if data == null or not data is Dictionary:
		return
	if not bool(data.get("myRoomExpired", false)):
		return
	var now_ms: = Time.get_ticks_msec()
	if now_ms - _last_room_expired_notice_ms < 8000:
		return
	_last_room_expired_notice_ms = now_ms
	var panel: = parent_panel if is_instance_valid(parent_panel) else _active_parent_panel
	if is_instance_valid(panel):
		_show_msg(panel, "队伍创建超过1小时未开战，已自动解散")

static func _on_list_signal(data: Dictionary) -> void :
	_apply_list_data(data)
	_notify_my_room_expired(data, _active_parent_panel)
	if _active_game_manager and _active_parent_panel and is_instance_valid(_active_parent_panel):
		refresh_panel(_active_game_manager, _active_parent_panel)

static func _on_create_success_signal(data: Dictionary) -> void :
	set_lobby_op_pending(false)
	var room_id: = _safe_int(data.get("roomId"), 0)
	var display_no: = _safe_int(data.get("displayNo"), 0)
	var leader_id: = 0
	if _active_game_manager and _active_game_manager.network:
		leader_id = _safe_int(_active_game_manager.network.user_id, 0)
	if room_id > 0:
		_apply_my_room_optimistic(room_id, display_no, leader_id)
	elif leader_id > 0:
		_try_apply_my_room_from_rooms_as_leader(leader_id)
	if _active_game_manager and _active_game_manager.network:
		var scope: = "in_room" if _resolve_my_room_id() > 0 else "lobby"
		_active_game_manager.network.get_brother_tower_poll(scope)
		if room_id <= 0 and _resolve_my_room_id() <= 0 and _active_parent_panel and is_instance_valid(_active_parent_panel):
			_show_msg(_active_parent_panel, "队伍已创建，正在同步…")
	if _active_game_manager and _active_parent_panel and is_instance_valid(_active_parent_panel):
		refresh_panel(_active_game_manager, _active_parent_panel)

static func _on_join_success_signal(data: Dictionary) -> void :
	set_lobby_op_pending(false)
	var room_id: = _safe_int(data.get("roomId"), 0)
	var applied_only: = bool(data.get("applied", false)) and not bool(data.get("joined", false))
	if applied_only:
		var pending: Array = []
		var raw: Variant = _list_data.get("myPendingApplicationRoomIds", [])
		if raw is Array:
			pending = raw.duplicate()
		if room_id > 0 and not pending.has(room_id):
			pending.append(room_id)
		_list_data["myPendingApplicationRoomIds"] = pending
		if _active_game_manager and _active_game_manager.network:
			_active_game_manager.network.get_brother_tower_poll("lobby")
		if _active_parent_panel and is_instance_valid(_active_parent_panel):
			_show_msg(_active_parent_panel, "已申请，等待队长同意")
			refresh_panel(_active_game_manager, _active_parent_panel)
		return
	if room_id > 0:
		_apply_my_room_optimistic(room_id, 0)
	if _active_game_manager and _active_parent_panel and is_instance_valid(_active_parent_panel):
		refresh_panel(_active_game_manager, _active_parent_panel)

static func _on_application_decide_success_signal(data: Dictionary) -> void :
	set_lobby_op_pending(false)
	if _active_game_manager and _active_game_manager.network:
		_active_game_manager.network.get_brother_tower_poll("in_room")
	if _active_parent_panel and is_instance_valid(_active_parent_panel):
		if bool(data.get("approved", false)):
			_show_msg(_active_parent_panel, "已同意申请")
		else:
			_show_msg(_active_parent_panel, "已拒绝申请")
		if _active_game_manager:
			refresh_panel(_active_game_manager, _active_parent_panel)

static func _on_ready_success_signal(_data: Dictionary) -> void :
	set_lobby_op_pending(false)
	if _active_game_manager and _active_game_manager.network:
		var uid: = _safe_int(_active_game_manager.network.user_id, 0)
		if uid > 0:
			_mark_local_member_ready(uid, true)
		_active_game_manager.network.get_brother_tower_poll("in_room")
	if _active_game_manager and _active_parent_panel and is_instance_valid(_active_parent_panel):
		refresh_panel(_active_game_manager, _active_parent_panel)

static func _on_poll_failed_signal(err: String) -> void :
	if _active_parent_panel and is_instance_valid(_active_parent_panel):
		_show_msg(_active_parent_panel, err)

static func _on_list_failed_signal(err: String) -> void :
	if _active_parent_panel and is_instance_valid(_active_parent_panel):
		_show_msg(_active_parent_panel, err)

static func _on_status_signal(data: Dictionary) -> void :
	_apply_status_data(data)
	if _active_game_manager and _active_parent_panel and is_instance_valid(_active_parent_panel):
		refresh_panel(_active_game_manager, _active_parent_panel)
	if _active_game_manager and _active_game_manager.player and data.has("friendshipPoints"):
		_active_game_manager.player.friendship_points = int(data.get("friendshipPoints", 0))

static func _on_op_failed_signal(err: String) -> void :
	set_lobby_op_pending(false)
	if _active_parent_panel and is_instance_valid(_active_parent_panel):
		_show_msg(_active_parent_panel, err)

static func _on_leave_success_signal(_data: Dictionary) -> void :
	clear_my_room_local_state()
	_refresh_lobby_after_room_exit()

static func _on_disband_success_signal(_data: Dictionary) -> void :
	clear_my_room_local_state()
	_refresh_lobby_after_room_exit()

static func _on_leave_failed_signal(err: String) -> void :
	if _active_parent_panel and is_instance_valid(_active_parent_panel):
		_show_msg(_active_parent_panel, err if not err.is_empty() else "退出失败")

static func _on_disband_failed_signal(err: String) -> void :
	if "没有可解散" in err:
		clear_my_room_local_state()
		_refresh_lobby_after_room_exit()
	if _active_parent_panel and is_instance_valid(_active_parent_panel):
		_show_msg(_active_parent_panel, err if not err.is_empty() else "解散失败")
