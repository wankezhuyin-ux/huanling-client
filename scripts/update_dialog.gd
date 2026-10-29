extends Control

signal download_requested
signal quit_requested
signal update_completed

var update_info: Dictionary = {}

var window: Window
var progress_bar: ProgressBar
var status_label: Label
var update_btn: Button
var quit_btn: Button
var btn_container: HBoxContainer
var is_downloading: bool = false


func setup(info: Dictionary) -> void :
	update_info = info.duplicate(true)
	_build_ui()


func _build_ui() -> void :
	if window:
		window.queue_free()

	window = Window.new()
	window.title = ""
	window.size = Vector2(520, 480)
	window.borderless = true
	window.transparent = true
	window.unresizable = true
	window.close_requested.connect(_on_close_requested)
	add_child(window)

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.066, 0.074, 0.074, 0.98)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.788, 0.635, 0.294, 1)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", panel_style)
	window.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 30
	vbox.offset_right = -30
	vbox.offset_top = 25
	vbox.offset_bottom = -25
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "发现新版本"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	vbox.add_child(title)

	var patch_version: = str(update_info.get("patch_version", update_info.get("version", "1.0.0")))
	var version_label = Label.new()
	version_label.text = "最新版本: v" + patch_version
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version_label.add_theme_font_size_override("font_size", 18)
	version_label.add_theme_color_override("font_color", Color(0.894, 0.770, 0.467))
	vbox.add_child(version_label)

	var size_label = Label.new()
	var size_mb = float(update_info.get("size", 0)) / (1024.0 * 1024.0)
	size_label.text = "更新大小: %.2f MB" % size_mb
	size_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	size_label.add_theme_font_size_override("font_size", 16)
	size_label.add_theme_color_override("font_color", Color(0.788, 0.635, 0.294))
	vbox.add_child(size_label)

	var notes_title = Label.new()
	notes_title.text = "更新内容："
	notes_title.add_theme_font_size_override("font_size", 16)
	notes_title.add_theme_color_override("font_color", Color(0.842, 0.816, 0.756))
	vbox.add_child(notes_title)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 140)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var notes_label = Label.new()
	notes_label.text = str(update_info.get("releaseNotes", "优化游戏体验"))
	notes_label.add_theme_font_size_override("font_size", 14)
	notes_label.add_theme_color_override("font_color", Color(0.734, 0.714, 0.657))
	notes_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	notes_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	notes_label.custom_minimum_size = Vector2(440, 0)
	scroll.add_child(notes_label)

	progress_bar = ProgressBar.new()
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.value = 0
	progress_bar.custom_minimum_size = Vector2(0, 25)
	progress_bar.visible = false
	vbox.add_child(progress_bar)

	status_label = Label.new()
	status_label.text = ""
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	status_label.visible = false
	vbox.add_child(status_label)

	btn_container = HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_container)

	update_btn = Button.new()
	update_btn.text = "立即更新"
	update_btn.custom_minimum_size = Vector2(130, 50)
	update_btn.add_theme_font_size_override("font_size", 18)
	_apply_primary_button_style(update_btn)
	update_btn.pressed.connect(_on_update_pressed)
	btn_container.add_child(update_btn)

	quit_btn = Button.new()
	quit_btn.text = "退出游戏"
	quit_btn.custom_minimum_size = Vector2(130, 50)
	quit_btn.add_theme_font_size_override("font_size", 18)
	_apply_secondary_button_style(quit_btn)
	quit_btn.pressed.connect(_on_quit_pressed)
	btn_container.add_child(quit_btn)

	window.popup_centered()


func set_progress(fraction: float, status_text: String) -> void :
	if progress_bar:
		progress_bar.visible = true
		progress_bar.value = clampf(fraction * 100.0, 0.0, 100.0)
		progress_bar.indeterminate = fraction > 0.0 and fraction < 0.86 and "下载" in status_text
	if status_label:
		status_label.visible = true
		status_label.text = status_text


func show_failure(error_text: String) -> void :
	is_downloading = false
	if progress_bar:
		progress_bar.indeterminate = false
	if status_label:
		status_label.visible = true
		status_label.text = "更新失败: " + error_text
		status_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	if update_btn:
		update_btn.visible = true
		update_btn.disabled = false
		update_btn.text = "重试"
	if quit_btn:
		quit_btn.visible = true
		quit_btn.disabled = false


func show_success_and_wait(success_text: String = "") -> void :
	if progress_bar:
		progress_bar.visible = true
		progress_bar.indeterminate = false
		progress_bar.value = 100
	if status_label:
		status_label.visible = true
		if success_text.is_empty():
			status_label.text = "更新完成！正在重启游戏..."
		else:
			status_label.text = success_text
		status_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	if btn_container:
		btn_container.visible = false
	await get_tree().create_timer(0.5).timeout
	update_completed.emit()


func _on_update_pressed() -> void :
	if is_downloading:
		return
	is_downloading = true
	if update_btn:
		update_btn.disabled = true
	if quit_btn:
		quit_btn.disabled = true
	if progress_bar:
		progress_bar.visible = true
		progress_bar.value = 0
	if status_label:
		status_label.visible = true
		status_label.text = "准备下载..."
		status_label.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
	download_requested.emit()


func _on_quit_pressed() -> void :
	quit_requested.emit()


func _on_close_requested() -> void :
	quit_requested.emit()


func _apply_primary_button_style(btn: Button) -> void :
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.072, 0.080, 0.079)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", style)

	var hover_style = style.duplicate()
	hover_style.bg_color = Color(0.072, 0.080, 0.079)
	btn.add_theme_stylebox_override("hover", hover_style)

	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))


func _apply_secondary_button_style(btn: Button) -> void :
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.072, 0.080, 0.079)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.788, 0.635, 0.294)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", style)

	var hover_style = style.duplicate()
	hover_style.bg_color = Color(0.072, 0.080, 0.079)
	btn.add_theme_stylebox_override("hover", hover_style)

	btn.add_theme_color_override("font_color", Color(0.842, 0.816, 0.756))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
