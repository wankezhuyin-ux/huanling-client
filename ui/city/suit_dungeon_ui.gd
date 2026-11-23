class_name SuitDungeonUI
extends RefCounted

const GameData = preload("res://scripts/game_data.gd")
const UIStyle = preload("res://scripts/ui_style.gd")
const SuitDatabaseDetailed = preload("res://scripts/data/suit_database_detailed.gd")
const TouchScrollUtils = preload("res://scripts/ui/touch_scroll_utils.gd")

const DUNGEON_COST = 500000

static func _suit_entry_cost(game_manager) -> int:
	if game_manager and game_manager.has_method("get_suit_dungeon_runtime_config"):
		var cfg: Dictionary = game_manager.get_suit_dungeon_runtime_config()
		if not cfg.is_empty():
			return int(cfg.get("entryCost", DUNGEON_COST))
	return DUNGEON_COST

static func _suit_client_deduct_entry(game_manager) -> bool:
	if game_manager and game_manager.has_method("get_suit_dungeon_runtime_config"):
		var cfg: Dictionary = game_manager.get_suit_dungeon_runtime_config()
		if not cfg.is_empty():
			return not bool(cfg.get("serverDeductEntryFee", false))
	return true

static func _refund_suit_entry(game_manager, amount: int, client_deduct: bool) -> void :
	if client_deduct and game_manager and game_manager.player:
		game_manager.player.gold += amount

static func _estimate_alert_line_count(message: String, chars_per_line: int = 16) -> int:
	var max_lines: int = 1
	for segment in message.split("\n"):
		if segment.is_empty():
			max_lines = maxi(max_lines, 1)
		else:
			max_lines = maxi(max_lines, int(ceil(float(segment.length()) / float(chars_per_line))))
	return maxi(1, max_lines)

static var _is_sweeping: bool = false
## 服务端下发的今日扫荡上限（含 VIP 加成）；0 表示还没拿到，文案就不带分母。
static var _sweep_cap: int = 0
const BUTTON_COOLDOWN_SEC: = 3

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

static func create_fullscreen(game_manager) -> Control:
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", UIStyle.create_panel_style())

	var vbox = UIStyle.create_base_vbox()
	panel.add_child(vbox)

	var title = UIStyle.create_title_label("🛡️ 套装副本")
	vbox.add_child(title)


	var info_panel = Panel.new()
	info_panel.custom_minimum_size = Vector2(0, 100)
	info_panel.add_theme_stylebox_override("panel", UIStyle.create_item_style())
	vbox.add_child(info_panel)

	var info_hbox = HBoxContainer.new()
	info_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	info_hbox.offset_left = 15
	info_hbox.offset_top = 10
	info_hbox.offset_right = -15
	info_hbox.offset_bottom = -10
	info_panel.add_child(info_hbox)


	var player_info = VBoxContainer.new()
	player_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_info.add_theme_constant_override("separation", 4)
	info_hbox.add_child(player_info)

	var player_name_label = Label.new()
	player_name_label.text = "玩家: %s" % game_manager.player.player_name
	player_name_label.add_theme_font_size_override("font_size", 16)
	player_name_label.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
	player_info.add_child(player_name_label)

	var player_cultivation_label = Label.new()
	player_cultivation_label.text = "修行值: %s" % _format_number(game_manager.player.cultivation)
	player_cultivation_label.add_theme_font_size_override("font_size", 14)
	player_cultivation_label.add_theme_color_override("font_color", Color(0.734, 0.714, 0.657))
	player_info.add_child(player_cultivation_label)

	var player_gold_label = Label.new()
	player_gold_label.text = "金币: %s" % _format_number(game_manager.player.gold)
	player_gold_label.add_theme_font_size_override("font_size", 14)
	player_gold_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	player_info.add_child(player_gold_label)


	var dungeon_info = VBoxContainer.new()
	dungeon_info.name = "dungeon_info"
	dungeon_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dungeon_info.add_theme_constant_override("separation", 4)
	info_hbox.add_child(dungeon_info)

	var highest_label = Label.new()
	highest_label.name = "suit_progress_label"
	highest_label.text = "当前进度: 第 %d 层" % game_manager.player.suit_dungeon_progress
	highest_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	highest_label.add_theme_font_size_override("font_size", 16)
	highest_label.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
	dungeon_info.add_child(highest_label)

	var cost_label = Label.new()
	cost_label.text = "挑战消耗: 50万金币"
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cost_label.add_theme_font_size_override("font_size", 14)
	cost_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.6))
	dungeon_info.add_child(cost_label)

	var sweep_label = Label.new()
	sweep_label.name = "sweep_label"
	sweep_label.text = _suit_sweep_label_text(int(game_manager.player.suit_dungeon_sweeps))
	sweep_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	sweep_label.add_theme_font_size_override("font_size", 14)
	sweep_label.add_theme_color_override("font_color", Color(0.6, 1, 0.6))
	dungeon_info.add_child(sweep_label)
	_bind_suit_dungeon_info_sync(game_manager, sweep_label)


	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	vbox.add_child(scroll)
	TouchScrollUtils.configure_scroll(scroll)

	var dungeon_container = VBoxContainer.new()
	dungeon_container.name = "suit_dungeon_levels"
	dungeon_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dungeon_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dungeon_container.add_theme_constant_override("separation", 10)
	scroll.add_child(dungeon_container)


	for level in range(1, 22):
		var dungeon_panel = _create_dungeon_panel(level, game_manager, panel)
		dungeon_container.add_child(dungeon_panel)
	TouchScrollUtils.enable_touch_drag_passthrough(dungeon_container)

	return panel

static func refresh_panel(game_manager, panel: Control) -> void :
	if game_manager == null or panel == null or not is_instance_valid(panel):
		return
	if game_manager.player == null:
		return
	# 服务端权威进度可能比本地旧存档高（换设备、回档、早期版本压根没落库）。
	# 客户端只增不减地跟上，否则通关过的层会被算成「未通关」，扫荡按钮出不来。
	var net = game_manager.network
	if net != null and int(net.suit_dungeon_server_progress) > int(game_manager.player.suit_dungeon_progress):
		game_manager.player.suit_dungeon_progress = int(net.suit_dungeon_server_progress)
	var progress_label: = panel.find_child("suit_progress_label", true, false) as Label
	if progress_label and is_instance_valid(progress_label):
		progress_label.text = "当前进度: 第 %d 层" % int(game_manager.player.suit_dungeon_progress)
	_refresh_sweep_display(panel, game_manager)
	# 次数按天重置：面板是缓存的，跨零点后本地那个「剩余 0 次」会一直卡着不让扫，
	# 所以每次刷新都重新问一遍服务端（GET，很轻）。
	var sweep_label: = panel.find_child("sweep_label", true, false) as Label
	if sweep_label and is_instance_valid(sweep_label):
		_bind_suit_dungeon_info_sync(game_manager, sweep_label)
	var levels_box: = panel.find_child("suit_dungeon_levels", true, false) as VBoxContainer
	if levels_box == null or not is_instance_valid(levels_box):
		return
	for child in levels_box.get_children():
		child.queue_free()
	for level in range(1, 22):
		levels_box.add_child(_create_dungeon_panel(level, game_manager, panel))
	TouchScrollUtils.enable_touch_drag_passthrough(levels_box)

static func create_content(game_manager, parent_panel: Control) -> Control:
	var vbox = UIStyle.create_base_vbox()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var title = UIStyle.create_title_label("🛡️ 套装副本")
	vbox.add_child(title)


	var info_panel = Panel.new()
	info_panel.custom_minimum_size = Vector2(0, 100)
	info_panel.add_theme_stylebox_override("panel", UIStyle.create_item_style())
	vbox.add_child(info_panel)

	var info_hbox = HBoxContainer.new()
	info_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	info_hbox.offset_left = 15
	info_hbox.offset_top = 10
	info_hbox.offset_right = -15
	info_hbox.offset_bottom = -10
	info_panel.add_child(info_hbox)

	var player_info = VBoxContainer.new()
	player_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_info.add_theme_constant_override("separation", 4)
	info_hbox.add_child(player_info)

	var player_name_label = Label.new()
	player_name_label.text = "玩家: %s" % game_manager.player.player_name
	player_name_label.add_theme_font_size_override("font_size", 16)
	player_name_label.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
	player_info.add_child(player_name_label)

	var player_cultivation_label = Label.new()
	player_cultivation_label.text = "修行值: %s" % _format_number(game_manager.player.cultivation)
	player_cultivation_label.add_theme_font_size_override("font_size", 14)
	player_cultivation_label.add_theme_color_override("font_color", Color(0.734, 0.714, 0.657))
	player_info.add_child(player_cultivation_label)

	var player_gold_label = Label.new()
	player_gold_label.text = "金币: %s" % _format_number(game_manager.player.gold)
	player_gold_label.add_theme_font_size_override("font_size", 14)
	player_gold_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	player_info.add_child(player_gold_label)

	var dungeon_info = VBoxContainer.new()
	dungeon_info.name = "dungeon_info"
	dungeon_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dungeon_info.add_theme_constant_override("separation", 4)
	info_hbox.add_child(dungeon_info)

	var highest_label = Label.new()
	highest_label.text = "当前进度: 第 %d 层" % game_manager.player.suit_dungeon_progress
	highest_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	highest_label.add_theme_font_size_override("font_size", 14)
	highest_label.add_theme_color_override("font_color", Color(0.734, 0.714, 0.657))
	dungeon_info.add_child(highest_label)

	var sweep_label = Label.new()
	sweep_label.name = "sweep_label"
	sweep_label.text = _suit_sweep_label_text(int(game_manager.player.suit_dungeon_sweeps))
	sweep_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	sweep_label.add_theme_font_size_override("font_size", 14)
	sweep_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	dungeon_info.add_child(sweep_label)
	_bind_suit_dungeon_info_sync(game_manager, sweep_label)

	var cost_label = Label.new()
	cost_label.text = "挑战消耗: 50万金币"
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cost_label.add_theme_font_size_override("font_size", 14)
	cost_label.add_theme_color_override("font_color", Color(0.734, 0.714, 0.657))
	dungeon_info.add_child(cost_label)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	TouchScrollUtils.configure_scroll(scroll)

	var dungeon_container = VBoxContainer.new()
	dungeon_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dungeon_container.add_theme_constant_override("separation", 10)
	scroll.add_child(dungeon_container)

	for level in range(1, 22):
		var dungeon_panel = _create_dungeon_panel(level, game_manager, parent_panel)
		dungeon_container.add_child(dungeon_panel)
	TouchScrollUtils.enable_touch_drag_passthrough(dungeon_container)

	return vbox

static func _create_dungeon_panel(level: int, game_manager, parent_control: Control) -> Panel:
	var suit_data = SuitDatabaseDetailed.get_suit_data(level)
	var required_cultivation = suit_data.get("required_cultivation", 0)
	var suit_name = suit_data.get("name", "未知套装")
	var element = suit_data.get("dungeon_element", "无")

	var can_challenge = game_manager.player.cultivation >= required_cultivation
	var is_unlocked = level <= game_manager.player.suit_dungeon_progress + 1
	var is_cleared = level <= game_manager.player.suit_dungeon_progress
	var is_current = is_unlocked and not is_cleared

	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(0, 100)

	var style = UIStyle.create_item_style()
	if is_cleared:
		style.bg_color = Color(0.1, 0.2, 0.15, 0.8)
		style.border_color = Color(0.3, 0.6, 0.4, 1)
	elif is_current:
		style.bg_color = Color(0.092, 0.076, 0.044, 0.92)
		style.border_color = Color(0.8, 0.6, 0.2, 1)
	else:
		style.bg_color = Color(0.048, 0.057, 0.059, 0.7)
		style.border_color = Color(0.655, 0.531, 0.245, 0.6)
	panel.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 15
	hbox.offset_top = 8
	hbox.offset_right = -15
	hbox.offset_bottom = -8
	panel.add_child(hbox)

	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(info_vbox)

	var title_hbox = HBoxContainer.new()
	title_hbox.add_theme_constant_override("separation", 10)
	info_vbox.add_child(title_hbox)

	var level_label = Label.new()
	if is_cleared:
		level_label.text = "✓ 第%d层" % level
		level_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.5))
	elif is_current:
		level_label.text = "⚔ 第%d层" % level
		level_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	else:
		level_label.text = "🔒 第%d层" % level
		level_label.add_theme_color_override("font_color", Color(0.631, 0.611, 0.564))
	level_label.add_theme_font_size_override("font_size", 16)
	title_hbox.add_child(level_label)

	var name_label = Label.new()
	name_label.text = suit_name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.4))
	title_hbox.add_child(name_label)

	var element_label = Label.new()
	element_label.text = "[%s]" % element
	element_label.add_theme_font_size_override("font_size", 16)
	element_label.add_theme_color_override("font_color", _get_element_color(element))
	title_hbox.add_child(element_label)

	var stats = suit_data.get("base_stats", {})
	var stats_label = Label.new()
	stats_label.text = "套装属性: 攻击%d 防御%d 生命%d 敏捷%d 内力%d" % [
		stats.get("attack", 0), 
		stats.get("defense", 0), 
		stats.get("hp", 0), 
		stats.get("agility", 0), 
		stats.get("mp", 0)
	]
	stats_label.add_theme_font_size_override("font_size", 12)
	stats_label.add_theme_color_override("font_color", Color(0.734, 0.714, 0.657))
	info_vbox.add_child(stats_label)

	var req_label = Label.new()
	req_label.text = "需要修行值: %s" % _format_number(required_cultivation)
	req_label.add_theme_font_size_override("font_size", 12)
	req_label.add_theme_color_override("font_color", Color(0.734, 0.714, 0.657))
	info_vbox.add_child(req_label)

	var btn_vbox = VBoxContainer.new()
	btn_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(btn_vbox)

	var net_ok: bool = game_manager.network != null and game_manager.network.is_logged_in()
	if is_cleared:
		var sweep_btn = Button.new()
		sweep_btn.text = "🔄 扫荡"
		sweep_btn.custom_minimum_size = Vector2(110, 48)
		sweep_btn.add_theme_font_size_override("font_size", 18)
		UIStyle.apply_button_style(sweep_btn)
		UIStyle.setup_button_animation(sweep_btn)
		sweep_btn.disabled = not net_ok
		if not net_ok:
			sweep_btn.tooltip_text = "请先登录后再扫荡套装副本"
		sweep_btn.set_meta("base_text", "🔄 扫荡")
		sweep_btn.pressed.connect( func(): await _on_sweep(level, game_manager, parent_control, sweep_btn))
		btn_vbox.add_child(sweep_btn)
	elif is_current and can_challenge:
		var challenge_btn = Button.new()
		challenge_btn.text = "⚔️ 挑战"
		challenge_btn.custom_minimum_size = Vector2(110, 48)
		challenge_btn.add_theme_font_size_override("font_size", 18)
		UIStyle.apply_golden_button_style(challenge_btn)
		UIStyle.setup_button_animation(challenge_btn)
		challenge_btn.disabled = not net_ok
		if not net_ok:
			challenge_btn.tooltip_text = "请先登录后再挑战套装副本"
		challenge_btn.set_meta("base_text", "⚔️ 挑战")
		challenge_btn.pressed.connect( func(): _on_challenge(level, game_manager, parent_control, challenge_btn))
		btn_vbox.add_child(challenge_btn)
	else:
		var locked_btn = Button.new()
		locked_btn.text = "🔒 未解锁"
		locked_btn.custom_minimum_size = Vector2(110, 48)
		locked_btn.add_theme_font_size_override("font_size", 16)
		locked_btn.disabled = true
		UIStyle.apply_button_style(locked_btn)
		btn_vbox.add_child(locked_btn)

	return panel

static func _get_element_color(element: String) -> Color:
	match element:
		"金": return Color(1, 0.84, 0, 1)
		"木": return Color(0.13, 0.55, 0.13, 1)
		"水": return Color(0.072, 0.080, 0.079, 1)
		"火": return Color(1, 0.27, 0, 1)
		"土": return Color(0.55, 0.27, 0.07, 1)
		"风": return Color(0.5, 0.8, 0.8, 1)
		"光": return Color(1, 1, 0.8, 1)
		"暗": return Color(0.072, 0.080, 0.079, 1)
		"混沌": return Color(0.5, 0, 0.5, 1)
		"八卦": return Color(0.8, 0.2, 0.2, 1)
		"战": return Color(0.8, 0, 0, 1)
		_: return Color(0.7, 0.7, 0.7, 1)

static func _format_number(num: int) -> String:
	if num >= 100000000:
		return "%d亿" % (num / 100000000)
	elif num >= 10000:
		return "%d万" % (num / 10000)
	else:
		return str(num)

static func _start_button_cooldown(button: Button, base_text: String, seconds: int = BUTTON_COOLDOWN_SEC) -> void :
	if button == null or not is_instance_valid(button):
		return
	button.disabled = true
	for remaining in range(seconds, 0, -1):
		if not is_instance_valid(button):
			return
		button.text = "%s(%ds)" % [base_text, remaining]
		await button.get_tree().create_timer(1.0).timeout
	if not is_instance_valid(button):
		return
	button.text = base_text
	button.disabled = false

static func _on_challenge(level: int, game_manager, parent_control: Control = null, trigger_btn: Button = null):
	if trigger_btn and is_instance_valid(trigger_btn):
		_start_button_cooldown(trigger_btn, str(trigger_btn.get_meta("base_text", trigger_btn.text)))
	if game_manager == null or game_manager.player == null:
		_show_alert(parent_control, "游戏未初始化")
		return
	var block_msg: = ""
	if game_manager.has_method("get_instanced_challenge_block_message"):
		block_msg = str(game_manager.get_instanced_challenge_block_message(""))
	elif game_manager.has_method("is_in_instanced_challenge") and game_manager.is_in_instanced_challenge():
		block_msg = "其他挑战正在进行中，请先完成或停止当前挑战后再试"
	if not block_msg.is_empty():
		_show_alert(parent_control, block_msg)
		return
	if game_manager.has_method("prepare_for_instanced_challenge_async"):
		await game_manager.prepare_for_instanced_challenge_async()
	elif game_manager.has_method("prepare_for_instanced_challenge"):
		game_manager.prepare_for_instanced_challenge()
	await _start_suit_dungeon_challenge(level, game_manager, parent_control)

static func _start_suit_dungeon_challenge(level: int, game_manager, parent_control: Control = null) -> void :
	if game_manager.player.gold < _suit_entry_cost(game_manager):
		_show_alert(parent_control, "金币不足！需要50万金币")
		return
	if not game_manager.network or not game_manager.network.is_logged_in():
		_show_alert(parent_control, "请先登录后再挑战套装副本。")
		return
	var snapshot = game_manager.create_secure_op_snapshot()
	var entry_cost: = _suit_entry_cost(game_manager)
	var client_deduct: = _suit_client_deduct_entry(game_manager)


	if client_deduct:
		game_manager.player.gold -= entry_cost
	var commit_ok = await game_manager.commit_secure_op()
	if not commit_ok:
		game_manager.restore_secure_op_snapshot(snapshot)
		_show_alert(parent_control, "云端确认失败，本次挑战扣费已回滚。")
		return


	var waves = _create_suit_dungeon_waves(level)


	var success = await game_manager.start_suit_dungeon_battle(level, waves)
	if not success:
		_show_alert(parent_control, "无法开始战斗，请稍后再试", "错误")
		_refund_suit_entry(game_manager, entry_cost, client_deduct)


static func _show_waiting_dialog(level: int, waves: Array, game_manager, parent_control: Control, entry_cost: int = DUNGEON_COST, client_deduct: bool = true):
	if parent_control == null:
		_show_alert(null, "当前正在战斗中，请等待战斗结束后再试")
		_refund_suit_entry(game_manager, entry_cost, client_deduct)
		return

	var waiting_panel = Panel.new()
	waiting_panel.name = "SuitDungeonWaitingPanel"
	waiting_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	waiting_panel.z_index = 1000

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0, 0, 0, 0.8)
	waiting_panel.add_theme_stylebox_override("panel", bg_style)

	parent_control.add_child(waiting_panel)

	var content_container = Control.new()
	content_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	waiting_panel.add_child(content_container)

	var center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_container.add_child(center_container)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	center_container.add_child(vbox)

	var anim_label = Label.new()
	anim_label.name = "WaitingAnimLabel"
	anim_label.text = "⚔️"
	anim_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	anim_label.add_theme_font_size_override("font_size", 48)
	vbox.add_child(anim_label)

	var msg_label = Label.new()
	msg_label.text = "当前野外战斗进行中...\n等待战斗结束后自动进入套装副本"
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.add_theme_font_size_override("font_size", 16)
	msg_label.add_theme_color_override("font_color", Color(1, 1, 1))
	vbox.add_child(msg_label)

	var countdown_label = Label.new()
	countdown_label.name = "CountdownLabel"
	countdown_label.text = "等待中..."
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.add_theme_font_size_override("font_size", 14)
	countdown_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(countdown_label)

	var cancel_btn = Button.new()
	cancel_btn.text = "取消挑战"
	cancel_btn.custom_minimum_size = Vector2(120, 40)
	cancel_btn.pressed.connect( func():
		_cleanup_waiting_dialog(parent_control)
		_refund_suit_entry(game_manager, entry_cost, client_deduct)
	)
	vbox.add_child(cancel_btn)

	var tween = parent_control.create_tween()
	if tween:
		tween.set_loops()
		tween.tween_property(anim_label, "rotation", 2 * PI, 1.0)

	_start_countdown_animation(parent_control, countdown_label)


	var on_battle_ended: Callable
	var requeue_wait: Callable = func() -> void :
		if game_manager and game_manager.battle_system and not game_manager.battle_system.battle_ended.is_connected(on_battle_ended):
			game_manager.battle_system.battle_ended.connect(on_battle_ended, CONNECT_ONE_SHOT)
	on_battle_ended = func(victory: bool):
		if game_manager == null:
			return
		var tree = game_manager.get_tree()
		if tree == null:
			return
		await tree.create_timer(0.5).timeout
		if game_manager == null:
			return
		if is_instance_valid(parent_control) and parent_control.get_node_or_null("SuitDungeonWaitingPanel") == null:
			return
		if game_manager.in_battle:
			requeue_wait.call()
			return
		var inst_block: = ""
		if game_manager.has_method("get_instanced_challenge_block_message"):
			inst_block = str(game_manager.get_instanced_challenge_block_message(""))
		if not inst_block.is_empty():
			_cleanup_waiting_dialog(parent_control)
			_show_alert(parent_control, inst_block)
			return


		_cleanup_waiting_dialog(parent_control)
		if game_manager.has_method("prepare_for_instanced_challenge_async"):
			await game_manager.prepare_for_instanced_challenge_async()
		elif game_manager.has_method("prepare_for_instanced_challenge"):
			game_manager.prepare_for_instanced_challenge()
		await _start_suit_dungeon_challenge(level, game_manager, parent_control)

	requeue_wait.call()


static func _start_countdown_animation(parent_control: Control, countdown_label: Label):
	if countdown_label == null or not is_instance_valid(countdown_label):
		return

	var wait_time = 0
	while true:
		if not is_instance_valid(parent_control):
			break
		var tree = parent_control.get_tree()
		if tree == null:
			break
		await tree.create_timer(1.0).timeout
		if not is_instance_valid(parent_control):
			break

		if parent_control.get_node_or_null("SuitDungeonWaitingPanel") == null:
			break

		wait_time += 1
		if countdown_label and is_instance_valid(countdown_label):
			countdown_label.text = "已等待 %d 秒..." % wait_time


static func _cleanup_waiting_dialog(parent_control: Control):
	if parent_control and is_instance_valid(parent_control):
		var waiting_panel = parent_control.get_node_or_null("SuitDungeonWaitingPanel")
		if waiting_panel:
			waiting_panel.queue_free()


static func _create_suit_dungeon_waves(level: int) -> Array:
	var SuitDungeonMonsters = load("res://scripts/data/suit_dungeon_monsters.gd")

	var all_waves = []
	for wave in range(1, 11):
		var wave_monsters = SuitDungeonMonsters.get_wave_monsters(level, wave)
		all_waves.append(wave_monsters)
	return all_waves

static func _coerce_string_name_array(raw: Variant) -> Array:
	var out: Array = []
	if raw is Array:
		for el in raw:
			var s: = str(el).strip_edges()
			if not s.is_empty():
				out.append(s)
	return out

static func _is_server_truthy(v: Variant) -> bool:
	return (typeof(v) == TYPE_BOOL and v) or (typeof(v) == TYPE_INT and int(v) != 0)

static func _parse_suit_sweep_server_drops(server_data: Dictionary) -> Dictionary:
	var sealed: Array = []
	var stones: Array = []
	var drop_items_raw: Variant = null
	if server_data.has("dropItems"):
		drop_items_raw = server_data.get("dropItems")
	elif server_data.has("drop_items"):
		drop_items_raw = server_data.get("drop_items")
	if drop_items_raw is Array:
		for it in drop_items_raw:
			if it is Dictionary:
				var d: Dictionary = it
				var item_name: = str(d.get("name", "")).strip_edges()
				if item_name.is_empty():
					continue
				var item_type: = str(d.get("type", "")).strip_edges()
				if item_type == "stone" or item_name.ends_with("普通解封石"):
					stones.append(item_name)
				else:
					sealed.append(item_name)
	if sealed.is_empty() and stones.is_empty():
		sealed = _coerce_string_name_array(
			server_data.get("sealedSuitsDropped", server_data.get("sealed_suits_dropped", []))
		)
		stones = _coerce_string_name_array(
			server_data.get("stonesDropped", server_data.get("stones_dropped", []))
		)
	return {"sealed": sealed, "stones": stones}

static func _build_suit_sweep_result_message(gold_granted: int, is_dup: bool, drop_messages: Array, server_data: Dictionary) -> String:
	var message: String
	if is_dup:
		message = "金币已在首次扫荡时发放"
	else:
		message = "获得金币：%s" % _format_number(gold_granted)
	if is_dup:
		message += "\n\n本次扫荡已结算，掉落请查看云端邮件"
	elif drop_messages.size() > 0:
		message += "\n\n掉落物品已由服务器发送到邮件：\n" + "\n".join(drop_messages)
	elif _is_server_truthy(server_data.get("suitDropMailSent", false)):
		message += "\n\n服务器已将掉落发送至邮件，请到邮箱查看领取。"
	else:
		message += "\n\n本次扫荡没有获得额外物品"
	return message

static func _on_sweep(level: int, game_manager, parent_control: Control, trigger_btn: Button = null) -> void :
	if _is_sweeping:
		return
	if not game_manager.network or not game_manager.network.is_logged_in():
		_show_alert(parent_control, "请先登录后再扫荡套装副本。")
		return
	if game_manager.player.suit_dungeon_sweeps <= 0:
		_show_game_alert(parent_control, "今日扫荡次数已用完", "扫荡失败")
		_refresh_sweep_display(parent_control, game_manager)
		return
	if trigger_btn and is_instance_valid(trigger_btn):
		_start_button_cooldown(trigger_btn, str(trigger_btn.get_meta("base_text", trigger_btn.text)))
	_is_sweeping = true
	var op_id: = "suit_sweep_%d_%d" % [Time.get_unix_time_from_system(), randi()]
	var er: Dictionary = await game_manager.wait_economy("economy_suit_sweep", func():
		game_manager.network.economy_suit_dungeon_sweep_reward(op_id, level)
	, op_id)
	_is_sweeping = false
	if er.get("ok", false):
		var dvar: Variant = er.get("data", {})
		var sweep_g: = 0
		var server_data: Dictionary = {}
		var progress_changed: = false
		if dvar is Dictionary:
			var d: Dictionary = dvar
			server_data = d
			if d.has("newGold"):
				game_manager.player.gold = int(d.get("newGold", game_manager.player.gold))
			if d.has("sweepsLeft"):
				# 服务端这次扣了 1 次，回的是**剩余**次数（与 player.suit_dungeon_sweeps 同义）
				game_manager.player.suit_dungeon_sweeps = int(d.get("sweepsLeft", 0))
			if d.has("suitDungeonProgress"):
				var server_progress: = int(d.get("suitDungeonProgress", -1))
				if server_progress > int(game_manager.player.suit_dungeon_progress):
					game_manager.player.suit_dungeon_progress = server_progress
					progress_changed = true
			sweep_g = int(d.get("goldGranted", d.get("goldGained", 0)))
		game_manager.gold_changed.emit(game_manager.player.gold)
		_perform_sweep(level, game_manager, parent_control, sweep_g, server_data)
		_refresh_sweep_display(parent_control, game_manager)
		if progress_changed:
			refresh_panel(game_manager, parent_control)
	else:
		_show_game_alert(parent_control, str(er.get("err", "扫荡失败")), "扫荡失败")
		_refresh_sweep_display(parent_control, game_manager)

static func _perform_sweep(level: int, game_manager, parent_control: Control, gold_granted: int, server_data: Dictionary) -> void :

	var is_dup: = _is_server_truthy(server_data.get("duplicate", false))
	if game_manager.quest_manager and not is_dup:
		game_manager.quest_manager.on_suit_dungeon_completed(level)
	var drop_messages: Array = []
	if not is_dup:
		var server_drops: = _parse_suit_sweep_server_drops(server_data)
		for sealed_name in server_drops.get("sealed", []):
			drop_messages.append("封印套装：%s" % str(sealed_name))
			game_manager.broadcast_event("suit_obtain", game_manager.player.player_name, {"suit_name": str(sealed_name)})
		for stone_name in server_drops.get("stones", []):
			drop_messages.append("%s x1" % str(stone_name))
		if _is_server_truthy(server_data.get("suitDropMailSent", false)) and MailManager.instance:
			MailManager.instance.refresh_mail_list()
	var message: = _build_suit_sweep_result_message(gold_granted, is_dup, drop_messages, server_data)
	_show_game_alert(parent_control, message, "扫荡完成 · 第 %d 层" % level)


static func _show_alert(parent_control: Control, message: String, title: String = "提示") -> void :
	_show_game_alert(parent_control, message, title)

static func _viewport_height() -> int:
	var scene_root = Engine.get_main_loop().current_scene
	if scene_root:
		return int(scene_root.get_viewport().get_visible_rect().size.y)
	return int(DisplayServer.window_get_size().y)

static func _show_game_alert(_parent_control: Control, message: String, title: String = "提示") -> void :
	var scene_root = Engine.get_main_loop().current_scene
	if not scene_root:
		push_warning("[SuitDungeon] %s" % message)
		return
	var popup_key = "suit_dungeon_alert:%s:%d:%d" % [title, Time.get_ticks_msec(), hash(message)]
	if _focus_existing_window_popup(popup_key):
		return

	var popup = Window.new()
	_mark_popup_key(popup, popup_key)
	popup.title = ""
	var viewport_h: = _viewport_height()
	var line_count: int = _estimate_alert_line_count(message)
	var content_height: int = maxi(80, line_count * 28)
	var max_body_h: = int(float(viewport_h) * 0.55)
	var body_h: = mini(content_height, max_body_h)
	var chrome_h: = 200
	var total_height: = mini(chrome_h + body_h, int(float(viewport_h) * 0.85))
	popup.size = Vector2i(420, maxi(280, total_height))
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
	vbox.add_theme_constant_override("separation", 16)
	main_panel.add_child(vbox)

	var title_label = Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(title_label)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, body_h)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	vbox.add_child(scroll)

	var content_label = Label.new()
	content_label.text = message
	content_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_label.add_theme_font_size_override("font_size", 18)
	content_label.add_theme_color_override("font_color", Color(0.894, 0.864, 0.803))
	content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_label.custom_minimum_size = Vector2(340, 0)
	content_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content_label)

	var ok_btn = Button.new()
	ok_btn.text = "确定"
	UIStyle.style_popup_button(ok_btn, true)
	ok_btn.pressed.connect( func(): popup.queue_free())
	vbox.add_child(ok_btn)

	scene_root.add_child(popup)
	popup.popup_centered()

static func _suit_sweep_label_text(sweeps_left: int) -> String:
	if _sweep_cap > 0:
		return "今日可扫荡: %d/%d 次" % [sweeps_left, _sweep_cap]
	return "今日可扫荡: %d 次" % sweeps_left

static func _bind_suit_dungeon_info_sync(game_manager, sweep_label: Label) -> void :
	if not game_manager or not game_manager.network or not game_manager.network.is_logged_in():
		return
	var net = game_manager.network
	net.suit_dungeon_info_loaded.connect( func(sweeps_left: int, max_sweeps: int):
		if game_manager.player == null:
			return
		# 服务端回的是**剩余**次数（扣一次减一），本地直接对齐，别再自己算
		game_manager.player.suit_dungeon_sweeps = sweeps_left
		_sweep_cap = maxi(0, max_sweeps)
		# 进度只增不减：服务端权威值更高时跟上（换设备 / 旧存档没落库）
		var server_progress: = int(net.suit_dungeon_server_progress)
		if server_progress > int(game_manager.player.suit_dungeon_progress):
			game_manager.player.suit_dungeon_progress = server_progress
		if is_instance_valid(sweep_label):
			sweep_label.text = _suit_sweep_label_text(sweeps_left)
	, CONNECT_ONE_SHOT)
	net.get_suit_dungeon_info()

static func _update_sweep_count_label(parent_control: Control, game_manager) -> void :
	if not parent_control or not is_instance_valid(parent_control) or game_manager == null:
		return
	var sweep_label: = parent_control.find_child("sweep_label", true, false) as Label
	if sweep_label and is_instance_valid(sweep_label):
		sweep_label.text = _suit_sweep_label_text(int(game_manager.player.suit_dungeon_sweeps))

static func _refresh_sweep_display(parent_control: Control, game_manager) -> void :
	_update_sweep_count_label(parent_control, game_manager)
