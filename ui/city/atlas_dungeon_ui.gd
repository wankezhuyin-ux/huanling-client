class_name AtlasDungeonUI
extends RefCounted

const UIStyle = preload("res://scripts/ui_style.gd")
const TouchScrollUtils = preload("res://scripts/ui/touch_scroll_utils.gd")

const TIER_ORDER: = ["basic", "medium", "advanced"]
const DEFAULT_TIERS: = {
	"basic": {"label": "初级", "entryCost": 100000000, "waveCount": 20, "dailyMax": 30}, 
	"medium": {"label": "中级", "entryCost": 500000000, "waveCount": 100, "dailyMax": 30}, 
	"advanced": {"label": "高级", "entryCost": 1000000000, "waveCount": 200, "dailyMax": 30}, 
}

const BUTTON_COOLDOWN_SEC: = 3

static var _start_in_progress: bool = false
static var _status_data: Dictionary = {}
static var _status_ready: bool = false
static var _status_failed: bool = false
static var _global_hooks_ready: bool = false
static var _active_game_manager = null
static var _active_parent_panel: Control = null

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
	vbox.add_theme_constant_override("separation", 14)
	margin_wrap.add_child(vbox)

	var title: = UIStyle.create_title_label("📖 图鉴副本")
	vbox.add_child(title)

	var info_panel: = Panel.new()
	info_panel.custom_minimum_size = Vector2(0, 72)
	info_panel.add_theme_stylebox_override("panel", UIStyle.create_item_style())
	vbox.add_child(info_panel)

	var info_hbox: = HBoxContainer.new()
	info_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	info_hbox.offset_left = 15
	info_hbox.offset_top = 8
	info_hbox.offset_right = -15
	info_hbox.offset_bottom = -8
	info_panel.add_child(info_hbox)

	var gold_label: = Label.new()
	gold_label.name = "atlas_gold_label"
	gold_label.text = "金币: %s" % _format_number(game_manager.player.gold if game_manager and game_manager.player else 0)
	gold_label.add_theme_font_size_override("font_size", 16)
	gold_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	gold_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_hbox.add_child(gold_label)

	var hint_right: = Label.new()
	hint_right.text = "击败怪物 10% 概率捕捉\n按成长阈值分流图鉴/宠物栏"
	hint_right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint_right.add_theme_font_size_override("font_size", 13)
	hint_right.add_theme_color_override("font_color", Color(0.734, 0.714, 0.657))
	info_hbox.add_child(hint_right)

	parent_panel.set_meta("atlas_gold_label", gold_label)
	parent_panel.set_meta("atlas_game_manager", game_manager)

	for tier in TIER_ORDER:
		vbox.add_child(_create_tier_card(tier, game_manager, parent_panel))

	var foot_hint: = Label.new()
	foot_hint.text = "💡 需联网挑战，服务端扣金币；战败或中途停止不退费；各难度每日最多30次。"
	foot_hint.add_theme_font_size_override("font_size", 14)
	foot_hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	foot_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(foot_hint)

	_ensure_status_hooks(game_manager, parent_panel)
	refresh_panel_and_sync(game_manager, parent_panel)
	if game_manager and game_manager.network and game_manager.network.has_method("fetch_gameplay_runtime_config"):
		if game_manager.get_atlas_dungeon_runtime_config().is_empty():
			game_manager.network.fetch_gameplay_runtime_config()

	TouchScrollUtils.enable_touch_drag_passthrough(vbox)
	return scroll

static func refresh_panel(game_manager, parent_panel: Control) -> void :
	if game_manager == null or parent_panel == null or not is_instance_valid(parent_panel):
		return
	_active_game_manager = game_manager
	_active_parent_panel = parent_panel
	_ensure_status_hooks(game_manager, parent_panel)
	_update_panel_labels(game_manager, parent_panel)

static func refresh_panel_and_sync(game_manager, parent_panel: Control) -> void :
	refresh_panel(game_manager, parent_panel)
	_request_atlas_dungeon_status(game_manager)

static func _update_panel_labels(game_manager, parent_panel: Control) -> void :
	if game_manager == null or parent_panel == null or not is_instance_valid(parent_panel):
		return
	var gold_label: Label = parent_panel.get_meta("atlas_gold_label", null)
	if gold_label and is_instance_valid(gold_label) and game_manager.player:
		gold_label.text = "金币: %s" % _format_number(game_manager.player.gold)
	for tier in TIER_ORDER:
		var rem_label: Label = parent_panel.get_meta("atlas_remaining_%s" % tier, null)
		if rem_label and is_instance_valid(rem_label):
			rem_label.text = _remaining_text(tier)

static func _create_tier_card(tier: String, game_manager, parent_panel: Control) -> Control:
	var tier_cfg: = _tier_cfg(game_manager, tier)
	var label: = str(tier_cfg.get("label", tier))
	var entry_cost: = int(tier_cfg.get("entryCost", DEFAULT_TIERS.get(tier, {}).get("entryCost", 0)))
	var wave_count: = int(tier_cfg.get("waveCount", DEFAULT_TIERS.get(tier, {}).get("waveCount", 20)))

	var card: = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var card_style: = UIStyle.create_item_style()
	card_style.content_margin_left = 14
	card_style.content_margin_right = 14
	card_style.content_margin_top = 10
	card_style.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", card_style)

	var hbox: = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(hbox)

	var info_vbox: = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 4)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	var name_label: = Label.new()
	name_label.text = "%s图鉴副本" % label
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
	info_vbox.add_child(name_label)

	var detail_label: = Label.new()
	detail_label.text = "消耗 %s 金币 · %d 波 · 每波5只100级怪" % [_format_number(entry_cost), wave_count]
	detail_label.add_theme_font_size_override("font_size", 14)
	detail_label.add_theme_color_override("font_color", Color(0.734, 0.714, 0.657))
	info_vbox.add_child(detail_label)

	var rem_label: = Label.new()
	rem_label.name = "remaining_%s" % tier
	rem_label.text = _remaining_text(tier)
	rem_label.add_theme_font_size_override("font_size", 13)
	rem_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	info_vbox.add_child(rem_label)
	parent_panel.set_meta("atlas_remaining_%s" % tier, rem_label)

	var btn: = Button.new()
	btn.text = "⚔️ 挑战"
	btn.set_meta("base_text", "⚔️ 挑战")
	btn.custom_minimum_size = Vector2(100, 38)
	UIStyle.apply_button_style(btn)
	btn.pressed.connect( func():
		await _on_challenge(tier, game_manager, parent_panel, btn)
	)
	hbox.add_child(btn)
	parent_panel.set_meta("atlas_btn_%s" % tier, btn)

	return card

static func _on_challenge(tier: String, game_manager, parent_panel: Control, btn: Button) -> void :
	if _start_in_progress:
		return
	if btn and is_instance_valid(btn) and btn.disabled:
		return
	_arm_button_cooldown(btn)
	if game_manager == null or game_manager.player == null:
		_show_alert(parent_panel, "游戏未初始化")
		return
	if game_manager.network == null or not game_manager.network.is_logged_in():
		_show_alert(parent_panel, "请先登录后再挑战图鉴副本")
		return
	if game_manager.pet_manager == null or game_manager.pet_manager.get_active_pet() == null:
		_show_alert(parent_panel, "请先设置出战宠物")
		return
	if game_manager.has_method("prepare_for_instanced_challenge_async"):
		await game_manager.prepare_for_instanced_challenge_async()
	elif game_manager.has_method("prepare_for_instanced_challenge"):
		game_manager.prepare_for_instanced_challenge()
	var block_msg: = ""
	if game_manager.has_method("get_instanced_challenge_block_message"):
		block_msg = str(game_manager.get_instanced_challenge_block_message(""))
	elif game_manager.has_method("is_in_instanced_challenge") and game_manager.is_in_instanced_challenge():
		block_msg = "其他挑战正在进行中，请先完成或停止当前挑战后再试"
	if not block_msg.is_empty():
		_show_alert(parent_panel, block_msg)
		return
	if not _status_ready:
		if _status_failed:
			_show_alert(parent_panel, "图鉴副本服务未就绪，请先部署并重启服务端后再试", "错误")
		else:
			_show_alert(parent_panel, "正在同步图鉴副本次数，请稍后再试")
		return

	var tier_cfg: = _tier_cfg(game_manager, tier)
	var entry_cost: = int(tier_cfg.get("entryCost", 0))
	if game_manager.player.gold < entry_cost:
		_show_alert(parent_panel, "金币不足，需要 %s 金币" % _format_number(entry_cost))
		return
	var remaining: = _remaining_count(tier)
	if remaining < 0:
		_show_alert(parent_panel, "次数尚未同步，请稍后再试")
		return
	if remaining <= 0:
		_show_alert(parent_panel, "今日该难度次数已用完")
		return

	_start_in_progress = true
	_set_all_atlas_buttons_syncing(parent_panel, true)
	if btn:
		btn.text = "请求中…"

	var er: Dictionary = await _request_atlas_start(game_manager, tier)
	if not bool(er.get("ok", false)):
		_reset_after_start_fail(parent_panel, btn)
		_show_alert(parent_panel, str(er.get("err", "图鉴副本挑战失败")), "错误")
		return

	var data_var: Variant = er.get("data", {})
	if not (data_var is Dictionary):
		_reset_after_start_fail(parent_panel, btn)
		_show_alert(parent_panel, "服务端返回异常，无法进入图鉴副本", "错误")
		return
	var data: Dictionary = data_var
	if not _is_valid_atlas_start_response(data, tier):
		if _should_retry_atlas_start(data):
			er = await _request_atlas_start(game_manager, tier)
			if not bool(er.get("ok", false)):
				_reset_after_start_fail(parent_panel, btn)
				_show_alert(parent_panel, str(er.get("err", "图鉴副本挑战失败")), "错误")
				return
			data_var = er.get("data", {})
			if data_var is Dictionary:
				data = data_var
		if not _is_valid_atlas_start_response(data, tier):
			_reset_after_start_fail(parent_panel, btn)
			print("[AtlasDungeonUI] start 回包校验失败 tier=%s keys=%s" % [tier, str(data.keys())])
			_show_alert(parent_panel, _atlas_start_fail_message(data, tier), "错误")
			return

	if game_manager.has_method("sync_atlas_dungeon_start_from_server"):
		game_manager.sync_atlas_dungeon_start_from_server(data)
	_apply_start_status(data, tier)

	refresh_panel(game_manager, parent_panel)

	var waves: Array = game_manager.create_atlas_dungeon_monsters(tier)
	if waves.is_empty():
		_reset_after_start_fail(parent_panel, btn)
		_show_alert(parent_panel, "怪物配置加载失败", "错误")
		return

	if not await game_manager.start_atlas_dungeon_battle(tier, waves):
		_reset_after_start_fail(parent_panel, btn)
		_show_alert(parent_panel, "无法开始战斗，请稍后重试", "错误")
		return

	_set_all_atlas_buttons_syncing(parent_panel, false)
	if btn and is_instance_valid(btn):
		btn.text = str(btn.get_meta("base_text", "⚔️ 挑战"))

static func _reset_after_start_fail(parent_panel: Control, btn: Button) -> void :
	_start_in_progress = false
	_set_all_atlas_buttons_syncing(parent_panel, false)
	_arm_button_cooldown(btn)

static func _arm_button_cooldown(button: Button) -> void :
	if button == null or not is_instance_valid(button):
		return
	_start_button_cooldown(button, str(button.get_meta("base_text", "⚔️ 挑战")))

static func _start_button_cooldown(button: Button, base_text: String, seconds: int = BUTTON_COOLDOWN_SEC) -> void :
	if button == null or not is_instance_valid(button):
		return
	button.disabled = true
	for remaining in range(seconds, 0, -1):
		if not is_instance_valid(button):
			return
		if _start_in_progress:
			return
		button.text = "%s(%ds)" % [base_text, remaining]
		await button.get_tree().create_timer(1.0).timeout
	if not is_instance_valid(button):
		return
	if _start_in_progress:
		return
	button.text = base_text
	button.disabled = false

static func _make_atlas_start_op_id(tier: String) -> String:
	return "atlas_start_%s_%d_%d" % [tier, Time.get_ticks_msec(), randi()]

static func _request_atlas_start(game_manager, tier: String) -> Dictionary:
	var op_id: = _make_atlas_start_op_id(tier)
	game_manager.current_atlas_dungeon_start_op_id = op_id
	return await game_manager.wait_economy("atlas_dungeon_start", func():
		game_manager.network.start_atlas_dungeon(tier, op_id)
	)

static func _should_retry_atlas_start(data: Dictionary) -> bool:
	return bool(data.get("duplicate", false)) and ( not data.has("newGold") or not data.has("remainingAttempts"))

static func _atlas_start_validation_error(data: Dictionary, tier: String) -> String:
	if not bool(data.get("success", false)):
		return "服务端未返回成功状态"
	if str(data.get("tier", "")).strip_edges() != tier:
		return "服务端难度不一致"
	if not data.has("newGold"):
		return "服务端回包缺少金币确认"
	if not data.has("remainingAttempts"):
		return "服务端回包缺少次数确认"
	return ""

static func _atlas_start_fail_message(data: Dictionary, tier: String) -> String:
	var detail: = _atlas_start_validation_error(data, tier)
	if detail.is_empty():
		detail = "服务端回包格式异常"
	var server_err: = str(data.get("error", data.get("message", ""))).strip_edges()
	if not server_err.is_empty():
		return "无法进入图鉴副本：%s\n（%s）" % [detail, server_err]
	return "无法进入图鉴副本：%s\n请稍后重试或重新登录后再试" % detail

static func _is_valid_atlas_start_response(data: Dictionary, tier: String) -> bool:
	return _atlas_start_validation_error(data, tier).is_empty()

static func _set_all_atlas_buttons_syncing(parent_panel: Control, syncing: bool) -> void :
	if parent_panel == null:
		return
	for tier in TIER_ORDER:
		var btn: Button = parent_panel.get_meta("atlas_btn_%s" % tier, null)
		if btn and is_instance_valid(btn):
			btn.disabled = syncing
			if not syncing:
				btn.text = str(btn.get_meta("base_text", "⚔️ 挑战"))

static func _apply_start_status(data: Dictionary, tier: String) -> void :
	if not _status_data.has("tiers") or not (_status_data.get("tiers") is Dictionary):
		_status_data["tiers"] = {}
	var tiers: Dictionary = _status_data["tiers"]
	if not tiers.has(tier) or not (tiers[tier] is Dictionary):
		tiers[tier] = {}
	var row: Dictionary = tiers[tier]
	if data.has("remainingAttempts"):
		row["remainingAttempts"] = int(data.get("remainingAttempts", 0))
	if data.has("maxAttempts"):
		row["maxAttempts"] = int(data.get("maxAttempts", 30))
	if data.has("usedAttempts"):
		row["usedAttempts"] = int(data.get("usedAttempts", 0))
	_status_ready = true
	_status_failed = false

static func _ensure_status_hooks(game_manager, parent_panel: Control) -> void :
	if game_manager == null:
		return
	_active_game_manager = game_manager
	if parent_panel and is_instance_valid(parent_panel):
		_active_parent_panel = parent_panel
	if _global_hooks_ready:
		return
	if game_manager.network == null:
		return
	_global_hooks_ready = true
	var net = game_manager.network
	if net.has_signal("atlas_dungeon_status_loaded"):
		net.atlas_dungeon_status_loaded.connect(_on_status_loaded)
	if net.has_signal("atlas_dungeon_status_failed"):
		net.atlas_dungeon_status_failed.connect(_on_status_failed)
	if net.has_signal("gameplay_runtime_config_loaded"):
		net.gameplay_runtime_config_loaded.connect(_on_runtime_config_loaded)
	if game_manager.has_signal("atlas_dungeon_battle_ended"):
		game_manager.atlas_dungeon_battle_ended.connect(_on_battle_ended_refresh)

static func _request_atlas_dungeon_status(game_manager) -> void :
	if game_manager == null or game_manager.network == null:
		return
	if game_manager.network.is_logged_in() and game_manager.network.has_method("get_atlas_dungeon_status"):
		game_manager.network.get_atlas_dungeon_status()

static func _refresh_active_panel() -> void :
	if _active_game_manager == null or _active_parent_panel == null:
		return
	if not is_instance_valid(_active_parent_panel):
		return
	_update_panel_labels(_active_game_manager, _active_parent_panel)

static func _on_status_loaded(data: Dictionary) -> void :
	if data is Dictionary and bool(data.get("success", false)) and data.get("tiers") is Dictionary:
		_status_data = data.duplicate(true)
		_status_ready = true
		_status_failed = false
	elif not _status_ready:
		_status_failed = true
	_refresh_active_panel()

static func _on_status_failed(_error: String) -> void :
	if not _status_ready:
		_status_failed = true
	_refresh_active_panel()

static func _on_runtime_config_loaded(_config: Dictionary) -> void :
	_refresh_active_panel()
	_request_atlas_dungeon_status(_active_game_manager)

static func _on_battle_ended_refresh(_victory: bool, _tier: String) -> void :
	_start_in_progress = false
	_request_atlas_dungeon_status(_active_game_manager)

static func _tier_cfg(game_manager, tier: String) -> Dictionary:
	if game_manager and game_manager.has_method("get_atlas_dungeon_tier_config"):
		var cfg: Dictionary = game_manager.get_atlas_dungeon_tier_config(tier)
		if not cfg.is_empty():
			return cfg
	var fallback: Variant = DEFAULT_TIERS.get(tier, {})
	return fallback if fallback is Dictionary else {}

static func _remaining_count(tier: String) -> int:
	if not _status_ready:
		return -1
	var tiers: Variant = _status_data.get("tiers", {})
	if tiers is Dictionary:
		var row: Variant = tiers.get(tier, {})
		if row is Dictionary and row.has("remainingAttempts"):
			return int(row.get("remainingAttempts", 0))
	return -1

static func _remaining_text(tier: String) -> String:
	if _status_failed:
		return "今日剩余: -- / -- 次（服务未就绪）"
	if not _status_ready:
		return "今日剩余: 同步中…"
	var rem: = _remaining_count(tier)
	var tier_cfg: Dictionary = {}
	var tier_cfg_var: Variant = DEFAULT_TIERS.get(tier, {})
	if tier_cfg_var is Dictionary:
		tier_cfg = tier_cfg_var
	var daily_max: = int(tier_cfg.get("dailyMax", 30))
	var tiers: Variant = _status_data.get("tiers", {})
	if tiers is Dictionary:
		var row: Variant = tiers.get(tier, {})
		if row is Dictionary and row.has("maxAttempts"):
			daily_max = int(row.get("maxAttempts", daily_max))
	return "今日剩余: %d / %d 次" % [rem, daily_max]

static func _format_number(n) -> String:
	var num: = int(n)
	if num >= 100000000:
		return "%.1f亿" % (float(num) / 100000000.0)
	if num >= 10000:
		return "%.1f万" % (float(num) / 10000.0)
	return str(num)

static func _find_existing_window_popup(popup_key: String) -> Window:
	var scene_root = Engine.get_main_loop().current_scene
	if not scene_root:
		return null
	for child in scene_root.get_children():
		if child is Window and str(child.get_meta("popup_key", "")) == popup_key:
			return child
	return null

static func _focus_existing_window_popup(popup_key: String) -> bool:
	var existing = _find_existing_window_popup(popup_key)
	if existing and is_instance_valid(existing):
		existing.show()
		existing.grab_focus()
		return true
	return false

static func _mark_popup_key(popup: Window, popup_key: String) -> void :
	if popup:
		popup.set_meta("popup_key", popup_key)

static func _show_alert(parent_control: Control, message: String, title: String = "提示") -> void :
	_show_game_alert(parent_control, message, title)


static func _estimate_alert_line_count(message: String, chars_per_line: int = 16) -> int:
	var max_lines: int = 1
	for segment in message.split("\n"):
		if segment.is_empty():
			max_lines = maxi(max_lines, 1)
		else:
			max_lines = maxi(max_lines, int(ceil(float(segment.length()) / float(chars_per_line))))
	return maxi(1, max_lines)

static func _show_game_alert(_parent_control: Control, message: String, title: String = "提示") -> void :
	var scene_root = Engine.get_main_loop().current_scene
	if not scene_root:
		push_warning("[AtlasDungeon] %s" % message)
		return
	var popup_key = "atlas_dungeon_alert:%s:%d:%d" % [title, Time.get_ticks_msec(), hash(message)]
	if _focus_existing_window_popup(popup_key):
		return

	var popup = Window.new()
	_mark_popup_key(popup, popup_key)
	popup.title = ""
	var line_count: int = _estimate_alert_line_count(message)
	var content_height: int = maxi(80, line_count * 28)
	var total_height = 200 + content_height
	popup.size = Vector2i(420, total_height)
	popup.transparent = true
	popup.borderless = true
	popup.unresizable = true
	popup.close_requested.connect( func(): popup.queue_free())

	var main_panel = Panel.new()
	main_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_panel.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	popup.add_child(main_panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 25
	vbox.offset_top = 25
	vbox.offset_right = -25
	vbox.offset_bottom = -25
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	main_panel.add_child(vbox)

	var title_label = Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(title_label)

	var content_label = Label.new()
	content_label.text = message
	content_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_label.add_theme_font_size_override("font_size", 18)
	content_label.add_theme_color_override("font_color", Color(0.894, 0.864, 0.803))
	content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(content_label)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	var ok_btn = Button.new()
	ok_btn.text = "确定"
	UIStyle.style_popup_button(ok_btn, true)
	ok_btn.pressed.connect( func(): popup.queue_free())
	vbox.add_child(ok_btn)

	scene_root.add_child(popup)
	popup.popup_centered()
