extends Control

const UIStyle = preload("res://scripts/ui_style.gd")
const XianMoEventPopup = preload("res://ui/xianmo/xianmo_event_popup.tscn")
const XianMoFactionSelect = preload("res://ui/xianmo/xianmo_faction_select.tscn")
const XianMoExploringAnimation = preload("res://ui/xianmo/xianmo_exploring_animation.tscn")
const TitleData = preload("res://scripts/title/title_data.gd")

const LOG_SAVE_PATH = "user://xianmo_event_logs_%s.json"
const MAX_LOG_ENTRIES = 50

var game_manager = null
var _pending_event: Dictionary = {}
var _pending_chest_popup: Control = null
var _pending_open_chest_type: String = ""
var _pending_open_chest_count: int = 0
var _event_logs: Array = []
var _current_user_id: int = 0

const ADVENTURE_BTN_COOLDOWN_SEC: = 3
var _adventure_btn_cooldown_until_ms: int = 0
var _adventure_cooldown_task_running: bool = false

@onready var week_label = $MarginContainer / VBoxContainer / Header / MarginContainer / HBoxContainer / WeekLabel
@onready var countdown_label = $MarginContainer / VBoxContainer / Header / MarginContainer / HBoxContainer / CountdownLabel
@onready var xian_panel = $MarginContainer / VBoxContainer / FactionContainer / XianPanel
@onready var mo_panel = $MarginContainer / VBoxContainer / FactionContainer / MoPanel
@onready var xian_count_label = $MarginContainer / VBoxContainer / FactionContainer / XianPanel / MarginContainer / HBoxContainer / InfoContainer / CountLabel
@onready var xian_score_label = $MarginContainer / VBoxContainer / FactionContainer / XianPanel / MarginContainer / HBoxContainer / InfoContainer / ScoreLabel
@onready var xian_leading_label = $MarginContainer / VBoxContainer / FactionContainer / XianPanel / MarginContainer / HBoxContainer / InfoContainer / LeadingLabel
@onready var mo_count_label = $MarginContainer / VBoxContainer / FactionContainer / MoPanel / MarginContainer / HBoxContainer / InfoContainer / CountLabel
@onready var mo_score_label = $MarginContainer / VBoxContainer / FactionContainer / MoPanel / MarginContainer / HBoxContainer / InfoContainer / ScoreLabel
@onready var mo_leading_label = $MarginContainer / VBoxContainer / FactionContainer / MoPanel / MarginContainer / HBoxContainer / InfoContainer / LeadingLabel
@onready var player_info_panel = $MarginContainer / VBoxContainer / PlayerInfoPanel
@onready var faction_label = $MarginContainer / VBoxContainer / PlayerInfoPanel / MarginContainer / HBoxContainer / LeftContainer / TopRow / FactionLabel
@onready var title_label = $MarginContainer / VBoxContainer / PlayerInfoPanel / MarginContainer / HBoxContainer / LeftContainer / TopRow / TitleLabel
@onready var player_name_label = $MarginContainer / VBoxContainer / PlayerInfoPanel / MarginContainer / HBoxContainer / LeftContainer / TopRow / PlayerNameLabel
@onready var level_label = $MarginContainer / VBoxContainer / PlayerInfoPanel / MarginContainer / HBoxContainer / LeftContainer / MiddleRow / LevelLabel
@onready var realm_label = $MarginContainer / VBoxContainer / PlayerInfoPanel / MarginContainer / HBoxContainer / LeftContainer / MiddleRow / RealmLabel
@onready var weekly_score_label = $MarginContainer / VBoxContainer / PlayerInfoPanel / MarginContainer / HBoxContainer / LeftContainer / ScoreRow / WeeklyScoreLabel
@onready var total_score_label = $MarginContainer / VBoxContainer / PlayerInfoPanel / MarginContainer / HBoxContainer / LeftContainer / ScoreRow / TotalScoreLabel
@onready var action_points_bar = $MarginContainer / VBoxContainer / PlayerInfoPanel / MarginContainer / HBoxContainer / LeftContainer / ActionPointsRow / ActionPointsBar
@onready var action_points_label = $MarginContainer / VBoxContainer / PlayerInfoPanel / MarginContainer / HBoxContainer / LeftContainer / ActionPointsRow / ActionPointsLabel
@onready var adventure_btn = $MarginContainer / VBoxContainer / PlayerInfoPanel / MarginContainer / HBoxContainer / AdventureBtnContainer / AdventureBtn
@onready var log_container = $MarginContainer / VBoxContainer / LogPanel / MarginContainer / VBoxContainer / ScrollContainer / LogContainer
@onready var log_panel = $MarginContainer / VBoxContainer / LogPanel
@onready var ranking_btn = $MarginContainer / VBoxContainer / BottomNav / MarginContainer / HBoxContainer / RankingBtn
@onready var shop_btn = $MarginContainer / VBoxContainer / BottomNav / MarginContainer / HBoxContainer / ShopBtn
@onready var chest_btn = $MarginContainer / VBoxContainer / BottomNav / MarginContainer / HBoxContainer / ChestBtn
@onready var treasure_btn = $MarginContainer / VBoxContainer / BottomNav / MarginContainer / HBoxContainer / TreasureBtn
@onready var title_btn = $MarginContainer / VBoxContainer / BottomNav / MarginContainer / HBoxContainer / TitleBtn
@onready var rules_btn = $MarginContainer / VBoxContainer / BottomNav / MarginContainer / HBoxContainer / RulesBtn
@onready var back_btn = $MarginContainer / VBoxContainer / BottomNav / MarginContainer / HBoxContainer / BackBtn

var xianmo_system = null
var xianmo_shop = null
var xianmo_ranking = null
var _logs_loaded = false

signal back_pressed

func _ready():
	_setup_signals()
	_setup_style()
	_play_enter_animation()
	_play_bgm()
	_try_load_logs()

func _exit_tree():
	_stop_bgm()

func _play_bgm():
	if game_manager and game_manager.has_method("play_bgm_xianmo"):
		game_manager.play_bgm_xianmo()

func _stop_bgm():
	if game_manager and game_manager.has_method("play_bgm_normal"):
		game_manager.play_bgm_normal()

func _setup_signals():
	if adventure_btn:
		adventure_btn.pressed.connect(_on_adventure_btn_pressed)
	if ranking_btn:
		ranking_btn.pressed.connect(_on_ranking_btn_pressed)
	if shop_btn:
		shop_btn.pressed.connect(_on_shop_btn_pressed)
	if chest_btn:
		chest_btn.pressed.connect(_on_chest_btn_pressed)
	if treasure_btn:
		treasure_btn.pressed.connect(_on_treasure_btn_pressed)
	if title_btn:
		title_btn.pressed.connect(_on_title_btn_pressed)
	if rules_btn:
		rules_btn.pressed.connect(_on_rules_btn_pressed)
	if back_btn:
		back_btn.pressed.connect(_on_back_btn_pressed)

func _setup_style():
	if xian_panel:
		xian_panel.add_theme_stylebox_override("panel", _create_faction_panel_style(Color(0.2, 0.4, 0.8, 0.35), Color(0.3, 0.5, 0.9)))
	if mo_panel:
		mo_panel.add_theme_stylebox_override("panel", _create_faction_panel_style(Color(0.6, 0.2, 0.2, 0.35), Color(0.8, 0.3, 0.3)))
	if player_info_panel:
		player_info_panel.add_theme_stylebox_override("panel", _create_content_panel_style())
	if log_panel:
		log_panel.add_theme_stylebox_override("panel", _create_content_panel_style())
	if adventure_btn:
		_setup_adventure_btn_style()
	_setup_bottom_nav_style()

func _setup_bottom_nav_style():
	var buttons = [ranking_btn, shop_btn, chest_btn, treasure_btn, title_btn, rules_btn, back_btn]
	for btn in buttons:
		if btn:
			btn.custom_minimum_size = Vector2(80, 50)
			btn.add_theme_font_size_override("font_size", 20)
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.25, 0.25, 0.35)
			style.border_width_left = 2
			style.border_width_right = 2
			style.border_width_top = 2
			style.border_width_bottom = 2
			style.border_color = Color(0.5, 0.5, 0.6)
			style.corner_radius_top_left = 10
			style.corner_radius_top_right = 10
			style.corner_radius_bottom_left = 10
			style.corner_radius_bottom_right = 10
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))

			var hover_style = style.duplicate()
			hover_style.bg_color = Color(0.35, 0.35, 0.45)
			hover_style.border_color = Color(0.6, 0.6, 0.7)
			btn.add_theme_stylebox_override("hover", hover_style)

			var pressed_style = style.duplicate()
			pressed_style.bg_color = Color(0.2, 0.2, 0.28)
			btn.add_theme_stylebox_override("pressed", pressed_style)

func _create_faction_panel_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = border_color
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.shadow_color = Color(0, 0, 0, 0.25)
	style.shadow_size = 6
	style.shadow_offset = Vector2(2, 3)
	return style

func _create_content_panel_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.4, 0.5)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	return style

func _setup_adventure_btn_style():
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.8, 0.5, 0.1)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(1.0, 0.7, 0.2)
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)
	adventure_btn.add_theme_stylebox_override("normal", style)

	var hover_style = style.duplicate()
	hover_style.bg_color = Color(0.9, 0.6, 0.2)
	hover_style.border_color = Color(1.0, 0.8, 0.3)
	adventure_btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = style.duplicate()
	pressed_style.bg_color = Color(0.7, 0.4, 0.1)
	pressed_style.border_color = Color(0.9, 0.6, 0.2)
	adventure_btn.add_theme_stylebox_override("pressed", pressed_style)

	adventure_btn.add_theme_font_size_override("font_size", 18)
	adventure_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	adventure_btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	adventure_btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.9, 0.9))

func _add_log(message: String):
	if not log_container:
		return

	var time_str = Time.get_time_string_from_system()
	var log_entry = Label.new()
	log_entry.text = "[%s] %s" % [time_str, message]
	log_entry.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_entry.add_theme_font_size_override("font_size", 20)
	log_entry.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))

	log_container.add_child(log_entry)

	_event_logs.append({"time": time_str, "message": message})

	if _event_logs.size() > MAX_LOG_ENTRIES:
		_event_logs.pop_front()
		if log_container.get_child_count() > 0:
			log_container.get_child(0).queue_free()

	_save_event_logs()

	await get_tree().process_frame
	var scroll = log_container.get_parent()
	if scroll and scroll is ScrollContainer:
		scroll.ensure_control_visible(log_entry)

func _save_event_logs():
	if _current_user_id == 0:
		return
	var path = LOG_SAVE_PATH % _current_user_id
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		var json = JSON.new()
		var json_string = json.stringify(_event_logs)
		file.store_string(json_string)
		file.close()

func _load_event_logs():
	if _current_user_id == 0:
		return
	if not is_inside_tree():
		return
	if not log_container:
		return
	var path = LOG_SAVE_PATH % _current_user_id
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			var json = JSON.new()
			var error = json.parse(json_string)
			if error == OK:
				var data = json.data
				if data is Array:
					_event_logs = data
					for log_entry in _event_logs:
						var label = Label.new()
						label.text = "[%s] %s" % [log_entry.get("time", ""), log_entry.get("message", "")]
						label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
						label.add_theme_font_size_override("font_size", 20)
						label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
						log_container.add_child(label)

					await get_tree().process_frame
					var scroll = log_container.get_parent()
					if scroll and scroll is ScrollContainer:
						var last_child = log_container.get_child(log_container.get_child_count() - 1)
						if last_child:
							scroll.ensure_control_visible(last_child)

func _play_enter_animation():
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

func set_game_manager(gm):
	game_manager = gm
	if game_manager:
		xianmo_system = game_manager.xianmo_system
		xianmo_shop = game_manager.xianmo_shop
		xianmo_ranking = game_manager.xianmo_ranking

		if game_manager.network:
			_current_user_id = game_manager.network.user_id
			_try_load_logs()

		if game_manager.title_manager:
			if not game_manager.title_manager.titles_updated.is_connected(_on_titles_updated):
				game_manager.title_manager.titles_updated.connect(_on_titles_updated)
			game_manager.title_manager.load_server_titles()

		if xianmo_system:
			xianmo_system.faction_assigned.connect(_on_faction_assigned)
			xianmo_system.action_points_changed.connect(_on_action_points_changed)
			xianmo_system.score_changed.connect(_on_score_changed)
			xianmo_system.fragments_changed.connect(_on_fragments_changed)
			xianmo_system.event_triggered.connect(_on_event_triggered)
			xianmo_system.adventure_failed.connect(_on_adventure_failed)
			xianmo_system.data_loaded.connect(_on_data_loaded)
			_refresh_from_server()

		_update_ui()

func _try_load_logs():
	if _logs_loaded:
		return
	if _current_user_id == 0:
		return
	if not is_inside_tree():
		return
	if not log_container:
		return

	_logs_loaded = true
	_load_event_logs()

	if _event_logs.is_empty():
		_add_log("欢迎来到仙魔战场！点击「选择阵营」开启你的冒险之旅。")

func _on_data_loaded():
	_update_ui()

func _on_titles_updated():
	if is_instance_valid(self) and game_manager:
		_update_player_info()

func _on_event_triggered(event: Dictionary):
	_pending_event = event
	_show_exploring_animation(event)

func _on_adventure_failed(error):
	var error_str = str(error) if error != null else "未知错误"
	_show_message("探险失败: %s" % error_str)
	_pending_event = {}

func _refresh_from_server():
	if xianmo_system:
		xianmo_system.load_from_server()

func _update_ui():
	if not xianmo_system:
		return

	_update_header()
	_update_faction_panels()
	_update_player_info()
	_update_action_points()
	_update_adventure_btn_text()

func update_ui():
	_update_ui()

func _update_header():
	if week_label and xianmo_system:
		week_label.text = "第%d周" % int(xianmo_system.global_state.week_number)
	if countdown_label and xianmo_system:
		countdown_label.text = "倒计时: " + xianmo_system.get_week_remaining_time_string()

func _update_faction_panels():
	if not xianmo_system:
		return

	var xian_count = int(xianmo_system.global_state.xian_count)
	var mo_count = int(xianmo_system.global_state.mo_count)
	var xian_score = int(xianmo_system.global_state.xian_total_score)
	var mo_score = int(xianmo_system.global_state.mo_total_score)

	print("[XianMoMainPanel] _update_faction_panels: xian_count=", xian_count, ", mo_count=", mo_count, ", xian_score=", xian_score, ", mo_score=", mo_score)

	if xianmo_ranking and xianmo_system.global_state.xian_count > 0:
		var comparison = xianmo_ranking.get_faction_comparison()
		xian_count = int(comparison.xian.count)
		mo_count = int(comparison.mo.count)
		xian_score = int(comparison.xian.total_score)
		mo_score = int(comparison.mo.total_score)

	if xian_count_label:
		xian_count_label.text = "%d人" % xian_count
	if xian_score_label:
		xian_score_label.text = "%d分" % xian_score
	if xian_leading_label:
		xian_leading_label.text = "🏆领先" if xian_score > mo_score else ""
		xian_leading_label.visible = xian_score > mo_score

	if mo_count_label:
		mo_count_label.text = "%d人" % mo_count
	if mo_score_label:
		mo_score_label.text = "%d分" % mo_score
	if mo_leading_label:
		mo_leading_label.text = "🏆领先" if mo_score > xian_score else ""
		mo_leading_label.visible = mo_score > xian_score

func _update_player_info():
	if not game_manager or not game_manager.player:
		return

	var player = game_manager.player
	var title_name = player.get_active_title_name()

	if faction_label and xianmo_system and xianmo_system.xianmo_data:
		var faction = xianmo_system.xianmo_data.faction
		faction_label.text = xianmo_system.get_faction_name(faction)
		faction_label.visible = not faction.is_empty()

	if title_label:
		title_label.text = title_name if not title_name.is_empty() else ""
		title_label.visible = not title_name.is_empty()

	if player_name_label:
		player_name_label.text = player.player_name

	if level_label:
		level_label.text = "等级: %d" % int(player.level)

	if realm_label:
		realm_label.text = "境界: %s" % player.realm

	if weekly_score_label and xianmo_system and xianmo_system.xianmo_data:
		weekly_score_label.text = "本周积分: %d" % int(xianmo_system.xianmo_data.weekly_score)

	if total_score_label and xianmo_system and xianmo_system.xianmo_data:
		total_score_label.text = "累积积分: %d" % int(xianmo_system.xianmo_data.total_score)

func _update_action_points():
	if not xianmo_system or not xianmo_system.xianmo_data:
		return

	var info = xianmo_system.get_action_points_info()
	var current = int(info.get("current", 0))
	var max_val = int(info.get("max", 24))

	if action_points_bar:
		action_points_bar.max_value = max_val
		action_points_bar.value = current

	if action_points_label:
		action_points_label.text = "行动力: %d/%d" % [current, max_val]

func _adventure_btn_cooldown_remaining_sec() -> int:
	var until_ms: = _adventure_btn_cooldown_until_ms
	if until_ms <= 0:
		return 0
	var rem: = int(ceil(float(until_ms - Time.get_ticks_msec()) / 1000.0))
	if rem <= 0:
		_adventure_btn_cooldown_until_ms = 0
		return 0
	return rem

func _start_adventure_btn_cooldown() -> void :
	_adventure_btn_cooldown_until_ms = Time.get_ticks_msec() + ADVENTURE_BTN_COOLDOWN_SEC * 1000
	call_deferred("_continue_adventure_btn_cooldown")

func _continue_adventure_btn_cooldown() -> void :
	if _adventure_cooldown_task_running:
		return
	_adventure_cooldown_task_running = true
	while _adventure_btn_cooldown_remaining_sec() > 0:
		var rem: = _adventure_btn_cooldown_remaining_sec()
		if is_instance_valid(adventure_btn):
			adventure_btn.disabled = true
			adventure_btn.text = "%d秒后可再用" % rem
		await get_tree().create_timer(1.0).timeout
	_adventure_btn_cooldown_until_ms = 0
	_adventure_cooldown_task_running = false
	if is_instance_valid(adventure_btn):
		adventure_btn.disabled = false
	_update_adventure_btn_text()

func _update_adventure_btn_text():
	if not adventure_btn:
		return
	if _adventure_btn_cooldown_remaining_sec() > 0:
		return

	if xianmo_system and xianmo_system.xianmo_data and xianmo_system.xianmo_data.is_joined():
		adventure_btn.text = "进入战场"
	else:
		adventure_btn.text = "选择阵营"

func _on_adventure_btn_pressed():
	if not xianmo_system:
		return
	if _adventure_btn_cooldown_remaining_sec() > 0:
		return
	if not _pending_event.is_empty():
		return

	if xianmo_system.is_loading():
		_show_message("正在加载数据，请稍候...")
		return
	if xianmo_system.is_adventure_pending():
		_show_message("正在探险中，请稍候...")
		return

	if not xianmo_system.xianmo_data.is_joined():
		if game_manager and game_manager.player:
			if game_manager.player.cultivation < 1000:
				_show_message("修行值需达到1000才能参与仙魔战场！")
				return
			if game_manager.player.gold < 1000000:
				_show_message("需要100万金币才能参与仙魔战场！")
				return
		_show_faction_select()
		return

	_pending_event = {}
	var result = xianmo_system.start_adventure()
	if result.success:
		_start_adventure_btn_cooldown()
		_add_log("开始探险...")
		if not result.event.is_empty():
			_pending_event = result.event
			_show_exploring_animation(result.event)
	else:
		_show_message(result.message)

func _show_exploring_animation(event: Dictionary):
	var anim = XianMoExploringAnimation.instantiate()
	anim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(anim)
	anim.setup(event.get("event_id", ""), event)
	anim.exploration_completed.connect(_on_exploration_completed.bind(anim))
	anim.start_exploration()

func _on_exploration_completed(anim_node: Control):
	if _pending_event.is_empty():
		if anim_node:
			anim_node.queue_free()
		return

	var event = _pending_event.duplicate()
	_pending_event = {}

	if anim_node:
		anim_node.queue_free()

	var event_type = event.get("type", "")
	var event_id = event.get("event_id", "")
	var reward = event.get("reward", {})
	if reward == null:
		reward = {}
	print("[XianMoMainPanel] _on_exploration_completed: event_id=", event_id, ", event_type=", event_type, ", server_processed=", event.get("server_processed", false))
	print("[XianMoMainPanel] reward=", reward)
	print("[XianMoMainPanel] event keys=", event.keys() if event is Dictionary else "not_dict")
	print("[XianMoMainPanel] event=", event)


	if reward is Dictionary and reward.get("requires_client_battle", false):
		push_warning("[XianMoMainPanel] 收到过期字段 requires_client_battle，已忽略并按服务端结果展示")

	if event.get("server_processed", false):
		print("[XianMoMainPanel] Showing server event result (server processed)")
		_show_server_event_result(event)
	else:
		print("[XianMoMainPanel] Showing event panel")
		_show_event_panel(event)


func _filter_server_synced_rewards_for_grant(rewards: Array) -> Array:
	var out: Array = []
	for r in rewards:
		if not r is Dictionary:
			out.append(r)
			continue
		# 服务端已经落地的奖励（金币已进余额、道具已进背包/已发邮件、宝箱已进宝箱仓库、
		# 残片/修为/经验已加、行动力已扣）只用于弹窗展示，绝不能再让客户端加一次。
		if r.get("sent_via_mail", false) == true:
			continue
		var t = str(r.get("type", ""))
		match t:
			"action_points", "action_point", "actionPoints", "action_points_cost", "action_points_loss", "actionPointsCost", "actionPointsLoss":
				continue
			"score":
				continue
			"gold", "item", "gift":
				if r.get("sent_via_mail", false) == true:
					continue
			"trap":
				var trap_cost = int(r.get("action_points_cost", 0))
				var trap_loss = int(r.get("action_points_loss", 0))
				if trap_cost + trap_loss > 0:
					continue
			_:
				pass
		out.append(r)
	return out

func _show_server_event_result(event: Dictionary):
	var reward = event.get("reward", null)

	var result = {
		"success": true, 
		"score": event.get("score", 0), 
		"rewards": [], 
		"message": ""
	}

	if reward != null and reward is Dictionary:
		if reward.has("rewards") and reward.rewards is Array:
			result.rewards = reward.rewards
		else:
			result.rewards.append(reward)
		if reward.has("message"):
			result.message = reward.message
		if reward.has("won"):
			result.won = reward.won
		if reward.has("battleLog"):
			result.battleLog = reward.battleLog
		if reward.has("rounds"):
			result.rounds = reward.rounds
		if reward.has("opponent"):
			result.opponent = reward.opponent
		if reward.has("is_mirror"):
			result.is_mirror = reward.is_mirror
		if reward.has("factionScoreChange"):
			result.factionScoreChange = reward.factionScoreChange
		if reward.has("enemyFaction"):
			result.enemyFaction = reward.enemyFaction

	if result.rewards.size() > 0 and xianmo_system:
		var to_grant = _filter_server_synced_rewards_for_grant(result.rewards)
		if to_grant.size() > 0:
			xianmo_system.grant_rewards(to_grant)

	if result.message.is_empty():
		var event_id: = str(event.get("event_id", ""))
		if event_id == "inheritance_memory":
			result.message = "你在遗址中找到了尘封已久的【天关令牌】×1！（已发送到邮件）"
		elif event_id == "spirit_beast_market":
			result.message = "获得【建设材料】×1！（已发送到邮件）"
		var event_type = event.get("type", "")
		if result.message.is_empty() and event_type == "battle":
			result.won = reward.get("won", false) if reward != null else false
			result.message = "战斗胜利！" if result.won else "战斗失败..."
		elif result.message.is_empty() and event_type == "trap":
			result.message = "你受到了陷阱的伤害..."
		elif result.message.is_empty() and event_type == "treasure":
			result.message = "你发现了宝箱！"
		elif result.message.is_empty() and event_type == "pet":
			if reward != null and reward.has("captured") and reward.captured == false:
				result.message = "你遇到了一只灵兽，但它逃脱了..."
			else:
				result.message = "你遇到了一只灵兽！"
		elif result.message.is_empty() and event_type == "training":
			result.message = "你完成了一次修炼！"
		elif result.message.is_empty() and event_type == "fragment":
			result.message = "你发现了藏宝图残片！"
		elif result.message.is_empty() and event_type == "empty":
			result.message = "这里空无一物..."
		elif result.message.is_empty() and event_type == "fortune":
			result.message = "你获得了一次悟道机缘！"

	_show_event_result_popup(event, result)

func _show_faction_select():
	var popup = XianMoFactionSelect.instantiate()
	add_child(popup)
	if popup.has_method("set_game_manager"):
		popup.call("set_game_manager", game_manager)
	popup.faction_selected.connect(_on_faction_selected)
	popup.cancelled.connect(_on_faction_select_cancelled)

func _on_faction_selected(faction: String):
	_update_ui()
	var faction_name = "仙道" if faction == "xian" else "魔道"
	_add_log("成功加入%s阵营！" % faction_name)
	_show_message("成功加入%s阵营！" % faction_name)

func _on_faction_select_cancelled():
	pass

func _on_ranking_btn_pressed():
	_show_ranking_panel()

func _on_shop_btn_pressed():
	_show_shop_panel()

func _on_chest_btn_pressed():
	_show_chest_panel()

func _on_treasure_btn_pressed():
	_show_treasure_panel()

func _on_title_btn_pressed():
	_show_title_panel()

func _on_rules_btn_pressed():
	_show_rules_panel()

func _on_back_btn_pressed():
	back_pressed.emit()

func _on_faction_assigned(_faction: String):
	_update_ui()

func _on_action_points_changed(_current: int, _max_points: int):
	_update_action_points()

func _on_score_changed(_weekly: int, _total: int):
	_update_player_info()
	_update_faction_panels()

func _on_fragments_changed(_count: int):
	pass

func _show_message(message: String):
	print("[XianMo] " + message)
	_show_styled_alert("提示", message)

func _show_styled_alert(title: String, message: String):
	var dialog = Window.new()
	dialog.title = ""
	var line_count = message.split("\n").size()
	var content_height = max(80, line_count * 28)
	var total_height = 200 + content_height
	dialog.size = Vector2i(420, total_height)
	dialog.transparent = true
	dialog.borderless = true
	dialog.unresizable = true
	dialog.close_requested.connect( func(): dialog.queue_free())

	var main_panel = Panel.new()
	main_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_panel.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	dialog.add_child(main_panel)

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
	content_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(content_label)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	var ok_btn = Button.new()
	ok_btn.text = "确定"
	UIStyle.style_popup_button(ok_btn, true)
	ok_btn.pressed.connect( func(): dialog.queue_free())
	vbox.add_child(ok_btn)

	add_child(dialog)
	dialog.popup_centered()

func _show_event_panel(event: Dictionary):
	if not game_manager or not game_manager.xianmo_event_processor:
		_show_message("系统错误")
		return

	print("[XianMo] Event data: ", event)
	var result = game_manager.xianmo_event_processor.process_event(event)
	print("[XianMo] Process result: ", result)

	if result.get("requires_choice", false):
		_show_choice_dialog(event, result)
	else:
		var process_result = await xianmo_system.process_event_result(event, result)
		print("[XianMo] Final result: ", process_result)
		_show_event_result_popup(event, process_result)

func _show_choice_dialog(event: Dictionary, result: Dictionary):
	var choices = result.get("choices", [])
	if choices.is_empty():
		return

	var choice_texts = []
	for choice in choices:
		choice_texts.append(choice.get("text", "选项"))

	_show_simple_choice_dialog(event, result, choices)

func _show_simple_choice_dialog(event: Dictionary, result: Dictionary, choices: Array):
	var event_name = event.get("name", "事件")
	var message = result.get("message", "请选择")

	var width = 450
	var height = 300

	var ui = _create_base_popup(event_name, width, height)
	var popup = ui.popup
	var content = ui.content
	var footer = ui.footer

	var msg_label = Label.new()
	msg_label.text = message
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_label.add_theme_font_size_override("font_size", 18)
	content.add_child(msg_label)

	var btn_container = VBoxContainer.new()
	btn_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_container.add_theme_constant_override("separation", 12)
	content.add_child(btn_container)

	for i in range(choices.size()):
		var choice = choices[i]
		var choice_id = choice.get("id", "")
		var choice_text = choice.get("text", "选项")

		var btn = Button.new()
		btn.text = choice_text
		btn.custom_minimum_size = Vector2(280, 50)

		var btn_style = StyleBoxFlat.new()
		btn_style.corner_radius_top_left = 10
		btn_style.corner_radius_top_right = 10
		btn_style.corner_radius_bottom_left = 10
		btn_style.corner_radius_bottom_right = 10

		if choice_id == "leave":
			btn_style.bg_color = Color(0.4, 0.4, 0.45)
			btn_style.border_width_left = 1
			btn_style.border_width_right = 1
			btn_style.border_width_top = 1
			btn_style.border_width_bottom = 1
			btn_style.border_color = Color(0.5, 0.5, 0.55)
		else:
			btn_style.bg_color = Color(0.3, 0.5, 0.7)
			btn_style.border_width_left = 2
			btn_style.border_width_right = 2
			btn_style.border_width_top = 2
			btn_style.border_width_bottom = 2
			btn_style.border_color = Color(0.4, 0.6, 0.8)

		btn.add_theme_stylebox_override("normal", btn_style)

		var hover_style = btn_style.duplicate()
		hover_style.bg_color = btn_style.bg_color.lightened(0.15)
		btn.add_theme_stylebox_override("hover", hover_style)

		var pressed_style = btn_style.duplicate()
		pressed_style.bg_color = btn_style.bg_color.darkened(0.1)
		btn.add_theme_stylebox_override("pressed", pressed_style)

		btn.add_theme_color_override("font_color", Color(1, 1, 1))
		btn.add_theme_font_size_override("font_size", 16)

		btn.pressed.connect( func(): _on_custom_choice_selected(event, choices, i, popup))

		btn_container.add_child(btn)

	add_child(popup)

func _on_custom_choice_selected(event: Dictionary, choices: Array, index: int, popup: Control):
	if index >= choices.size():
		return

	var choice = choices[index]
	var choice_id = choice.get("id", "")

	if popup:
		popup.queue_free()

	if choice_id == "leave":
		_add_log("你选择了离开。")
		return

	if not game_manager or not game_manager.xianmo_event_processor:
		return

	var result = game_manager.xianmo_event_processor.process_event(event, choice_id)
	var process_result = await xianmo_system.process_event_result(event, result)
	_show_event_result_popup(event, process_result)

func _on_dialog_action(event: Dictionary, choices: Array, action: String, dialog: ConfirmationDialog):
	if action.begins_with("choice_"):
		var index = action.substr(7).to_int()
		_on_choice_selected(event, choices, index, dialog)

func _on_choice_selected(event: Dictionary, choices: Array, index: int, dialog: ConfirmationDialog):
	if index >= choices.size():
		return

	var choice = choices[index]
	var choice_id = choice.get("id", "")

	if dialog:
		dialog.queue_free()

	if choice_id == "leave":
		_add_log("你选择了离开。")
		return

	if not game_manager or not game_manager.xianmo_event_processor:
		return

	var result = game_manager.xianmo_event_processor.process_event(event, choice_id)
	var process_result = await xianmo_system.process_event_result(event, result)
	_show_event_result_popup(event, process_result)

func _show_event_result_popup(event: Dictionary, result: Dictionary):
	var popup = XianMoEventPopup.instantiate()
	add_child(popup)
	popup.setup(event, result, game_manager)
	popup.closed.connect(_on_event_popup_closed.bind(event, result))

func _on_event_popup_closed(event: Dictionary, result: Dictionary):
	_update_ui()

	var event_name = event.get("name", "事件")
	var message = result.get("message", "")
	var score = int(result.get("score", 0))

	var log_msg = "%s - %s" % [event_name, message]
	if score != 0:
		log_msg += " (积分%+d)" % score

	_add_log(log_msg)

func _show_ranking_panel():
	print("[XianMoMainPanel] _show_ranking_panel called")
	var content = _create_ranking_panel()
	add_child(content)

func _show_shop_panel():
	var content = _create_shop_panel()
	add_child(content)

func _show_chest_panel():
	var content = _create_chest_panel()
	add_child(content)

func _show_treasure_panel():
	var content = _create_treasure_panel()
	add_child(content)

func _show_title_panel():
	var content = _create_title_panel()
	add_child(content)

func _show_rules_panel():
	var content = _create_rules_panel()
	add_child(content)

func _create_base_popup(title: String, width: int = 500, height: int = 450) -> Dictionary:
	var popup = Control.new()
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.5)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	popup.add_child(bg)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(width, height)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = - width / 2
	panel.offset_top = - height / 2
	panel.offset_right = width / 2
	panel.offset_bottom = height / 2
	popup.add_child(panel)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.18, 0.95)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.5, 0.4, 0.7)
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 5)
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var header = PanelContainer.new()
	header.custom_minimum_size = Vector2(0, 50)
	vbox.add_child(header)

	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color(0.2, 0.15, 0.3, 0.8)
	header_style.corner_radius_top_left = 12
	header_style.corner_radius_top_right = 12
	header.add_theme_stylebox_override("panel", header_style)

	var title_label = Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.85, 1.0))
	header.add_child(title_label)

	var content_margin = MarginContainer.new()
	content_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_margin.add_theme_constant_override("margin_left", 15)
	content_margin.add_theme_constant_override("margin_right", 15)
	content_margin.add_theme_constant_override("margin_top", 10)
	content_margin.add_theme_constant_override("margin_bottom", 10)
	vbox.add_child(content_margin)

	var content = VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	content_margin.add_child(content)

	var footer = VBoxContainer.new()
	footer.custom_minimum_size = Vector2(0, 80)
	vbox.add_child(footer)

	bg.gui_input.connect( func(event):
		if event is InputEventMouseButton and event.pressed:
			popup.queue_free()
	)

	return {
		"popup": popup, 
		"panel": panel, 
		"vbox": vbox, 
		"header": header, 
		"title_label": title_label, 
		"content": content, 
		"footer": footer, 
		"bg": bg
	}

func _create_close_button(text: String = "关 闭") -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(200, 55)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 20)

	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.3, 0.6, 0.9)
	btn_style.border_width_left = 2
	btn_style.border_width_right = 2
	btn_style.border_width_top = 2
	btn_style.border_width_bottom = 2
	btn_style.border_color = Color(0.5, 0.75, 1.0)
	btn_style.corner_radius_top_left = 10
	btn_style.corner_radius_top_right = 10
	btn_style.corner_radius_bottom_left = 10
	btn_style.corner_radius_bottom_right = 10
	btn.add_theme_stylebox_override("normal", btn_style)

	var hover_style = btn_style.duplicate()
	hover_style.bg_color = Color(0.4, 0.7, 1.0)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = btn_style.duplicate()
	pressed_style.bg_color = Color(0.2, 0.5, 0.8)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	return btn

func _create_ranking_panel() -> Control:
	var ui = _create_base_popup("🏆 仙魔战场排行榜", 550, 640)
	var popup = ui.popup
	var content = ui.content
	var footer = ui.footer

	var faction_totals = HBoxContainer.new()
	faction_totals.add_theme_constant_override("separation", 20)
	faction_totals.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(faction_totals)

	var xian_total = Label.new()
	var mo_total = Label.new()
	if xianmo_system and xianmo_system.global_state:
		xian_total.text = "☯️ 仙道: %d分" % int(xianmo_system.global_state.xian_total_score)
		mo_total.text = "☠️ 魔道: %d分" % int(xianmo_system.global_state.mo_total_score)
	else:
		xian_total.text = "☯️ 仙道: 0分"
		mo_total.text = "☠️ 魔道: 0分"
	xian_total.add_theme_font_size_override("font_size", 20)
	mo_total.add_theme_font_size_override("font_size", 20)
	faction_totals.add_child(xian_total)
	faction_totals.add_child(mo_total)

	var tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.name = "RankingTabs"
	content.add_child(tabs)

	var xian_tab = _create_faction_ranking_tab("xian")
	xian_tab.name = "仙道排行"
	tabs.add_child(xian_tab)

	var mo_tab = _create_faction_ranking_tab("mo")
	mo_tab.name = "魔道排行"
	tabs.add_child(mo_tab)

	if game_manager and game_manager.xianmo_ranking:
		print("[XianMoMainPanel] game_manager.xianmo_ranking exists")
		print("[XianMoMainPanel] game_manager.network=", game_manager.network)
		game_manager.xianmo_ranking.rankings_updated.connect( func():
			_refresh_ranking_tabs(tabs, faction_totals)
		)
		game_manager.xianmo_ranking.update_rankings(true)
	else:
		print("[XianMoMainPanel] ERROR: game_manager or xianmo_ranking is null!")
		if game_manager:
			print("[XianMoMainPanel] game_manager exists, xianmo_ranking=", game_manager.xianmo_ranking)
		else:
			print("[XianMoMainPanel] game_manager is null")

	var close_btn = _create_close_button()
	close_btn.pressed.connect( func(): popup.queue_free())
	footer.add_child(close_btn)

	return popup

func _refresh_ranking_tabs(tabs: TabContainer, faction_totals: HBoxContainer):
	if not is_instance_valid(tabs) or not is_instance_valid(faction_totals):
		return
	if xianmo_system and xianmo_system.global_state:
		for child in faction_totals.get_children():
			if child is Label:
				if child.text.begins_with("☯️"):
					child.text = "☯️ 仙道: %d分" % int(xianmo_system.global_state.xian_total_score)
				elif child.text.begins_with("☠️"):
					child.text = "☠️ 魔道: %d分" % int(xianmo_system.global_state.mo_total_score)

	for tab_idx in range(tabs.get_child_count()):
		var tab = tabs.get_child(tab_idx)
		var faction = "xian" if tab_idx == 0 else "mo"
		print("[XianMoMainPanel] refreshing tab ", tab_idx, " faction=", faction, " tab type=", tab.get_class())
		if tab is ScrollContainer:
			_refresh_ranking_tab(tab, faction)

func _refresh_ranking_tab(scroll: ScrollContainer, faction: String):
	print("[XianMoMainPanel] _refresh_ranking_tab called for faction=", faction)
	var old_container = null
	for child in scroll.get_children():
		if child is VBoxContainer:
			old_container = child
			break

	if old_container == null:
		print("[XianMoMainPanel] old_container is null!")
		return

	var rankings = []
	if game_manager and game_manager.xianmo_ranking:
		rankings = game_manager.xianmo_ranking.get_top_players(faction, 20)
	print("[XianMoMainPanel] rankings count for ", faction, ": ", rankings.size())

	var new_container = VBoxContainer.new()
	new_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	new_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_container.add_theme_constant_override("separation", 5)

	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	new_container.add_child(header)

	var rank_header = Label.new()
	rank_header.text = "排名"
	rank_header.custom_minimum_size = Vector2(60, 0)
	rank_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_header.add_theme_font_size_override("font_size", 20)
	rank_header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	header.add_child(rank_header)

	var name_header = Label.new()
	name_header.text = "玩家"
	name_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_header.add_theme_font_size_override("font_size", 20)
	name_header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	header.add_child(name_header)

	var score_header = Label.new()
	score_header.text = "积分"
	score_header.custom_minimum_size = Vector2(80, 0)
	score_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_header.add_theme_font_size_override("font_size", 20)
	score_header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	header.add_child(score_header)

	for i in range(min(20, rankings.size())):
		var player_data = rankings[i]
		var row = _create_ranking_row(i, player_data)
		new_container.add_child(row)

	if rankings.is_empty():
		var empty_label = Label.new()
		empty_label.text = "暂无排名数据"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		new_container.add_child(empty_label)

	old_container.queue_free()
	scroll.add_child(new_container)

func _create_faction_ranking_tab(faction: String) -> ScrollContainer:
	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.name = "RankingScroll_" + faction

	var container = VBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_theme_constant_override("separation", 5)
	scroll.add_child(container)

	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	container.add_child(header)

	var rank_header = Label.new()
	rank_header.text = "排名"
	rank_header.custom_minimum_size = Vector2(60, 0)
	rank_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_header.add_theme_font_size_override("font_size", 20)
	rank_header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	header.add_child(rank_header)

	var name_header = Label.new()
	name_header.text = "玩家"
	name_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_header.add_theme_font_size_override("font_size", 20)
	name_header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	header.add_child(name_header)

	var score_header = Label.new()
	score_header.text = "积分"
	score_header.custom_minimum_size = Vector2(80, 0)
	score_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_header.add_theme_font_size_override("font_size", 20)
	score_header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	header.add_child(score_header)

	var loading_label = Label.new()
	loading_label.text = "加载中..."
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	loading_label.name = "LoadingLabel"
	container.add_child(loading_label)

	var rankings = []
	if game_manager and game_manager.xianmo_ranking:
		rankings = game_manager.xianmo_ranking.get_top_players(faction, 20)
		if rankings.size() > 0:
			loading_label.queue_free()
			for i in range(min(20, rankings.size())):
				var player_data = rankings[i]
				var row = _create_ranking_row(i, player_data)
				container.add_child(row)

	return scroll

func _create_ranking_row(index: int, player_data: Dictionary) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var rank_label = Label.new()
	match index:
		0: rank_label.text = "🥇"
		1: rank_label.text = "🥈"
		2: rank_label.text = "🥉"
		_: rank_label.text = str(index + 1)
	rank_label.custom_minimum_size = Vector2(60, 0)
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_label.add_theme_font_size_override("font_size", 20)
	row.add_child(rank_label)

	var name_label = Label.new()
	name_label.text = player_data.get("player_name", "未知")
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 20)
	row.add_child(name_label)

	var score_label = Label.new()
	score_label.text = str(player_data.get("score", 0))
	score_label.custom_minimum_size = Vector2(80, 0)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 20)
	row.add_child(score_label)

	return row

func _create_rules_panel() -> Control:
	var ui = _create_base_popup("📜 仙魔战场规则说明", 550, 640)
	var popup = ui.popup
	var content = ui.content
	var footer = ui.footer

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	var rules_text = "\r\n【参与条件】\r\n• 修行值需达到1000以上\r\n• 加入战场需消耗100万金币\r\n\r\n【基础规则】\r\n• 仙魔战场每赛季为北京时间周一至周日一周；周一 0 点自动结算上周并发奖（与文档「每周一 00:00 结算」一致）\r\n• 玩家选择加入仙道或魔道阵营\r\n• 消耗行动力进行探险，获取积分和奖励\r\n\r\n【行动力】\r\n• 初始行动力24点，每小时恢复1点\r\n• 每次探险消耗1点行动力\r\n\r\n【积分规则】\r\n• 完成事件获得积分\r\n• 阵营总积分为所有成员积分之和\r\n• 击败敌方阵营玩家/怪物可降低对方阵营积分\r\n• 周结算时根据排名发放奖励\r\n\r\n【阵营对峙】\r\n• 遭遇敌对阵营玩家镜像，胜利+4积分\r\n• 遭遇敌对阵营怪物，胜利+2积分\r\n• 胜利后对方阵营积分-2或-4\r\n• 战斗为模拟战斗，可查看战斗回放\r\n\r\n【阵营怪物】\r\n• 仙道怪物：仙道初阶弟子/仙道精英/仙道长老\r\n• 魔道怪物：魔道初阶弟子/魔道精英/魔道长老\r\n• 怪物属性固定，难度递增\r\n\r\n【事件类型】\r\n• 灵兽事件：可捕捉灵兽\r\n• 宝箱事件：获得随机奖励\r\n• 战斗事件：与敌人战斗（模拟战斗）\r\n• 特殊事件：各种奇遇\r\n\r\n【奖励说明】\r\n• 周结算根据个人排名发放宝箱\r\n• 阵营胜利方额外获得奖励\r\n• 积分可在商店兑换物品"









































	var rules_label = Label.new()
	rules_label.text = rules_text
	rules_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(rules_label)

	var close_btn = _create_close_button()
	close_btn.pressed.connect( func(): popup.queue_free())
	footer.add_child(close_btn)

	return popup

func _enable_popup_scroll_touch(root: Control) -> void :
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
		_enable_popup_scroll_touch(c)

func _create_shop_panel() -> Control:
	var ui = _create_base_popup("🏪 积分兑换", 550, 640)
	var popup = ui.popup
	var content = ui.content
	var footer = ui.footer

	var score_info = Label.new()
	if xianmo_system and xianmo_system.xianmo_data:
		score_info.text = "当前积分: %d" % int(xianmo_system.xianmo_data.total_score)
	else:
		score_info.text = "当前积分: 0"
	score_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_info.add_theme_font_size_override("font_size", 20)
	score_info.add_theme_color_override("font_color", Color(1, 0.85, 0.0))
	content.add_child(score_info)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.scroll_deadzone = 20
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	content.add_child(scroll)

	var items_container = VBoxContainer.new()
	items_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	items_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	items_container.add_theme_constant_override("separation", 10)
	scroll.add_child(items_container)

	var shop_items = [
		{"id": "bronze_chest", "name": "青铜宝箱", "cost": 150, "desc": "随机获得一件青铜套装部件"}, 
		{"id": "silver_chest", "name": "白银宝箱", "cost": 300, "desc": "随机获得一件白银套装部件"}, 
		{"id": "gold_chest", "name": "黄金宝箱", "cost": 450, "desc": "随机获得一件黄金套装部件"}, 
		{"id": "fortify_lv1_book", "name": "硬皮lv1技能书", "cost": 5000, "desc": "宠物技能书，可学习硬皮lv1技能，提升宠物基础防御70%"}
	]

	for item in shop_items:
		var item_panel = _create_shop_item(item, popup)
		items_container.add_child(item_panel)

	_enable_popup_scroll_touch(items_container)

	var close_btn = _create_close_button()
	close_btn.pressed.connect( func(): popup.queue_free())
	footer.add_child(close_btn)

	return popup

func _create_shop_item(item: Dictionary, popup: Control) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 108)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.8)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.3, 0.3, 0.4)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(hbox)

	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(info_vbox)

	var name_label = Label.new()
	var item_icon: = "📘" if str(item.get("id", "")) == "fortify_lv1_book" else "📦"
	name_label.text = item_icon + " " + item.name
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = item.desc
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_vbox.add_child(desc_label)

	var action_vbox = VBoxContainer.new()
	action_vbox.add_theme_constant_override("separation", 6)
	action_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	action_vbox.size_flags_horizontal = Control.SIZE_SHRINK_END
	hbox.add_child(action_vbox)

	var cost_label = Label.new()
	cost_label.text = "💰 %d积分" % int(item.cost)
	cost_label.add_theme_font_size_override("font_size", 18)
	cost_label.add_theme_color_override("font_color", Color(1, 0.85, 0.0))
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_vbox.add_child(cost_label)

	var buy_btn = Button.new()
	buy_btn.text = "兑换"
	buy_btn.custom_minimum_size = Vector2(70, 40)

	var can_buy = false
	if xianmo_system and xianmo_system.xianmo_data:
		can_buy = xianmo_system.xianmo_data.total_score >= item.cost

	if can_buy:
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(0.2, 0.6, 0.3)
		btn_style.corner_radius_top_left = 8
		btn_style.corner_radius_top_right = 8
		btn_style.corner_radius_bottom_left = 8
		btn_style.corner_radius_bottom_right = 8
		buy_btn.add_theme_stylebox_override("normal", btn_style)
		buy_btn.pressed.connect( func(): _on_shop_buy(item, popup))
	else:
		buy_btn.disabled = true
		buy_btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

	action_vbox.add_child(buy_btn)

	return panel

func _on_shop_buy(item: Dictionary, popup: Control):
	if not game_manager or not game_manager.network:
		return
	if not game_manager.network.is_logged_in():
		_show_toast("未登录，无法兑换")
		return
	var op_id = "xianmo_shop_%s_%s" % [str(Time.get_unix_time_from_system()), str(randi())]
	_set_popup_buttons_disabled(popup, true)
	game_manager.network.xianmo_shop_buy_success.connect( func(data: Dictionary):
		if game_manager and data.has("saveData") and data.get("saveData") is Dictionary:
			game_manager.apply_cloud_save(data.get("saveData"), {
				"reward_inventory_slice": true, 
				"currency_slice": true, 
			})
			if data.has("saveRevision") and game_manager.has_method("_set_cloud_save_revision"):
				game_manager._set_cloud_save_revision(int(data.get("saveRevision", 0)))
		if xianmo_system and xianmo_system.xianmo_data:
			xianmo_system.xianmo_data.total_score = int(data.get("newTotalScore", xianmo_system.xianmo_data.total_score))
		_add_log("兑换成功！获得%s" % item.name)
		_update_ui()
		if is_instance_valid(popup):
			popup.queue_free()
		_show_shop_panel()
	, CONNECT_ONE_SHOT)
	game_manager.network.xianmo_shop_buy_failed.connect( func(error: String):
		_set_popup_buttons_disabled(popup, false)
		_show_toast(error)
	, CONNECT_ONE_SHOT)
	game_manager.network.xianmo_shop_buy(item.id, op_id)

func _show_toast(message: String):
	_show_styled_alert("提示", message)

func _set_popup_buttons_disabled(root: Node, disabled: bool) -> void :
	if not is_instance_valid(root):
		return
	if root is Button:
		(root as Button).disabled = disabled
	for child in root.get_children():
		_set_popup_buttons_disabled(child, disabled)

func _create_chest_panel() -> Control:
	var ui = _create_base_popup("📦 我的宝箱", 550, 640)
	var popup = ui.popup
	var content = ui.content
	var footer = ui.footer

	var chest_info = HBoxContainer.new()
	chest_info.alignment = BoxContainer.ALIGNMENT_CENTER
	chest_info.add_theme_constant_override("separation", 20)
	content.add_child(chest_info)

	var chest_types = [
		{"type": "bronze", "name": "青铜", "color": Color(0.8, 0.5, 0.2)}, 
		{"type": "silver", "name": "白银", "color": Color(0.75, 0.75, 0.8)}, 
		{"type": "gold", "name": "黄金", "color": Color(1, 0.85, 0.0)}
	]
	for chest in chest_types:
		var count = 0
		if game_manager and game_manager.xianmo_chest_manager:
			count = game_manager.xianmo_chest_manager.get_chest_count(chest.type)

		var chest_label = Label.new()
		chest_label.text = "%s: %d个" % [chest.name, int(count)]
		chest_label.add_theme_font_size_override("font_size", 20)
		chest_label.add_theme_color_override("font_color", chest.color)
		chest_info.add_child(chest_label)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)

	var items_container = VBoxContainer.new()
	items_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_container.add_theme_constant_override("separation", 8)
	scroll.add_child(items_container)

	for chest in chest_types:
		var count = 0
		if game_manager and game_manager.xianmo_chest_manager:
			count = game_manager.xianmo_chest_manager.get_chest_count(chest.type)

		if count > 0:
			var item_panel = _create_chest_item(chest, count, popup)
			items_container.add_child(item_panel)

	if items_container.get_child_count() == 0:
		var empty_label = Label.new()
		empty_label.text = "暂无宝箱，通过探险或积分兑换获取"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		items_container.add_child(empty_label)

	var close_btn = _create_close_button()
	close_btn.pressed.connect( func(): popup.queue_free())
	footer.add_child(close_btn)

	return popup

func _create_chest_item(chest: Dictionary, count: int, popup: Control) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 70)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.8)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = chest.color
	panel.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)

	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	var name_label = Label.new()
	name_label.text = "📦 %s宝箱" % chest.name
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", chest.color)
	info_vbox.add_child(name_label)

	var count_label = Label.new()
	count_label.text = "拥有: %d个" % int(count)
	count_label.add_theme_font_size_override("font_size", 16)
	count_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	info_vbox.add_child(count_label)

	var open_btn = Button.new()
	open_btn.text = "开启"
	open_btn.custom_minimum_size = Vector2(70, 40)
	open_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.6, 0.4, 0.2)
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.corner_radius_bottom_right = 8
	open_btn.add_theme_stylebox_override("normal", btn_style)
	open_btn.pressed.connect( func(): _on_chest_open(chest.type, popup))
	hbox.add_child(open_btn)

	if int(count) >= 2:
		var batch_btn = Button.new()
		batch_btn.text = "批量开启"
		batch_btn.custom_minimum_size = Vector2(90, 40)
		batch_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var batch_style = StyleBoxFlat.new()
		batch_style.bg_color = Color(0.45, 0.35, 0.15)
		batch_style.corner_radius_top_left = 8
		batch_style.corner_radius_top_right = 8
		batch_style.corner_radius_bottom_left = 8
		batch_style.corner_radius_bottom_right = 8
		batch_btn.add_theme_stylebox_override("normal", batch_style)
		batch_btn.pressed.connect( func(): _on_chest_open_batch(chest.type, popup))
		hbox.add_child(batch_btn)

	return panel

func _on_chest_open(chest_type: String, popup: Control):
	if not game_manager:
		return

	if game_manager.inventory_manager and game_manager.inventory_manager.pet_equipment_items.size() >= game_manager.inventory_manager.MAX_PET_EQUIPMENT_INVENTORY:
		_show_toast("宠物装备背包已满！请先整理背包")
		return

	if not game_manager.network:
		return

	_pending_chest_popup = popup
	_pending_open_chest_type = chest_type
	_pending_open_chest_count = 1
	game_manager.network.xianmo_chest_open_success.connect(_on_chest_open_success, CONNECT_ONE_SHOT)
	game_manager.network.xianmo_chest_open_failed.connect(_on_chest_open_failed, CONNECT_ONE_SHOT)
	game_manager.network.xianmo_open_chest(chest_type)

func _on_chest_open_batch(chest_type: String, popup: Control):
	if not game_manager:
		return
	if not game_manager.network:
		return

	var owned: = 0
	if game_manager.xianmo_chest_manager:
		owned = game_manager.xianmo_chest_manager.get_chest_count(chest_type)
	var open_n: = mini(owned, 10)
	if open_n < 1:
		_show_toast("没有此类型的宝箱")
		return

	if game_manager.inventory_manager:
		var used: int = game_manager.inventory_manager.pet_equipment_items.size()
		var cap: int = game_manager.inventory_manager.MAX_PET_EQUIPMENT_INVENTORY
		var free_slots: int = maxi(0, cap - used)
		if free_slots < open_n:
			_show_toast("宠物装备背包空间不足！请先整理背包（需要%d空位）" % open_n)
			return

	_pending_chest_popup = popup
	_pending_open_chest_type = chest_type
	_pending_open_chest_count = open_n
	var op_id: = "xianmo_chest_open_batch_%s_%s_%s_%s" % [
		str(game_manager.network.user_id), 
		chest_type, 
		str(Time.get_unix_time_from_system()), 
		str(Time.get_ticks_usec())
	]
	game_manager.network.xianmo_chest_open_batch_success.connect(_on_chest_open_batch_success, CONNECT_ONE_SHOT)
	game_manager.network.xianmo_chest_open_batch_failed.connect(_on_chest_open_batch_failed, CONNECT_ONE_SHOT)
	game_manager.network.xianmo_open_chest_batch(chest_type, open_n, op_id)

func _on_chest_open_success(data: Dictionary):
	if _pending_chest_popup:
		_pending_chest_popup.queue_free()
		_pending_chest_popup = null

	var equipment_data = data.get("equipment", {})
	if equipment_data.is_empty():
		_pending_open_chest_type = ""
		_pending_open_chest_count = 0
		_show_toast("开启宝箱失败：数据错误")
		return

	var opened_bucket = _pending_open_chest_type
	if opened_bucket.is_empty():
		opened_bucket = str(equipment_data.get("quality", equipment_data.get("chest_type", "bronze")))

	if game_manager and data.has("saveData") and data.get("saveData") is Dictionary:
		game_manager.apply_cloud_save(data.get("saveData"), {
			"reconcile_treasure_chests": false, 
			"reward_inventory_slice": true, 
			"authoritative_equipment_inventory": true, 
		})
		if data.has("saveRevision") and game_manager.has_method("_set_cloud_save_revision"):
			game_manager._set_cloud_save_revision(int(data.get("saveRevision", 0)))

	if game_manager and game_manager.xianmo_chest_manager and opened_bucket != "":
		if game_manager.xianmo_chest_manager.chests.has(opened_bucket):
			game_manager.xianmo_chest_manager.chests[opened_bucket] = max(0, int(game_manager.xianmo_chest_manager.chests[opened_bucket]) - 1)
			game_manager.xianmo_chest_manager.chest_opened.emit(opened_bucket, equipment_data)
			if game_manager.xianmo_system and game_manager.xianmo_system.has_method("load_from_server"):
				game_manager.xianmo_system.load_from_server()
	_pending_open_chest_type = ""
	_pending_open_chest_count = 0

	_add_log("开启宝箱成功！")
	_update_ui()
	_show_chest_panel()
	_show_chest_result_from_dict(equipment_data)

func _on_chest_open_failed(error: String):
	_pending_open_chest_type = ""
	_pending_open_chest_count = 0
	_show_toast("开启宝箱失败：%s" % error)

func _on_chest_open_batch_success(data: Dictionary):
	if _pending_chest_popup:
		_pending_chest_popup.queue_free()
		_pending_chest_popup = null

	if data.get("duplicate", false) == true:
		_pending_open_chest_type = ""
		_pending_open_chest_count = 0
		if game_manager and data.has("saveData") and data.get("saveData") is Dictionary:
			game_manager.apply_cloud_save(data.get("saveData"), {
				"reconcile_treasure_chests": false, 
				"reward_inventory_slice": true, 
				"authoritative_equipment_inventory": true, 
			})
			if data.has("saveRevision") and game_manager.has_method("_set_cloud_save_revision"):
				game_manager._set_cloud_save_revision(int(data.get("saveRevision", 0)))
		_show_toast("操作已处理，请刷新后查看")
		_update_ui()
		_show_chest_panel()
		return

	var equipments = data.get("equipments", [])
	if not (equipments is Array) or equipments.is_empty():
		_pending_open_chest_type = ""
		_pending_open_chest_count = 0
		_show_toast("批量开启失败：数据错误")
		return

	var opened_bucket = _pending_open_chest_type
	var opened_n = int(data.get("openedCount", _pending_open_chest_count))
	if opened_n <= 0:
		opened_n = equipments.size()

	if game_manager and data.has("saveData") and data.get("saveData") is Dictionary:
		game_manager.apply_cloud_save(data.get("saveData"), {
			"reconcile_treasure_chests": false, 
			"reward_inventory_slice": true, 
			"authoritative_equipment_inventory": true, 
		})
		if data.has("saveRevision") and game_manager.has_method("_set_cloud_save_revision"):
			game_manager._set_cloud_save_revision(int(data.get("saveRevision", 0)))

	if game_manager and game_manager.xianmo_chest_manager and opened_bucket != "":
		if game_manager.xianmo_chest_manager.chests.has(opened_bucket):
			game_manager.xianmo_chest_manager.chests[opened_bucket] = max(0, int(game_manager.xianmo_chest_manager.chests[opened_bucket]) - opened_n)
			if equipments.size() > 0 and equipments[0] is Dictionary:
				game_manager.xianmo_chest_manager.chest_opened.emit(opened_bucket, equipments[0])
			if game_manager.xianmo_system and game_manager.xianmo_system.has_method("load_from_server"):
				game_manager.xianmo_system.load_from_server()
	_pending_open_chest_type = ""
	_pending_open_chest_count = 0

	_add_log("批量开启宝箱成功！获得%d件装备" % equipments.size())
	_update_ui()
	_show_chest_panel()
	_show_chest_batch_result(equipments)

func _on_chest_open_batch_failed(error: String):
	_pending_open_chest_type = ""
	_pending_open_chest_count = 0
	_show_toast("批量开启失败：%s" % error)

func _show_chest_result_from_dict(equipment_data: Dictionary):
	var ui = _create_base_popup("🎁 获得装备", 400, 300)
	var popup = ui.popup
	var content = ui.content
	var footer = ui.footer

	var name_label = Label.new()
	var slot_names = {"weapon": "武器", "armor": "防具", "accessory": "饰品", "boots": "靴子", "helmet": "头盔"}
	var chest_names = {"bronze": "青铜", "silver": "银月", "gold": "金鳞"}
	var slot = str(equipment_data.get("slot", ""))
	var quality = str(equipment_data.get("quality", equipment_data.get("chest_type", "bronze")))
	var slot_name = slot_names.get(slot, "未知")
	var chest_name = chest_names.get(quality, "青铜")
	var equip_name = str(equipment_data.get("equip_name", equipment_data.get("name", "%s%s" % [chest_name, slot_name])))
	name_label.text = equip_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(1, 0.85, 0.0))
	content.add_child(name_label)

	var desc_label = Label.new()
	var stats = []
	var attack_val = equipment_data.get("attack", 0)
	var defense_val = equipment_data.get("defense", 0)
	var agility_val = equipment_data.get("agility", 0)
	var hp_val = equipment_data.get("hp", 0)
	if attack_val > 0:
		stats.append("攻击+%d" % int(attack_val))
	if defense_val > 0:
		stats.append("防御+%d" % int(defense_val))
	if agility_val > 0:
		stats.append("敏捷+%d" % int(agility_val))
	if hp_val > 0:
		stats.append("生命+%d" % int(hp_val))
	desc_label.text = "\n".join(stats)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 18)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(desc_label)

	var close_btn = Button.new()
	close_btn.text = "确定"
	close_btn.pressed.connect( func(): popup.queue_free())
	footer.add_child(close_btn)

	add_child(popup)

func _format_chest_equipment_line(equipment_data: Dictionary) -> String:
	var slot_names = {"weapon": "武器", "armor": "防具", "accessory": "饰品", "boots": "靴子", "helmet": "头盔"}
	var chest_names = {"bronze": "青铜", "silver": "银月", "gold": "金鳞"}
	var slot = str(equipment_data.get("slot", ""))
	var quality = str(equipment_data.get("quality", equipment_data.get("chest_type", "bronze")))
	var slot_name = slot_names.get(slot, "未知")
	var chest_name = chest_names.get(quality, "青铜")
	var equip_name = str(equipment_data.get("equip_name", equipment_data.get("name", "%s%s" % [chest_name, slot_name])))
	var stats: Array = []
	var attack_val = equipment_data.get("attack", 0)
	var defense_val = equipment_data.get("defense", 0)
	var agility_val = equipment_data.get("agility", 0)
	var hp_val = equipment_data.get("hp", 0)
	if attack_val > 0:
		stats.append("攻+%d" % int(attack_val))
	if defense_val > 0:
		stats.append("防+%d" % int(defense_val))
	if agility_val > 0:
		stats.append("敏+%d" % int(agility_val))
	if hp_val > 0:
		stats.append("血+%d" % int(hp_val))
	if stats.is_empty():
		return equip_name
	return "%s（%s）" % [equip_name, " ".join(stats)]

func _show_chest_batch_result(equipments: Array):
	var ui = _create_base_popup("🎁 批量获得装备", 420, 420)
	var popup = ui.popup
	var content = ui.content
	var footer = ui.footer

	var summary = Label.new()
	summary.text = "共获得 %d 件装备" % equipments.size()
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.add_theme_font_size_override("font_size", 18)
	summary.add_theme_color_override("font_color", Color(1, 0.85, 0.0))
	content.add_child(summary)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 260)
	content.add_child(scroll)

	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)

	for item in equipments:
		if not (item is Dictionary):
			continue
		var row = Label.new()
		row.text = _format_chest_equipment_line(item)
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_theme_font_size_override("font_size", 16)
		row.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		list.add_child(row)

	var close_btn = Button.new()
	close_btn.text = "确定"
	close_btn.pressed.connect( func(): popup.queue_free())
	footer.add_child(close_btn)

	add_child(popup)

func _show_chest_result(equipment):
	if not equipment:
		return

	var ui = _create_base_popup("🎁 获得装备", 400, 300)
	var popup = ui.popup
	var content = ui.content
	var footer = ui.footer

	var name_label = Label.new()
	name_label.text = equipment.get_full_name()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(1, 0.85, 0.0))
	content.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = equipment.get_stat_description()
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 18)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(desc_label)

	var close_btn = _create_close_button("收  下")
	close_btn.pressed.connect( func(): popup.queue_free())
	footer.add_child(close_btn)

	add_child(popup)

func _create_treasure_panel() -> Control:
	var ui = _create_base_popup("🗺️ 藏宝图", 550, 640)
	var popup = ui.popup
	var content = ui.content
	var footer = ui.footer

	var fragments = 0
	if xianmo_system and xianmo_system.xianmo_data:
		fragments = xianmo_system.xianmo_data.treasure_fragments

	var fragment_label = Label.new()
	fragment_label.text = "🗺️ 藏宝图残片: %d / 10" % int(fragments)
	fragment_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fragment_label.add_theme_font_size_override("font_size", 22)
	fragment_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.5))
	content.add_child(fragment_label)

	var progress = ProgressBar.new()
	progress.custom_minimum_size = Vector2(0, 20)
	progress.max_value = 10
	progress.value = int(fragments)
	progress.show_percentage = false
	content.add_child(progress)

	var info_label = Label.new()
	info_label.text = "收集10个残片可兑换藏宝图\n奖励概率: 60%得1亿金币, 30%得5亿, 10%得10亿"
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.add_theme_font_size_override("font_size", 16)
	info_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	content.add_child(info_label)

	var exchange_btn = Button.new()
	exchange_btn.text = "兑换藏宝图"
	exchange_btn.custom_minimum_size = Vector2(180, 50)
	exchange_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var can_exchange = fragments >= 10
	if can_exchange:
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(0.6, 0.4, 0.2)
		btn_style.corner_radius_top_left = 10
		btn_style.corner_radius_top_right = 10
		btn_style.corner_radius_bottom_left = 10
		btn_style.corner_radius_bottom_right = 10
		exchange_btn.add_theme_stylebox_override("normal", btn_style)
		exchange_btn.pressed.connect( func(): _on_treasure_exchange(popup))
	else:
		exchange_btn.disabled = true
		exchange_btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

	content.add_child(exchange_btn)

	var close_btn = _create_close_button()
	close_btn.pressed.connect( func(): popup.queue_free())
	footer.add_child(close_btn)

	return popup

func _on_treasure_exchange(popup: Control):
	if not game_manager or not game_manager.network:
		return
	if not game_manager.network.is_logged_in():
		_show_toast("未登录，无法兑换")
		return
	var op_id = "xianmo_treasure_%s_%s" % [str(Time.get_unix_time_from_system()), str(randi())]
	_set_popup_buttons_disabled(popup, true)
	game_manager.network.xianmo_treasure_exchange_success.connect( func(data: Dictionary):
		var gold = int(data.get("goldReward", 0))
		if game_manager and data.has("saveData") and data.get("saveData") is Dictionary:
			game_manager.apply_cloud_save(data.get("saveData"), {
				"reward_inventory_slice": true, 
				"currency_slice": true, 
			})
			if data.has("saveRevision") and game_manager.has_method("_set_cloud_save_revision"):
				game_manager._set_cloud_save_revision(int(data.get("saveRevision", 0)))
		if xianmo_system and xianmo_system.xianmo_data:
			xianmo_system.xianmo_data.treasure_fragments = int(data.get("remainingFragments", xianmo_system.xianmo_data.treasure_fragments))
		_add_log("藏宝图兑换成功！获得%d亿金币" % (gold / 100000000))
		_update_ui()
		if is_instance_valid(popup):
			popup.queue_free()
		_show_treasure_result(gold)
	, CONNECT_ONE_SHOT)
	game_manager.network.xianmo_treasure_exchange_failed.connect( func(error: String):
		_set_popup_buttons_disabled(popup, false)
		_show_toast(error)
	, CONNECT_ONE_SHOT)
	game_manager.network.xianmo_treasure_exchange(op_id)

func _show_treasure_result(gold: int):
	var ui = _create_base_popup("💰 发现宝藏！", 400, 280)
	var popup = ui.popup
	var content = ui.content
	var footer = ui.footer

	var gold_label = Label.new()
	gold_label.text = "获得 %d 亿金币！" % (int(gold) / 100000000)
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_label.add_theme_font_size_override("font_size", 24)
	gold_label.add_theme_color_override("font_color", Color(1, 0.85, 0.0))
	content.add_child(gold_label)

	var close_btn = _create_close_button("太棒了！")
	close_btn.pressed.connect( func(): popup.queue_free())
	footer.add_child(close_btn)

	add_child(popup)

func _create_title_panel() -> Control:
	var ui = _create_base_popup("🎖️ 称号系统", 550, 640)
	var popup = ui.popup
	var content = ui.content
	var footer = ui.footer

	var titles = []
	var active_title_id = ""
	if game_manager and game_manager.player:
		titles = game_manager.player.titles
		active_title_id = game_manager.player.active_title_id

	var active_info = Label.new()
	var active_title = null
	for title in titles:
		if title is TitleData and title.title_id == active_title_id:
			active_title = title
			break

	if active_title:
		active_info.text = "当前称号: [%s]" % active_title.title_name
		active_info.add_theme_color_override("font_color", Color(0.9, 0.5, 1.0))
	else:
		active_info.text = "当前称号: 无"
		active_info.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	active_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	active_info.add_theme_font_size_override("font_size", 20)
	content.add_child(active_info)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)

	var items_container = VBoxContainer.new()
	items_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_container.add_theme_constant_override("separation", 8)
	scroll.add_child(items_container)

	var valid_titles = []
	for title in titles:
		if title is TitleData and not title.is_expired():
			valid_titles.append(title)

	for title in valid_titles:
		var item_panel = _create_title_item(title, title.title_id == active_title_id, popup)
		items_container.add_child(item_panel)

	if valid_titles.is_empty():
		var empty_label = Label.new()
		empty_label.text = "暂无称号，参与仙魔战场周结算可获得称号"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		items_container.add_child(empty_label)

	var close_btn = _create_close_button()
	close_btn.pressed.connect( func(): popup.queue_free())
	footer.add_child(close_btn)

	return popup

func _create_title_item(title, is_active: bool, popup: Control) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 80)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.8) if not is_active else Color(0.2, 0.15, 0.25, 0.9)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 2 if is_active else 1
	style.border_width_right = 2 if is_active else 1
	style.border_width_top = 2 if is_active else 1
	style.border_width_bottom = 2 if is_active else 1
	style.border_color = Color(0.9, 0.5, 1.0) if is_active else Color(0.3, 0.3, 0.4)
	panel.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)

	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 3)
	hbox.add_child(info_vbox)

	var name_label = Label.new()
	name_label.text = "🎖️ " + title.title_name
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.5, 1.0))
	info_vbox.add_child(name_label)

	var bonus_text = ""
	if title.attack_bonus > 0:
		bonus_text += "攻击+%d " % int(title.attack_bonus)
	if title.defense_bonus > 0:
		bonus_text += "防御+%d " % int(title.defense_bonus)
	if title.agility_bonus > 0:
		bonus_text += "敏捷+%d " % int(title.agility_bonus)
	if title.hp_bonus > 0:
		bonus_text += "生命+%d" % int(title.hp_bonus)

	var bonus_label = Label.new()
	bonus_label.text = bonus_text if bonus_text else "无属性加成"
	bonus_label.add_theme_font_size_override("font_size", 16)
	bonus_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	info_vbox.add_child(bonus_label)

	var time_label = Label.new()
	time_label.text = "有效期: " + title.get_remaining_time_string()
	time_label.add_theme_font_size_override("font_size", 14)
	time_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	info_vbox.add_child(time_label)

	if not is_active:
		var use_btn = Button.new()
		use_btn.text = "使用"
		use_btn.custom_minimum_size = Vector2(60, 40)
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(0.5, 0.3, 0.7)
		btn_style.corner_radius_top_left = 8
		btn_style.corner_radius_top_right = 8
		btn_style.corner_radius_bottom_left = 8
		btn_style.corner_radius_bottom_right = 8
		use_btn.add_theme_stylebox_override("normal", btn_style)
		use_btn.pressed.connect( func(): _on_title_use(title.title_id, popup))
		hbox.add_child(use_btn)
	else:
		var unequip_btn = Button.new()
		unequip_btn.text = "卸下"
		unequip_btn.custom_minimum_size = Vector2(60, 40)
		var unequip_style = StyleBoxFlat.new()
		unequip_style.bg_color = Color(0.45, 0.35, 0.4)
		unequip_style.corner_radius_top_left = 8
		unequip_style.corner_radius_top_right = 8
		unequip_style.corner_radius_bottom_left = 8
		unequip_style.corner_radius_bottom_right = 8
		unequip_btn.add_theme_stylebox_override("normal", unequip_style)
		unequip_btn.pressed.connect( func(): _on_title_unequip(popup))
		hbox.add_child(unequip_btn)

	return panel

func _refresh_title_panel_after_change(popup: Control) -> void :
	_update_ui()
	if is_instance_valid(popup):
		popup.queue_free()
	_show_title_panel()

func _on_title_use(title_id: String, popup: Control):
	if not game_manager or not game_manager.title_manager:
		return
	if not game_manager.network or not game_manager.network.is_logged_in():
		var local_ok = game_manager.title_manager.activate_title(title_id)
		if local_ok:
			_add_log("成功激活称号！")
			_refresh_title_panel_after_change(popup)
		else:
			_show_toast("激活称号失败")
		return

	var title = null
	if game_manager.player:
		for t in game_manager.player.titles:
			if t != null and str(t.title_id) == title_id:
				title = t
				break
	var source: = "xianmo"
	if title != null:
		source = str(title.source)

	var on_success: = func():
		game_manager.title_manager.apply_active_title_id(title_id)
		_add_log("成功激活称号！")
		_refresh_title_panel_after_change(popup)

	var on_fail: = func():
		_show_toast("激活称号失败")

	if source == "gang":
		if not game_manager.gang_manager:
			on_fail.call()
			return
		game_manager.gang_manager.title_activated.connect( func(data: Dictionary):
			if not bool(data.get("success", false)):
				on_fail.call()
				return
			on_success.call()
		, CONNECT_ONE_SHOT)
	elif source == "arena":
		game_manager.network.arena_title_activated.connect( func(data: Dictionary):
			if not bool(data.get("success", false)):
				on_fail.call()
				return
			on_success.call()
		, CONNECT_ONE_SHOT)
	else:
		game_manager.network.xianmo_title_activated.connect( func(data: Dictionary):
			if not bool(data.get("success", false)):
				on_fail.call()
				return
			on_success.call()
		, CONNECT_ONE_SHOT)

	var request_sent = game_manager.title_manager.activate_title_server(title_id)
	if not request_sent:
		_show_toast("激活称号失败")

func _on_title_unequip(popup: Control):
	if not game_manager or not game_manager.title_manager:
		return
	if not game_manager.network or not game_manager.network.is_logged_in():
		game_manager.title_manager.deactivate_title()
		_add_log("已卸下称号")
		_refresh_title_panel_after_change(popup)
		return
	game_manager.network.xianmo_title_deactivated.connect( func(data: Dictionary):
		if not bool(data.get("success", false)):
			_show_toast("卸下称号失败")
			return
		game_manager.title_manager.deactivate_title()
		if game_manager:
			game_manager.call_deferred("save_game", true)
		_add_log("已卸下称号")
		_refresh_title_panel_after_change(popup)
	, CONNECT_ONE_SHOT)
	if not game_manager.title_manager.deactivate_title_server():
		_show_toast("卸下称号失败")
