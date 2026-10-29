extends Control

signal faction_selected(faction: String)
signal cancelled

var game_manager = null
var xianmo_system = null

@onready var xian_panel = $Panel / VBoxContainer / Content / VBoxContainer / FactionContainer / XianPanel
@onready var mo_panel = $Panel / VBoxContainer / Content / VBoxContainer / FactionContainer / MoPanel
@onready var xian_count_label = $Panel / VBoxContainer / Content / VBoxContainer / FactionContainer / XianPanel / VBox / VBoxContainer / CountLabel
@onready var xian_score_label = $Panel / VBoxContainer / Content / VBoxContainer / FactionContainer / XianPanel / VBox / VBoxContainer / ScoreLabel
@onready var mo_count_label = $Panel / VBoxContainer / Content / VBoxContainer / FactionContainer / MoPanel / VBox / VBoxContainer / CountLabel
@onready var mo_score_label = $Panel / VBoxContainer / Content / VBoxContainer / FactionContainer / MoPanel / VBox / VBoxContainer / ScoreLabel
@onready var xian_join_btn = $Panel / VBoxContainer / Content / VBoxContainer / FactionContainer / XianPanel / VBox / VBoxContainer / JoinBtn
@onready var mo_join_btn = $Panel / VBoxContainer / Content / VBoxContainer / FactionContainer / MoPanel / VBox / VBoxContainer / JoinBtn
@onready var auto_assign_btn = $Panel / VBoxContainer / Content / VBoxContainer / AutoAssignContainer / AutoAssignBtn
@onready var cancel_btn = $Panel / VBoxContainer / Footer / CancelBtn
@onready var background = $Background

const BALANCE_THRESHOLD = 3

func _ready():
	_setup_signals()
	_setup_styles()
	_play_enter_animation()

func _setup_signals():
	if xian_join_btn:
		xian_join_btn.pressed.connect(_on_xian_join_pressed)
	if mo_join_btn:
		mo_join_btn.pressed.connect(_on_mo_join_pressed)
	if auto_assign_btn:
		auto_assign_btn.pressed.connect(_on_auto_assign_pressed)
	if cancel_btn:
		cancel_btn.pressed.connect(_on_cancel_pressed)
	if background:
		background.gui_input.connect(_on_background_input)

func _setup_styles():
	if xian_panel:
		var style = _create_faction_style(Color(0.2, 0.4, 0.8, 0.4), Color(0.3, 0.5, 0.9))
		xian_panel.add_theme_stylebox_override("panel", style)
	if mo_panel:
		var style = _create_faction_style(Color(0.6, 0.2, 0.2, 0.4), Color(0.7, 0.3, 0.3))
		mo_panel.add_theme_stylebox_override("panel", style)

	_setup_button_styles()

func _setup_button_styles():
	if xian_join_btn:
		xian_join_btn.custom_minimum_size = Vector2(0, 50)
		xian_join_btn.add_theme_font_size_override("font_size", 18)
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(0.2, 0.5, 0.8)
		btn_style.border_width_left = 2
		btn_style.border_width_right = 2
		btn_style.border_width_top = 2
		btn_style.border_width_bottom = 2
		btn_style.border_color = Color(0.4, 0.7, 1.0)
		btn_style.corner_radius_top_left = 10
		btn_style.corner_radius_top_right = 10
		btn_style.corner_radius_bottom_left = 10
		btn_style.corner_radius_bottom_right = 10
		xian_join_btn.add_theme_stylebox_override("normal", btn_style)
		xian_join_btn.add_theme_color_override("font_color", Color(1, 1, 1))

		var hover_style = btn_style.duplicate()
		hover_style.bg_color = Color(0.3, 0.6, 0.9)
		xian_join_btn.add_theme_stylebox_override("hover", hover_style)

		var pressed_style = btn_style.duplicate()
		pressed_style.bg_color = Color(0.15, 0.4, 0.7)
		xian_join_btn.add_theme_stylebox_override("pressed", pressed_style)

	if mo_join_btn:
		mo_join_btn.custom_minimum_size = Vector2(0, 50)
		mo_join_btn.add_theme_font_size_override("font_size", 18)
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(0.7, 0.25, 0.25)
		btn_style.border_width_left = 2
		btn_style.border_width_right = 2
		btn_style.border_width_top = 2
		btn_style.border_width_bottom = 2
		btn_style.border_color = Color(0.9, 0.4, 0.4)
		btn_style.corner_radius_top_left = 10
		btn_style.corner_radius_top_right = 10
		btn_style.corner_radius_bottom_left = 10
		btn_style.corner_radius_bottom_right = 10
		mo_join_btn.add_theme_stylebox_override("normal", btn_style)
		mo_join_btn.add_theme_color_override("font_color", Color(1, 1, 1))

		var hover_style = btn_style.duplicate()
		hover_style.bg_color = Color(0.8, 0.35, 0.35)
		mo_join_btn.add_theme_stylebox_override("hover", hover_style)

		var pressed_style = btn_style.duplicate()
		pressed_style.bg_color = Color(0.6, 0.2, 0.2)
		mo_join_btn.add_theme_stylebox_override("pressed", pressed_style)

	if auto_assign_btn:
		auto_assign_btn.custom_minimum_size = Vector2(250, 45)
		auto_assign_btn.add_theme_font_size_override("font_size", 16)
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(0.4, 0.5, 0.2)
		btn_style.border_width_left = 2
		btn_style.border_width_right = 2
		btn_style.border_width_top = 2
		btn_style.border_width_bottom = 2
		btn_style.border_color = Color(0.6, 0.7, 0.3)
		btn_style.corner_radius_top_left = 10
		btn_style.corner_radius_top_right = 10
		btn_style.corner_radius_bottom_left = 10
		btn_style.corner_radius_bottom_right = 10
		auto_assign_btn.add_theme_stylebox_override("normal", btn_style)
		auto_assign_btn.add_theme_color_override("font_color", Color(1, 1, 1))

		var hover_style = btn_style.duplicate()
		hover_style.bg_color = Color(0.5, 0.6, 0.25)
		auto_assign_btn.add_theme_stylebox_override("hover", hover_style)

		var pressed_style = btn_style.duplicate()
		pressed_style.bg_color = Color(0.35, 0.45, 0.18)
		auto_assign_btn.add_theme_stylebox_override("pressed", pressed_style)

func _create_faction_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
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
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 8
	style.shadow_offset = Vector2(2, 4)
	return style

func _play_enter_animation():
	var panel = $Panel
	if panel:
		panel.modulate.a = 0
		panel.scale = Vector2(0.8, 0.8)
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(panel, "modulate:a", 1.0, 0.3)
		tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _play_exit_animation(callback: Callable):
	var panel = $Panel
	if panel:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(panel, "modulate:a", 0.0, 0.2)
		tween.tween_property(panel, "scale", Vector2(0.8, 0.8), 0.2)
		tween.tween_callback(callback).set_delay(0.2)

func set_game_manager(gm):
	game_manager = gm
	if game_manager:
		xianmo_system = game_manager.xianmo_system
		if xianmo_system:
			if xianmo_system.faction_assigned.is_connected(_on_faction_assigned):
				xianmo_system.faction_assigned.disconnect(_on_faction_assigned)
			if xianmo_system.join_failed.is_connected(_on_join_failed):
				xianmo_system.join_failed.disconnect(_on_join_failed)
			xianmo_system.faction_assigned.connect(_on_faction_assigned)
			xianmo_system.join_failed.connect(_on_join_failed)
		_update_faction_info()

func _on_faction_assigned(faction: String):
	var loading_popup = get_node_or_null("LoadingPopup")
	if loading_popup:
		loading_popup.queue_free()
	_play_exit_animation( func():
		faction_selected.emit(faction)
		queue_free()
	)

func _on_join_failed(error: String):
	var loading_popup = get_node_or_null("LoadingPopup")
	if loading_popup:
		loading_popup.queue_free()
	_show_error(error)

func _update_faction_info():
	if not xianmo_system:
		return

	var comparison = xianmo_system.get_faction_comparison()

	if xian_count_label:
		xian_count_label.text = "当前人数: %d" % comparison.xian.count
	if xian_score_label:
		xian_score_label.text = "阵营积分: %d" % comparison.xian.total_score

	if mo_count_label:
		mo_count_label.text = "当前人数: %d" % comparison.mo.count
	if mo_score_label:
		mo_score_label.text = "阵营积分: %d" % comparison.mo.total_score

	_update_balance_hint(comparison)

func _update_balance_hint(comparison: Dictionary):
	var hint_label = $Panel / VBoxContainer / Content / VBoxContainer / BalanceHint
	if not hint_label:
		return

	var xian_count = comparison.xian.count
	var mo_count = comparison.mo.count

	if xian_count == 0 and mo_count == 0:
		hint_label.text = "💡 本周对决刚刚开始，选择任意阵营均可"
	elif abs(xian_count - mo_count) <= 2:
		hint_label.text = "💡 阵营人数接近平衡，推荐选择自动分配"
	elif xian_count > mo_count:
		hint_label.text = "💡 仙道人数较多，加入魔道可获得更多挑战"
	else:
		hint_label.text = "💡 魔道人数较多，加入仙道可获得更多挑战"

func _on_xian_join_pressed():
	_join_faction("xian")

func _on_mo_join_pressed():
	_join_faction("mo")

func _on_auto_assign_pressed():
	if not xianmo_system:
		return

	var result = xianmo_system.join_xianmo()
	if result.success:
		_play_exit_animation( func():
			faction_selected.emit(result.faction)
			queue_free()
		)
	elif result.message == "正在加入...":
		_show_loading(result.message)
	else:
		_show_error(result.message)

func _join_faction(faction: String):
	if not xianmo_system:
		return

	var comparison = xianmo_system.get_faction_comparison()
	var xian_count = comparison.xian.count
	var mo_count = comparison.mo.count

	var actual_faction = faction
	var need_balance = false

	if faction == "xian" and xian_count - mo_count >= BALANCE_THRESHOLD:
		actual_faction = "mo"
		need_balance = true
	elif faction == "mo" and mo_count - xian_count >= BALANCE_THRESHOLD:
		actual_faction = "xian"
		need_balance = true

	if need_balance:
		_show_balance_dialog(faction, actual_faction)
	else:
		_do_join_faction(actual_faction)

func _show_balance_dialog(requested_faction: String, actual_faction: String):
	var requested_name = "仙道" if requested_faction == "xian" else "魔道"
	var actual_name = "仙道" if actual_faction == "xian" else "魔道"

	var popup = Control.new()
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.5)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	popup.add_child(bg)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 320)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -200
	panel.offset_top = -160
	panel.offset_right = 200
	panel.offset_bottom = 160
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
	vbox.add_theme_constant_override("separation", 15)
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
	title_label.text = "阵营分配"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.85, 1.0))
	header.add_child(title_label)

	var content = VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	vbox.add_child(content)

	var msg_label = Label.new()
	msg_label.text = "虽然你很想加入%s，但是%s并不想让你加入，你只好转投%s。" % [requested_name, requested_name, actual_name]
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_label.add_theme_font_size_override("font_size", 14)
	content.add_child(msg_label)

	var footer = VBoxContainer.new()
	footer.custom_minimum_size = Vector2(0, 70)
	vbox.add_child(footer)

	var confirm_btn = Button.new()
	confirm_btn.text = "确  定"
	confirm_btn.custom_minimum_size = Vector2(200, 50)
	confirm_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	confirm_btn.add_theme_font_size_override("font_size", 18)

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
	confirm_btn.add_theme_stylebox_override("normal", btn_style)

	var hover_style = btn_style.duplicate()
	hover_style.bg_color = Color(0.4, 0.7, 1.0)
	confirm_btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = btn_style.duplicate()
	pressed_style.bg_color = Color(0.2, 0.5, 0.8)
	confirm_btn.add_theme_stylebox_override("pressed", pressed_style)

	confirm_btn.add_theme_color_override("font_color", Color(1, 1, 1))

	confirm_btn.pressed.connect( func():
		_do_join_faction(actual_faction)
		popup.queue_free()
	)

	footer.add_child(confirm_btn)

	add_child(popup)

func _do_join_faction(faction: String):
	if not xianmo_system:
		return

	var result = xianmo_system.join_faction(faction)
	if result.success:
		_play_exit_animation( func():
			faction_selected.emit(faction)
			queue_free()
		)
	elif result.message == "正在加入...":
		_show_loading(result.message)
	else:
		_show_error(result.message)

func _show_loading(message: String):
	var popup = Control.new()
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.name = "LoadingPopup"

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.5)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	popup.add_child(bg)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 120)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -150
	panel.offset_top = -60
	panel.offset_right = 150
	panel.offset_bottom = 60
	popup.add_child(panel)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.18, 0.95)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.6, 0.8)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var loading_label = Label.new()
	loading_label.text = "⏳ " + message
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.add_theme_font_size_override("font_size", 18)
	loading_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	vbox.add_child(loading_label)

	add_child(popup)

func _show_error(message: String):
	print("[XianMoFactionSelect] Error: ", message)
	var popup = Control.new()
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.5)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	popup.add_child(bg)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(350, 260)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -175
	panel.offset_top = -130
	panel.offset_right = 175
	panel.offset_bottom = 130
	popup.add_child(panel)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.18, 0.95)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.8, 0.3, 0.3)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var icon_label = Label.new()
	icon_label.text = "⚠️"
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 32)
	vbox.add_child(icon_label)

	var msg_label = Label.new()
	msg_label.text = message
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	msg_label.add_theme_font_size_override("font_size", 18)
	msg_label.add_theme_color_override("font_color", Color(1, 0.8, 0.8))
	vbox.add_child(msg_label)

	var confirm_btn = Button.new()
	confirm_btn.text = "确定"
	confirm_btn.custom_minimum_size = Vector2(100, 35)
	confirm_btn.pressed.connect( func():
		popup.queue_free()
	)
	vbox.add_child(confirm_btn)

	add_child(popup)

func _on_cancel_pressed():
	_play_exit_animation( func():
		cancelled.emit()
		queue_free()
	)

func _on_background_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_cancel_pressed()
