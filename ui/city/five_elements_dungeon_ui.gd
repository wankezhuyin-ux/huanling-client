class_name FiveElementsDungeonUI
extends RefCounted

const UIStyle = preload("res://scripts/ui_style.gd")
const TouchScrollUtils = preload("res://scripts/ui/touch_scroll_utils.gd")

const FIVE_ELEMENTS: = ["金", "木", "水", "火", "土"]
const DIFFICULTIES: = ["简单", "困难", "地狱"]
const CULTIVATION_THRESHOLD: = 1000000
const CULTIVATION_COST: = 10000
const YUANBAO_COST: = 100
const MAX_YUANBAO_ATTEMPTS: = 1
const ELEMENT_ICON_PATHS: = {
	"金": "res://assets/icons/five_elements/icon_jin.png", 
	"木": "res://assets/icons/five_elements/icon_mu.png", 
	"水": "res://assets/icons/five_elements/icon_shui.png", 
	"火": "res://assets/icons/five_elements/icon_huo.png", 
	"土": "res://assets/icons/five_elements/icon_tu.png", 
}

static var _element_colors: = {
	"金": Color(1, 0.84, 0), 
	"木": Color(0.13, 0.55, 0.13), 
	"水": Color(0, 0.75, 1), 
	"火": Color(1, 0.27, 0), 
	"土": Color(0.55, 0.27, 0.07), 
}

static func create_content(game_manager, parent_panel: Control) -> Control:
	var scroll: = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	TouchScrollUtils.configure_scroll(scroll)

	var margin_wrap: = MarginContainer.new()
	margin_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin_wrap.add_theme_constant_override("margin_left", 20)
	margin_wrap.add_theme_constant_override("margin_right", 20)
	margin_wrap.add_theme_constant_override("margin_top", 8)
	margin_wrap.add_theme_constant_override("margin_bottom", 20)
	scroll.add_child(margin_wrap)

	var vbox: = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 14)
	margin_wrap.add_child(vbox)

	var info_panel: = Panel.new()
	info_panel.custom_minimum_size = Vector2(0, 80)
	info_panel.add_theme_stylebox_override("panel", UIStyle.create_item_style())
	vbox.add_child(info_panel)

	var info_hbox: = HBoxContainer.new()
	info_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	info_hbox.offset_left = 15
	info_hbox.offset_top = 8
	info_hbox.offset_right = -15
	info_hbox.offset_bottom = -8
	info_panel.add_child(info_hbox)

	var left_info: = VBoxContainer.new()
	left_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_info.add_theme_constant_override("separation", 4)
	info_hbox.add_child(left_info)

	var cultivation_label: = Label.new()
	cultivation_label.name = "cultivation_label"
	cultivation_label.text = "修行值: %s" % _format_number(game_manager.player.cultivation)
	cultivation_label.add_theme_font_size_override("font_size", 16)
	cultivation_label.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
	left_info.add_child(cultivation_label)

	var cost_label: = Label.new()
	cost_label.text = "消耗: %s修行值/次  门槛: %s修行值" % [_format_number(CULTIVATION_COST), _format_number(CULTIVATION_THRESHOLD)]
	cost_label.add_theme_font_size_override("font_size", 14)
	cost_label.add_theme_color_override("font_color", Color(0.734, 0.714, 0.657))
	left_info.add_child(cost_label)

	var right_info: = VBoxContainer.new()
	right_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_info.add_theme_constant_override("separation", 4)
	info_hbox.add_child(right_info)

	var attempts_label: = Label.new()
	attempts_label.name = "attempts_label"
	attempts_label.text = "今日剩余: 同步中…"
	attempts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	attempts_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	attempts_label.add_theme_font_size_override("font_size", 16)
	attempts_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	right_info.add_child(attempts_label)

	parent_panel.set_meta("fe_cultivation_label", cultivation_label)
	parent_panel.set_meta("fe_attempts_label", attempts_label)
	parent_panel.set_meta("fe_game_manager", game_manager)
	_ensure_fe_status_hooks(game_manager, parent_panel)

	parent_panel.set_meta("fe_diff_idx", 0)
	var diff_bar: = HBoxContainer.new()
	diff_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	diff_bar.add_theme_constant_override("separation", 12)
	diff_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(diff_bar)

	var diff_btns: Array = []
	for i in range(DIFFICULTIES.size()):
		var chip: = Button.new()
		chip.name = "fe_diff_chip_%d" % i
		chip.text = DIFFICULTIES[i]
		chip.custom_minimum_size = Vector2(90, 40)
		chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		chip.add_theme_font_size_override("font_size", 16)
		diff_bar.add_child(chip)
		diff_btns.append(chip)
		var chip_idx: = i
		var pick_diff: = func():
			_select_fe_difficulty(chip_idx, parent_panel)
		chip.pressed.connect(pick_diff)
		TouchScrollUtils.bind_tap(chip, pick_diff)
	parent_panel.set_meta("fe_diff_btns", diff_btns)
	_apply_fe_diff_chip_styles(parent_panel)

	for element in FIVE_ELEMENTS:
		var card: = _create_element_card(element, game_manager, parent_panel)
		vbox.add_child(card)

	_refresh_yuanbao_buttons(game_manager, parent_panel)
	_refresh_all_fe_level_labels(game_manager, parent_panel)
	if game_manager.get_fe_dungeon_runtime_config().is_empty() and game_manager.network and game_manager.network.has_method("fetch_gameplay_runtime_config"):
		game_manager.network.fetch_gameplay_runtime_config()


	var drop_panel: = PanelContainer.new()
	var drop_style: = UIStyle.create_item_style()
	drop_style.content_margin_left = 14
	drop_style.content_margin_right = 14
	drop_style.content_margin_top = 10
	drop_style.content_margin_bottom = 10
	drop_panel.add_theme_stylebox_override("panel", drop_style)
	vbox.add_child(drop_panel)

	var drop_vbox: = VBoxContainer.new()
	drop_vbox.add_theme_constant_override("separation", 8)
	drop_panel.add_child(drop_vbox)

	var drop_title: = Label.new()
	drop_title.text = "🎁 可能掉落"
	drop_title.add_theme_font_size_override("font_size", 17)
	drop_title.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
	drop_vbox.add_child(drop_title)

	var drop_text: = Label.new()
	drop_text.name = "fe_drop_summary_label"
	drop_text.text = _fe_drop_summary_text(game_manager)
	drop_text.add_theme_font_size_override("font_size", 16)
	drop_text.add_theme_color_override("font_color", Color(0.85, 0.85, 0.6))
	drop_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	drop_vbox.add_child(drop_text)
	parent_panel.set_meta("fe_drop_summary_label", drop_text)


	var hint_label: = Label.new()
	hint_label.text = "💡 若野外战斗进行中，点击挑战将自动排队等待结束后进入，建议先切换到低级地图减少等待；请勿切出战斗界面，否则会判挑战失败；元宝挑战同样需达到修行门槛，但不消耗修行值，每日限次。"
	hint_label.add_theme_font_size_override("font_size", 14)
	hint_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(hint_label)

	TouchScrollUtils.enable_touch_drag_passthrough(vbox)
	return scroll

static func _create_element_card(element: String, game_manager, parent_panel: Control) -> Control:
	var card: = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var card_style: = UIStyle.create_item_style()
	card_style.content_margin_left = 14
	card_style.content_margin_right = 14
	card_style.content_margin_top = 10
	card_style.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", card_style)

	var hbox: = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 10)
	card.add_child(hbox)

	var icon: = TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = _load_element_icon(element)
	hbox.add_child(icon)

	var info_vbox: = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 4)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(info_vbox)

	var name_label: = Label.new()
	name_label.text = "五行副本(%s)" % element
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", _element_colors.get(element, Color.WHITE))
	info_vbox.add_child(name_label)

	var level_label: = Label.new()
	level_label.name = "level_label_%s" % element
	level_label.add_theme_font_size_override("font_size", 13)
	level_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	level_label.clip_text = true
	info_vbox.add_child(level_label)

	parent_panel.set_meta("fe_level_label_%s" % element, level_label)
	_update_difficulty_info(level_label, int(parent_panel.get_meta("fe_diff_idx", 0)), game_manager)

	var challenge_btn: = Button.new()
	challenge_btn.name = "challenge_btn_%s" % element
	challenge_btn.text = "⚔️ 挑战"
	challenge_btn.custom_minimum_size = Vector2(100, 40)
	challenge_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	challenge_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	challenge_btn.add_theme_font_size_override("font_size", 16)
	UIStyle.apply_orange_action_button_style(challenge_btn)
	hbox.add_child(challenge_btn)

	challenge_btn.pressed.connect( func():
		var idx: = int(parent_panel.get_meta("fe_diff_idx", 0))
		await _on_challenge(element, game_manager, parent_panel, idx, challenge_btn)
	)

	var yuanbao_btn: = Button.new()
	yuanbao_btn.name = "yuanbao_btn_%s" % element
	yuanbao_btn.text = "💎 元宝挑战"
	yuanbao_btn.custom_minimum_size = Vector2(115, 40)
	yuanbao_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	yuanbao_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	yuanbao_btn.add_theme_font_size_override("font_size", 16)
	UIStyle.apply_golden_button_style(yuanbao_btn)
	hbox.add_child(yuanbao_btn)

	yuanbao_btn.pressed.connect( func():
		var idx: = int(parent_panel.get_meta("fe_diff_idx", 0))
		await _on_yuanbao_challenge(element, game_manager, parent_panel, idx, yuanbao_btn)
	)
	parent_panel.set_meta("fe_yuanbao_btn_%s" % element, yuanbao_btn)
	parent_panel.set_meta("challenge_btn_%s" % element, challenge_btn)

	return card

static func _apply_fe_diff_chip_styles(parent_panel: Control) -> void :
	if parent_panel == null or not is_instance_valid(parent_panel):
		return
	var selected: = int(parent_panel.get_meta("fe_diff_idx", 0))
	var btns = parent_panel.get_meta("fe_diff_btns", [])
	if not (btns is Array):
		return
	for i in range(btns.size()):
		var b = btns[i]
		if b is Button and is_instance_valid(b):
			UIStyle.apply_tab_style(b, i == selected)

static func _load_element_icon(element: String) -> Texture2D:
	var path: = str(ELEMENT_ICON_PATHS.get(element, ""))
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		var loaded = load(path)
		if loaded is Texture2D:
			return loaded
	if not FileAccess.file_exists(path):
		return null
	var img: = Image.load_from_file(ProjectSettings.globalize_path(path))
	if img == null or img.is_empty():
		return null
	if img.get_width() > 96 or img.get_height() > 96:
		img.resize(96, 96, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(img)

static func _select_fe_difficulty(idx: int, parent_panel: Control) -> void :
	if parent_panel == null or not is_instance_valid(parent_panel):
		return
	if idx < 0 or idx >= DIFFICULTIES.size():
		idx = 0
	parent_panel.set_meta("fe_diff_idx", idx)
	_apply_fe_diff_chip_styles(parent_panel)
	var gm = parent_panel.get_meta("fe_game_manager", null)
	_refresh_all_fe_level_labels(gm, parent_panel)

static func _fe_drop_summary_text(game_manager) -> String:
	if game_manager == null or not game_manager.has_method("get_fe_dungeon_runtime_config"):
		return "加载中..."
	var cfg: Dictionary = game_manager.get_fe_dungeon_runtime_config()
	if cfg.is_empty():
		return "登录后同步服务端掉落表"

	var desc: = str(cfg.get("descriptionText", "")).strip_edges()
	if not desc.is_empty():
		return desc
	var rewards = cfg.get("rewards", {})
	var name_set: = {}
	if rewards is Dictionary:
		for key in ["simple", "normal", "hard"]:
			var list = rewards.get(key, [])
			if list is Array:
				for entry in list:
					if entry is Dictionary:
						var n: = str(entry.get("name", "")).strip_edges()
						if not n.is_empty():
							name_set[n] = true
	var names: Array = name_set.keys()
	names.sort()
	if names.is_empty():
		return "暂无掉落配置"
	return "、".join(PackedStringArray(names.map( func(n): return str(n))))

static func _refresh_fe_drop_summary(game_manager, parent_panel: Control) -> void :
	var label: Label = parent_panel.get_meta("fe_drop_summary_label", null)
	if label and is_instance_valid(label):
		label.text = _fe_drop_summary_text(game_manager)

static func _update_difficulty_info(label: Label, diff_idx: int, game_manager = null) -> void :
	var diff_name: = DIFFICULTIES[0]
	if diff_idx >= 0 and diff_idx < DIFFICULTIES.size():
		diff_name = DIFFICULTIES[diff_idx]
	if game_manager != null and game_manager.has_method("get_fe_wave_display_text"):
		label.text = game_manager.get_fe_wave_display_text(diff_name)
	else:
		label.text = "500-1200级（3波×5只）"

static func _refresh_all_fe_level_labels(game_manager, parent_panel: Control) -> void :
	if parent_panel == null or not is_instance_valid(parent_panel):
		return
	var gm = game_manager
	if gm == null:
		gm = parent_panel.get_meta("fe_game_manager", null)
	var diff_idx: = int(parent_panel.get_meta("fe_diff_idx", 0))
	for element in FIVE_ELEMENTS:
		var level_label: Label = parent_panel.get_meta("fe_level_label_%s" % element, null)
		if level_label == null or not is_instance_valid(level_label):
			var found: = parent_panel.find_child("level_label_%s" % element, true, false)
			if found is Label:
				level_label = found
				parent_panel.set_meta("fe_level_label_%s" % element, level_label)
		if level_label and is_instance_valid(level_label):
			_update_difficulty_info(level_label, diff_idx, gm)

static func _on_fe_runtime_config_loaded(config: Dictionary) -> void :
	var gm = _active_game_manager
	var panel = _active_parent_panel
	if gm and gm.has_method("_on_gameplay_runtime_config_loaded"):
		gm._on_gameplay_runtime_config_loaded(config)
	if panel == null or not is_instance_valid(panel) or gm == null:
		_request_fe_dungeon_status(gm)
		return
	_refresh_all_fe_level_labels(gm, panel)
	_refresh_fe_drop_summary(gm, panel)
	_request_fe_dungeon_status(gm)
	_refresh_active_fe_panel()

static var _pending_fe: Dictionary = {}
static var _fe_start_in_progress: bool = false
static var _status_ready: bool = false
static var _status_failed: bool = false
static var _status_cache: Dictionary = {}
static var _active_parent_panel: Control = null
static var _active_game_manager = null
static var _global_hooks_ready: bool = false
static var _status_sync_waiting: bool = false
static var _status_sync_generation: int = 0
static var _status_sync_resolved_generation: int = 0
static var _status_sync_resolved_ok: bool = false
static var _status_sync_last_yuanbao_remaining: int = -1

static func _invalidate_fe_yuanbao_status_cache() -> void :
	_status_cache.erase("yuanbaoRemaining")
	_status_cache.erase("yuanbaoMaxAttempts")
	_status_sync_last_yuanbao_remaining = -1

static func _invalidate_fe_status_cache_for_refresh() -> void :
	_status_cache.clear()
	_status_ready = false
	_status_failed = false
	_status_sync_last_yuanbao_remaining = -1

static func _mark_fe_status_sync_resolved(ok: bool, was_waiting: bool, data: Dictionary = {}) -> void :
	if not was_waiting:
		return
	_status_sync_resolved_generation = _status_sync_generation
	_status_sync_resolved_ok = ok
	if ok and data is Dictionary and data.has("yuanbaoRemaining"):
		_status_sync_last_yuanbao_remaining = int(data.get("yuanbaoRemaining", 0))
	else:
		_status_sync_last_yuanbao_remaining = -1

static func _fe_dungeon_enabled(game_manager) -> bool:
	if game_manager == null or not game_manager.has_method("get_fe_dungeon_runtime_config"):
		return false
	var cfg: Dictionary = game_manager.get_fe_dungeon_runtime_config()
	if cfg.is_empty():
		return false
	return bool(cfg.get("enabled", false))

static func _fe_cfg_int(game_manager, key: String, fallback: int) -> int:
	if game_manager == null:
		return fallback
	var cfg: Dictionary = game_manager.get_fe_dungeon_runtime_config()
	return int(cfg.get(key, fallback)) if not cfg.is_empty() else fallback

static func _fe_cultivation_threshold(game_manager) -> int:
	return _fe_cfg_int(game_manager, "cultivationThreshold", CULTIVATION_THRESHOLD)

static func _fe_is_logged_in(game_manager) -> bool:
	return game_manager != null and game_manager.network != null and game_manager.network.is_logged_in()

static func refresh_panel(game_manager, parent_panel: Control) -> void :
	if game_manager == null or parent_panel == null:
		return
	_active_game_manager = game_manager
	_active_parent_panel = parent_panel
	parent_panel.set_meta("fe_game_manager", game_manager)
	_invalidate_fe_status_cache_for_refresh()
	_ensure_fe_status_hooks(game_manager, parent_panel)
	_refresh_yuanbao_buttons(game_manager, parent_panel)
	_refresh_all_fe_level_labels(game_manager, parent_panel)
	_refresh_fe_drop_summary(game_manager, parent_panel)

static func _update_status_cache_from_data(data: Dictionary) -> void :
	if data.is_empty():
		return
	if data.has("remainingAttempts"):
		_status_cache["remainingAttempts"] = int(data.get("remainingAttempts", 0))
	if data.has("yuanbaoRemaining"):
		_status_cache["yuanbaoRemaining"] = int(data.get("yuanbaoRemaining", 0))
	if data.has("maxAttempts"):
		_status_cache["maxAttempts"] = int(data.get("maxAttempts", 0))
	if data.has("yuanbaoMaxAttempts"):
		_status_cache["yuanbaoMaxAttempts"] = int(data.get("yuanbaoMaxAttempts", 0))

static func _fe_free_remaining_count() -> int:
	if not _status_ready or not _status_cache.has("remainingAttempts"):
		return -1
	return int(_status_cache.get("remainingAttempts", 0))

static func _fe_yuanbao_remaining_count() -> int:
	if not _status_cache.has("yuanbaoRemaining"):
		return -1
	return int(_status_cache.get("yuanbaoRemaining", 0))

static func _sync_player_fe_yuanbao_from_cache(game_manager) -> void :
	if game_manager == null or game_manager.player == null:
		return
	if not _status_cache.has("yuanbaoRemaining"):
		return
	var max_yb: = int(_status_cache.get("yuanbaoMaxAttempts", _fe_cfg_int(game_manager, "yuanbaoDailyMax", MAX_YUANBAO_ATTEMPTS)))
	var yb_rem: = maxi(0, int(_status_cache.get("yuanbaoRemaining", max_yb)))
	game_manager.player.fe_yuanbao_attempts = clampi(max_yb - yb_rem, 0, max_yb)
	game_manager.player.fe_yuanbao_attempts_date = Time.get_date_string_from_system()

static func _apply_status_cache_to_panel(parent_panel: Control, game_manager) -> void :
	if parent_panel == null or not is_instance_valid(parent_panel) or game_manager == null:
		return
	if not _status_cache.has("remainingAttempts"):
		return
	var rem: = int(_status_cache.get("remainingAttempts", 0))
	var max_free: = int(_status_cache.get("maxAttempts", _fe_cfg_int(game_manager, "dailyMax", 5)))
	var max_yb: = int(_status_cache.get("yuanbaoMaxAttempts", _fe_cfg_int(game_manager, "yuanbaoDailyMax", MAX_YUANBAO_ATTEMPTS)))
	parent_panel.set_meta("fe_remaining_attempts", rem)
	var yuanbao_rem: = -1
	if _status_cache.has("yuanbaoRemaining"):
		yuanbao_rem = int(_status_cache.get("yuanbaoRemaining", 0))
		parent_panel.set_meta("fe_yuanbao_remaining", yuanbao_rem)
	else:
		yuanbao_rem = int(parent_panel.get_meta("fe_yuanbao_remaining", -1))
	var label: Label = parent_panel.get_meta("fe_attempts_label", null)
	if label and is_instance_valid(label):
		if yuanbao_rem >= 0:
			label.text = "今日剩余: %d/%d次  元宝: %d/%d次" % [rem, max_free, yuanbao_rem, max_yb]
		else:
			label.text = "今日剩余: %d/%d次  元宝: 同步中…" % [rem, max_free]
	_sync_player_fe_yuanbao_from_cache(game_manager)
	_refresh_yuanbao_buttons(game_manager, parent_panel)

static func _refresh_active_fe_panel() -> void :
	if _active_game_manager == null or _active_parent_panel == null:
		return
	if not is_instance_valid(_active_parent_panel):
		return
	if _status_ready and _status_cache.has("remainingAttempts"):
		_apply_status_cache_to_panel(_active_parent_panel, _active_game_manager)
	elif _status_failed:
		var label: Label = _active_parent_panel.get_meta("fe_attempts_label", null)
		if label and is_instance_valid(label):
			var max_free: = _fe_cfg_int(_active_game_manager, "dailyMax", 5)
			var max_yb: = _fe_cfg_int(_active_game_manager, "yuanbaoDailyMax", MAX_YUANBAO_ATTEMPTS)
			label.text = "今日剩余: --/%d次  元宝: --/%d次" % [max_free, max_yb]
		_refresh_yuanbao_buttons(_active_game_manager, _active_parent_panel)
	else:
		_refresh_fe_attempts_pending(_active_game_manager, _active_parent_panel)

static func _ensure_fe_status_hooks(game_manager, parent_panel: Control) -> void :
	if game_manager == null:
		return
	_active_game_manager = game_manager
	if parent_panel and is_instance_valid(parent_panel):
		_active_parent_panel = parent_panel
		parent_panel.set_meta("fe_game_manager", game_manager)
	_refresh_fe_attempts_pending(game_manager, parent_panel)
	if not _fe_is_logged_in(game_manager):
		_refresh_yuanbao_buttons(game_manager, parent_panel)
		return
	if game_manager.network == null:
		return
	if _global_hooks_ready:
		_request_fe_dungeon_status(game_manager)
		return
	_global_hooks_ready = true
	var net = game_manager.network
	net.fe_dungeon_status_loaded.connect(_on_fe_status)
	net.fe_dungeon_status_failed.connect(_on_fe_status_failed)
	if game_manager.has_signal("five_elements_dungeon_battle_ended"):
		game_manager.five_elements_dungeon_battle_ended.connect(_on_fe_battle_ended_refresh)
	if game_manager.has_signal("cultivation_changed"):
		game_manager.cultivation_changed.connect(_on_fe_cultivation_changed)
	if net.has_signal("gameplay_runtime_config_loaded"):
		net.gameplay_runtime_config_loaded.connect(_on_fe_runtime_config_loaded)
	_request_fe_dungeon_status(game_manager)

static func _on_fe_cultivation_changed(_amount: int) -> void :
	var gm = _active_game_manager
	var panel = _active_parent_panel
	if panel == null or not is_instance_valid(panel) or gm == null:
		return
	_refresh_cultivation_label(panel, gm)
	_refresh_yuanbao_buttons(gm, panel)

static func _on_fe_battle_ended_refresh(_victory: bool) -> void :
	var gm = _active_game_manager
	var panel = _active_parent_panel
	if panel and is_instance_valid(panel) and gm:
		_refresh_cultivation_label(panel, gm)
		if _status_ready and _status_cache.has("remainingAttempts"):
			_apply_status_cache_to_panel(panel, gm)
		else:
			_refresh_yuanbao_buttons(gm, panel)
	_request_fe_dungeon_status(gm)

static func _request_fe_dungeon_status(game_manager) -> void :
	if game_manager == null or game_manager.network == null:
		return
	if game_manager.network.is_logged_in():
		game_manager.network.get_fe_dungeon_status()

static func _await_fe_dungeon_status_sync(game_manager, timeout_ms: int = 6000) -> bool:
	if game_manager == null or game_manager.network == null:
		return false
	if not game_manager.network.is_logged_in():
		return false
	var tree: SceneTree = game_manager.get_tree()
	var target_gen: = _status_sync_generation + 1
	_status_sync_generation = target_gen
	_status_sync_resolved_generation = 0
	_status_sync_resolved_ok = false
	_status_sync_last_yuanbao_remaining = -1
	if tree == null:
		_request_fe_dungeon_status(game_manager)
		return _status_sync_resolved_generation == target_gen and _status_sync_resolved_ok and _status_sync_last_yuanbao_remaining >= 0
	_status_sync_waiting = true
	_request_fe_dungeon_status(game_manager)
	var deadline: = Time.get_ticks_msec() + timeout_ms
	while _status_sync_waiting and Time.get_ticks_msec() < deadline:
		await tree.process_frame
	return _status_sync_resolved_generation == target_gen and _status_sync_resolved_ok and _status_sync_last_yuanbao_remaining >= 0

static func _refresh_fe_attempts_pending(game_manager, parent_panel: Control) -> void :
	if parent_panel == null or not is_instance_valid(parent_panel):
		return
	var label: Label = parent_panel.get_meta("fe_attempts_label", null)
	if not _fe_is_logged_in(game_manager):
		if label and is_instance_valid(label):
			label.text = "请先登录后再挑战五行副本"
		if game_manager:
			_refresh_yuanbao_buttons(game_manager, parent_panel)
		return
	if _status_ready and _status_cache.has("remainingAttempts"):
		_apply_status_cache_to_panel(parent_panel, game_manager)
		return
	if label == null or not is_instance_valid(label):
		return
	var max_free: = _fe_cfg_int(game_manager, "dailyMax", 5)
	var max_yb: = _fe_cfg_int(game_manager, "yuanbaoDailyMax", MAX_YUANBAO_ATTEMPTS)
	label.text = "今日剩余: 同步中…  免费上限%d次  元宝上限%d次" % [max_free, max_yb]
	if game_manager:
		_refresh_yuanbao_buttons(game_manager, parent_panel)

static func _fe_cultivation_cost(game_manager) -> int:
	return _fe_cfg_int(game_manager, "cultivationCost", CULTIVATION_COST)

static func _try_arm_fe_start(game_manager, parent_panel: Control) -> bool:
	if _fe_start_in_progress:
		return false
	_fe_start_in_progress = true
	_set_all_fe_buttons_syncing(game_manager, parent_panel, true)
	return true

static func _release_fe_start(game_manager, parent_panel: Control) -> void :
	_fe_start_in_progress = false
	_set_all_fe_buttons_syncing(game_manager, parent_panel, false)

static func _fe_instanced_block_message(game_manager) -> String:
	if game_manager == null:
		return ""
	if game_manager.has_method("get_instanced_challenge_block_message"):
		return str(game_manager.get_instanced_challenge_block_message(""))
	if game_manager.has_method("is_in_instanced_challenge") and game_manager.is_in_instanced_challenge():
		return "其他挑战正在进行中，请先完成或停止当前挑战后再试"
	return ""

static func _queue_fe_after_field_battle(element: String, diff_name: String, game_manager, parent_panel: Control, btn: Button, is_yuanbao: bool) -> void :
	_show_alert(parent_panel, "当前野外战斗进行中，请等待战斗结束后再挑战五行副本")
	_pending_fe = {
		"element": element, 
		"difficulty": diff_name, 
		"game_manager": game_manager, 
		"parent_panel": parent_panel, 
		"btn": btn, 
		"is_yuanbao": is_yuanbao, 
	}
	if game_manager.battle_system and not game_manager.battle_system.battle_ended.is_connected(_on_pending_battle_ended):
		game_manager.battle_system.battle_ended.connect(_on_pending_battle_ended)

static func _on_yuanbao_challenge(element: String, game_manager, parent_panel: Control, diff_idx: int, btn: Button = null) -> void :
	if _fe_start_in_progress:
		return
	if not _fe_is_logged_in(game_manager):
		_show_alert(parent_panel, "请先登录后再挑战五行副本")
		return
	var block_msg: = _fe_instanced_block_message(game_manager)
	if not block_msg.is_empty():
		_show_alert(parent_panel, block_msg)
		return
	if not _fe_dungeon_enabled(game_manager):
		_show_alert(parent_panel, "五行副本维护中")
		return
	var threshold: = _fe_cultivation_threshold(game_manager)
	if game_manager.player.cultivation < threshold:
		_show_alert(parent_panel, "修行值不足，需达到%s修行值" % _format_number(threshold))
		return
	if not _try_arm_fe_start(game_manager, parent_panel):
		return
	if not await _await_fe_dungeon_status_sync(game_manager):
		_release_fe_start(game_manager, parent_panel)
		if _status_failed:
			_show_alert(parent_panel, "五行副本服务未就绪，请稍后重试")
		else:
			_show_alert(parent_panel, "正在同步元宝挑战次数，请稍后再试")
		return
	if parent_panel and is_instance_valid(parent_panel):
		_apply_status_cache_to_panel(parent_panel, game_manager)
	var yb_rem: = _status_sync_last_yuanbao_remaining
	if yb_rem < 0:
		_release_fe_start(game_manager, parent_panel)
		_show_alert(parent_panel, "正在同步元宝挑战次数，请稍后再试")
		return
	if yb_rem == 0:
		_release_fe_start(game_manager, parent_panel)
		_show_alert(parent_panel, "今日元宝挑战次数已用完")
		return
	var yb_cost: = _fe_cfg_int(game_manager, "yuanbaoCost", YUANBAO_COST)
	if game_manager.player.yuanbao_currency < yb_cost:
		_release_fe_start(game_manager, parent_panel)
		_show_alert(parent_panel, "元宝不足，需要%d元宝" % yb_cost)
		return

	var diff_name: String = "简单"
	if diff_idx >= 0 and diff_idx < DIFFICULTIES.size():
		diff_name = DIFFICULTIES[diff_idx]

	if game_manager.has_method("prepare_for_instanced_challenge_async"):
		await game_manager.prepare_for_instanced_challenge_async()
	elif game_manager.has_method("prepare_for_instanced_challenge"):
		game_manager.prepare_for_instanced_challenge()

	await _do_start_fe(element, diff_name, game_manager, parent_panel, btn, true)

static func _on_challenge(element: String, game_manager, parent_panel: Control, diff_idx: int, btn: Button = null) -> void :
	if _fe_start_in_progress:
		return
	if not _fe_is_logged_in(game_manager):
		_show_alert(parent_panel, "请先登录后再挑战五行副本")
		return
	var block_msg: = _fe_instanced_block_message(game_manager)
	if not block_msg.is_empty():
		_show_alert(parent_panel, block_msg)
		return
	if not _fe_dungeon_enabled(game_manager):
		_show_alert(parent_panel, "五行副本维护中")
		return
	if not _status_ready:
		if _status_failed:
			_show_alert(parent_panel, "五行副本服务未就绪，请稍后重试")
		else:
			_show_alert(parent_panel, "正在同步五行副本次数，请稍后再试")
		return
	var threshold: = _fe_cultivation_threshold(game_manager)
	if game_manager.player.cultivation < threshold:
		_show_alert(parent_panel, "修行值不足，需达到%s修行值" % _format_number(threshold))
		return
	if parent_panel and is_instance_valid(parent_panel):
		_apply_status_cache_to_panel(parent_panel, game_manager)
	var rem: = _fe_free_remaining_count()
	if rem < 0:
		_show_alert(parent_panel, "次数尚未同步，请稍后再试")
		return
	if rem <= 0:
		_show_alert(parent_panel, "今日次数已用完")
		return
	if not _try_arm_fe_start(game_manager, parent_panel):
		return

	var diff_name: String = "简单"
	if diff_idx >= 0 and diff_idx < DIFFICULTIES.size():
		diff_name = DIFFICULTIES[diff_idx]

	if game_manager.has_method("prepare_for_instanced_challenge_async"):
		await game_manager.prepare_for_instanced_challenge_async()
	elif game_manager.has_method("prepare_for_instanced_challenge"):
		game_manager.prepare_for_instanced_challenge()

	await _do_start_fe(element, diff_name, game_manager, parent_panel, btn)

static func _make_fe_start_op_id(element: String) -> String:
	return "fe_start_%s_%d_%d" % [element, Time.get_ticks_msec(), randi()]

static func _request_fe_start(game_manager, element: String, diff_name: String, is_yuanbao: bool, op_id: String) -> Dictionary:
	return await game_manager.wait_economy("fe_dungeon_start", func():
		game_manager.network.start_fe_dungeon(element, diff_name, op_id, is_yuanbao)
	)

static func _should_retry_fe_start(data: Dictionary, already_retried: bool) -> bool:
	if already_retried:
		return false
	return not _is_valid_fe_start_response(data)

static func _fe_start_validation_error(data: Dictionary) -> String:
	if not bool(data.get("success", false)):
		return "服务端未返回成功状态"
	if not data.has("newCultivation"):
		return "服务端回包缺少修行值确认"
	if not data.has("remainingAttempts"):
		return "服务端回包缺少次数确认"
	if not data.has("sessionId") or str(data.get("sessionId", "")).strip_edges().is_empty():
		return "服务端回包缺少挑战会话"
	return ""

static func _is_valid_fe_start_response(data: Dictionary) -> bool:
	return _fe_start_validation_error(data).is_empty()

static func _fe_start_fail_message(data: Dictionary) -> String:
	var detail: = _fe_start_validation_error(data)
	if detail.is_empty():
		detail = "服务端回包格式异常"
	var server_err: = str(data.get("error", data.get("message", ""))).strip_edges()
	if not server_err.is_empty():
		return "无法进入五行副本：%s\n（%s）" % [detail, server_err]
	return "无法进入五行副本：%s\n请稍后重试或重新登录后再试" % detail

static func _do_start_fe(element: String, diff_name: String, game_manager, parent_panel: Control, btn: Button = null, is_yuanbao: bool = false) -> void :
	if not _fe_start_in_progress:
		if not _try_arm_fe_start(game_manager, parent_panel):
			return
	if game_manager == null:
		_release_fe_start(game_manager, parent_panel)
		return
	if game_manager.network == null or not game_manager.network.is_logged_in():
		_release_fe_start(game_manager, parent_panel)
		_show_alert(parent_panel, "请先登录后再挑战五行副本")
		return

	game_manager._suppress_general_cloud_upload_until_ms = maxi(
		game_manager._suppress_general_cloud_upload_until_ms, 
		Time.get_ticks_msec() + 120000
	)

	var op_id: = _make_fe_start_op_id(element)
	var er: Dictionary = await _request_fe_start(game_manager, element, diff_name, is_yuanbao, op_id)
	if not bool(er.get("ok", false)):
		_release_fe_start(game_manager, parent_panel)
		var fail_err: = str(er.get("err", "五行副本挑战失败"))
		if is_yuanbao and ("元宝" in fail_err or "次数" in fail_err):
			_request_fe_dungeon_status(game_manager)
		_show_alert(parent_panel, fail_err)
		return

	var data_var: Variant = er.get("data", {})
	if not (data_var is Dictionary):
		_release_fe_start(game_manager, parent_panel)
		_show_alert(parent_panel, "服务端返回异常，无法进入五行副本")
		return
	var data: Dictionary = data_var
	var fe_start_retried: = false
	if not _is_valid_fe_start_response(data):
		if _should_retry_fe_start(data, fe_start_retried):
			fe_start_retried = true
			er = await _request_fe_start(game_manager, element, diff_name, is_yuanbao, op_id)
			if not bool(er.get("ok", false)):
				_release_fe_start(game_manager, parent_panel)
				_show_alert(parent_panel, str(er.get("err", "五行副本挑战失败")))
				return
			data_var = er.get("data", {})
			if data_var is Dictionary:
				data = data_var
		if not _is_valid_fe_start_response(data):
			_release_fe_start(game_manager, parent_panel)
			print("[FiveElementsDungeonUI] start 回包校验失败 keys=%s" % str(data.keys()))
			_show_alert(parent_panel, _fe_start_fail_message(data))
			return

	if game_manager.has_method("sync_fe_dungeon_start_from_server"):
		game_manager.sync_fe_dungeon_start_from_server(data)
	_apply_fe_start_status_to_panel(parent_panel, data, game_manager)
	_status_ready = true
	_status_failed = false
	_refresh_cultivation_label(parent_panel, game_manager)
	_refresh_yuanbao_buttons(game_manager, parent_panel)

	var monsters = game_manager._create_five_elements_dungeon_monsters(element, diff_name)
	if monsters.size() == 0:
		_release_fe_start(game_manager, parent_panel)
		_show_alert(parent_panel, "怪物配置加载失败")
		return
	if not game_manager.start_five_elements_dungeon_battle(element, diff_name, monsters, is_yuanbao):
		_release_fe_start(game_manager, parent_panel)
		_show_alert(parent_panel, "无法开始战斗，请稍后重试")
		return

	_release_fe_start(game_manager, parent_panel)

static func _on_pending_battle_ended(_victory: bool) -> void :
	if _pending_fe.is_empty():
		return
	var gm = _pending_fe.get("game_manager")
	if gm == null:
		_pending_fe = {}
		return
	var tree = gm.get_tree()
	if tree == null:
		_pending_fe = {}
		return
	await tree.create_timer(0.5).timeout
	if _pending_fe.is_empty():
		return
	if gm == null or not is_instance_valid(gm):
		_pending_fe = {}
		return
	if gm.in_battle:
		if gm.battle_system and not gm.battle_system.battle_ended.is_connected(_on_pending_battle_ended):
			gm.battle_system.battle_ended.connect(_on_pending_battle_ended)
		return
	var inst_block: = _fe_instanced_block_message(gm)
	if not inst_block.is_empty():
		var abort_panel: Control = _pending_fe.get("parent_panel")
		_pending_fe = {}
		if gm.battle_system and gm.battle_system.battle_ended.is_connected(_on_pending_battle_ended):
			gm.battle_system.battle_ended.disconnect(_on_pending_battle_ended)
		_show_alert(abort_panel, inst_block)
		return
	var fe = _pending_fe
	_pending_fe = {}
	if gm.battle_system and gm.battle_system.battle_ended.is_connected(_on_pending_battle_ended):
		gm.battle_system.battle_ended.disconnect(_on_pending_battle_ended)
	await _do_start_fe(
		fe["element"], 
		fe["difficulty"], 
		gm, 
		fe.get("parent_panel"), 
		fe["btn"], 
		fe.get("is_yuanbao", false)
	)

static func _reset_btn(btn: Button, is_yuanbao: bool = false, parent_panel: Control = null, game_manager = null) -> void :
	if parent_panel and game_manager:
		_release_fe_start(game_manager, parent_panel)
		return
	if btn and is_instance_valid(btn):
		btn.disabled = false
		btn.text = "💎 元宝挑战" if is_yuanbao else "⚔️ 挑战"

static func _set_all_fe_buttons_syncing(game_manager, parent_panel: Control, syncing: bool) -> void :
	if parent_panel == null:
		return
	if syncing:
		for element in FIVE_ELEMENTS:
			var ch_btn: Button = parent_panel.get_meta("challenge_btn_%s" % element, null)
			var yb_btn: Button = parent_panel.get_meta("fe_yuanbao_btn_%s" % element, null)
			if ch_btn and is_instance_valid(ch_btn):
				ch_btn.disabled = true
				ch_btn.text = "⏳ 同步中..."
			if yb_btn and is_instance_valid(yb_btn):
				yb_btn.disabled = true
				yb_btn.text = "⏳ 同步中..."
	elif game_manager:
		_refresh_yuanbao_buttons(game_manager, parent_panel)

static func _estimate_alert_line_count(message: String, chars_per_line: int = 16) -> int:
	var max_lines: int = 1
	for segment in message.split("\n"):
		if segment.is_empty():
			max_lines = maxi(max_lines, 1)
		else:
			max_lines = maxi(max_lines, int(ceil(float(segment.length()) / float(chars_per_line))))
	return maxi(1, max_lines)

static func _show_alert(parent_control: Control, msg: String) -> void :
	_show_fe_window_alert(msg, "提示")

static func _show_fe_window_alert(message: String, title: String = "提示") -> void :
	var scene_root = Engine.get_main_loop().current_scene
	if not scene_root:
		push_warning("[FiveElements] %s" % message)
		return
	var popup: = Window.new()
	popup.title = ""
	var line_count: int = _estimate_alert_line_count(message)
	var content_height: int = maxi(80, line_count * 28)
	popup.size = Vector2i(420, 200 + content_height)
	popup.transparent = true
	popup.borderless = true
	popup.unresizable = true
	popup.close_requested.connect( func(): popup.queue_free())

	var main_panel: = Panel.new()
	main_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_panel.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	popup.add_child(main_panel)

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

	var content_label: = Label.new()
	content_label.text = message
	content_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_label.add_theme_font_size_override("font_size", 18)
	content_label.add_theme_color_override("font_color", Color(0.894, 0.864, 0.803))
	content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(content_label)

	var ok_btn: = Button.new()
	ok_btn.text = "确定"
	UIStyle.style_popup_button(ok_btn, true)
	ok_btn.pressed.connect( func(): popup.queue_free())
	vbox.add_child(ok_btn)

	scene_root.add_child(popup)
	popup.popup_centered()

static func _refresh_yuanbao_buttons(game_manager, parent_panel: Control) -> void :
	var player = game_manager.player
	var not_logged_in: bool = not _fe_is_logged_in(game_manager)
	var yb_rem: = _fe_yuanbao_remaining_count()
	var exhausted: bool = yb_rem == 0
	var threshold: = _fe_cultivation_threshold(game_manager)
	var below_threshold: bool = player.cultivation < threshold
	var busy: bool = _fe_start_in_progress or game_manager.in_battle
	var service_blocked: bool = _status_failed or not _status_ready
	for element in FIVE_ELEMENTS:
		var btn: Button = parent_panel.get_meta("fe_yuanbao_btn_%s" % element, null)
		if btn == null or not is_instance_valid(btn):
			continue
		if not_logged_in:
			btn.disabled = true
			btn.text = "💎 请先登录"
		elif busy:
			btn.disabled = true
			if _fe_start_in_progress:
				btn.text = "⏳ 同步中..."
		elif service_blocked:
			btn.disabled = true
			btn.text = "💎 同步中…" if not _status_failed else "💎 服务未就绪"
		elif below_threshold:
			btn.disabled = true
			btn.text = "💎 修行不足"
		elif yb_rem < 0:
			btn.disabled = true
			btn.text = "💎 同步中…"
		elif exhausted:
			btn.disabled = true
			btn.text = "💎 次数已用完"
		else:
			btn.disabled = false
			btn.text = "💎 元宝挑战"
	_refresh_free_challenge_buttons(game_manager, parent_panel)

static func _refresh_free_challenge_buttons(game_manager, parent_panel: Control) -> void :
	if game_manager == null or parent_panel == null:
		return
	var not_logged_in: bool = not _fe_is_logged_in(game_manager)
	var rem: = _fe_free_remaining_count()
	var threshold: = _fe_cultivation_threshold(game_manager)
	var below_threshold: bool = game_manager.player.cultivation < threshold
	var busy: bool = _fe_start_in_progress or game_manager.in_battle
	var service_blocked: bool = _status_failed or not _status_ready
	for element in FIVE_ELEMENTS:
		var btn: Button = parent_panel.get_meta("challenge_btn_%s" % element, null)
		if btn == null or not is_instance_valid(btn):
			continue
		if not_logged_in:
			btn.disabled = true
			btn.text = "⚔️ 请先登录"
		elif busy:
			btn.disabled = true
			if _fe_start_in_progress:
				btn.text = "⏳ 同步中..."
		elif service_blocked:
			btn.disabled = true
			btn.text = "⚔️ 同步中…" if not _status_failed else "⚔️ 服务未就绪"
		elif below_threshold:
			btn.disabled = true
			btn.text = "⚔️ 修行不足"
		elif rem < 0:
			btn.disabled = true
			btn.text = "⚔️ 同步中…"
		elif rem <= 0:
			btn.disabled = true
			btn.text = "⚔️ 次数已用完"
		else:
			btn.disabled = false
			btn.text = "⚔️ 挑战"

static func _refresh_cultivation_label(parent_panel: Control, game_manager) -> void :
	if parent_panel == null or game_manager == null or game_manager.player == null:
		return
	var label: Label = parent_panel.get_meta("fe_cultivation_label", null)
	if label and is_instance_valid(label):
		label.text = "修行值: %s" % _format_number(game_manager.player.cultivation)

static func _apply_fe_start_status_to_panel(parent_panel: Control, data: Dictionary, game_manager) -> void :
	if data.is_empty():
		return
	_update_status_cache_from_data(data)
	_status_ready = true
	_status_failed = false
	if parent_panel == null or not is_instance_valid(parent_panel):
		_refresh_active_fe_panel()
		return
	_apply_status_cache_to_panel(parent_panel, game_manager)

static func _format_number(n: int) -> String:
	if n >= 100000000:
		return "%d亿" % (n / 100000000)
	elif n >= 10000:
		return "%d万" % (n / 10000)
	return str(n)

static func _on_fe_status(data: Dictionary) -> void :
	var was_waiting: = _status_sync_waiting
	_status_sync_waiting = false
	if data is Dictionary and bool(data.get("success", false)) and data.has("remainingAttempts"):
		_update_status_cache_from_data(data)
		_status_ready = true
		_status_failed = false
		_mark_fe_status_sync_resolved(data.has("yuanbaoRemaining"), was_waiting, data)
	else:
		_mark_fe_status_sync_resolved(false, was_waiting, {})
		if not _status_ready:
			_status_failed = true
		_refresh_active_fe_panel()
		return
	_refresh_active_fe_panel()

static func _on_fe_status_failed(_error: String) -> void :
	var was_waiting: = _status_sync_waiting
	_status_sync_waiting = false
	_mark_fe_status_sync_resolved(false, was_waiting, {})
	if not _status_ready:
		_status_failed = true
	if _status_ready and _status_cache.has("remainingAttempts"):
		_refresh_active_fe_panel()
		return
	var gm = _active_game_manager
	var panel = _active_parent_panel
	if panel == null or not is_instance_valid(panel):
		return
	var label: Label = panel.get_meta("fe_attempts_label", null)
	if label == null or not is_instance_valid(label):
		return
	var max_free: = _fe_cfg_int(gm, "dailyMax", 5)
	var max_yb: = _fe_cfg_int(gm, "yuanbaoDailyMax", MAX_YUANBAO_ATTEMPTS)
	label.text = "今日剩余: --/%d次  元宝: --/%d次" % [max_free, max_yb]
	if gm:
		_refresh_yuanbao_buttons(gm, panel)
