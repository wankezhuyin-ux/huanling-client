extends RefCounted
class_name ConfirmDialog

const UIStyle = preload("res://scripts/ui_style.gd")

const POPUP_WIDTH: = 380
const POPUP_HEIGHT: = 320

static func _resolve_host_size(host: Control) -> Vector2:
	var size: = host.size
	if size.x <= 1.0 or size.y <= 1.0:
		size = host.get_viewport_rect().size
	if size.x <= 1.0 or size.y <= 1.0:
		return Vector2(720.0, 1280.0)
	return size

static func _center_in_size(area: Vector2, popup: Panel) -> void :
	popup.position = Vector2(
		maxf(8.0, (area.x - POPUP_WIDTH) * 0.5), 
		maxf(8.0, (area.y - POPUP_HEIGHT) * 0.5)
	)

static func _center_popup(host: Control, popup: Panel, layer_size: Vector2 = Vector2.ZERO) -> void :
	var size: = layer_size
	if size.x <= 1.0 or size.y <= 1.0:
		size = _resolve_host_size(host)
	_center_in_size(size, popup)

static func _layout_top_level_layer(host: Control, layer: Control) -> void :
	var vp_rect: = host.get_viewport().get_visible_rect()
	layer.set_anchors_preset(Control.PRESET_TOP_LEFT)
	layer.position = vp_rect.position
	layer.size = vp_rect.size

static func _fill_confirm_layer(layer: Control, popup: Panel, area: Vector2) -> void :
	var dim: = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.04, 0.08, 0.68)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.z_index = 0
	layer.add_child(dim)
	popup.custom_minimum_size = Vector2(POPUP_WIDTH, POPUP_HEIGHT)
	popup.size = Vector2(POPUP_WIDTH, POPUP_HEIGHT)
	popup.mouse_filter = Control.MOUSE_FILTER_STOP
	popup.z_index = 1
	layer.add_child(popup)
	_center_in_size(area, popup)
	popup.set_meta("confirm_dialog_layer", layer)
	dim.gui_input.connect( func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_close_popup(popup)
	)

static func _attach_popup(parent: Node, popup: Panel) -> void :
	if parent is Window:
		var win: = parent as Window
		if not is_instance_valid(win):
			return
		var layer: = Control.new()
		layer.name = "ConfirmDialogLayer"
		layer.mouse_filter = Control.MOUSE_FILTER_STOP
		layer.z_index = 4096
		layer.set_anchors_preset(Control.PRESET_FULL_RECT)
		win.add_child(layer)
		var area: = Vector2(win.size)
		if area.x <= 1.0 or area.y <= 1.0:
			area = Vector2(POPUP_WIDTH + 40, POPUP_HEIGHT + 40)
		layer.size = area
		_fill_confirm_layer(layer, popup, area)
		return
	var host: = parent as Control
	if host == null:
		parent.add_child(popup)
		return
	var overlay: = Control.new()
	overlay.name = "ConfirmDialogLayer"
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.top_level = true
	overlay.z_index = 4096
	overlay.z_as_relative = false
	host.add_child(overlay)
	_layout_top_level_layer(host, overlay)
	_fill_confirm_layer(overlay, popup, overlay.size)

static func _close_popup(popup: Panel) -> void :
	var layer = popup.get_meta("confirm_dialog_layer", null)
	if layer is Node and is_instance_valid(layer):
		layer.queue_free()
	elif is_instance_valid(popup):
		popup.queue_free()

static func _style_popup_button(btn: Button, is_confirm: bool) -> void :
	UIStyle.style_popup_button(btn, is_confirm)

static func _build_popup_shell(title: String, message: String) -> Dictionary:
	var popup: = Panel.new()
	popup.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	var vbox: = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 22
	vbox.offset_top = 20
	vbox.offset_right = -22
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 14)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	popup.add_child(vbox)
	var title_label: = Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.custom_minimum_size = Vector2(POPUP_WIDTH - 44, 0)
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color(1, 0.85, 0.35))
	vbox.add_child(title_label)
	var scroll: = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	TouchScrollUtils.configure_scroll(scroll)
	var msg_label: = Label.new()
	msg_label.text = message
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_label.custom_minimum_size = Vector2(POPUP_WIDTH - 44, 0)
	msg_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	msg_label.add_theme_font_size_override("font_size", 16)
	msg_label.add_theme_color_override("font_color", Color(0.9, 0.93, 1.0))
	scroll.add_child(msg_label)
	TouchScrollUtils.bind_content_touch_scroll(scroll, msg_label)
	return {"popup": popup, "vbox": vbox}

static func _add_button_row(vbox: VBoxContainer, buttons: Array) -> void :
	var btn_hbox: = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 16)
	btn_hbox.size_flags_vertical = Control.SIZE_SHRINK_END
	vbox.add_child(btn_hbox)
	for btn in buttons:
		if btn is Button:
			btn_hbox.add_child(btn)

static func show(parent: Node, title: String, message: String, on_confirm: Callable, 
		confirm_text: String = "确定", cancel_text: String = "取消", 
		_window_size: Vector2 = Vector2(400, 250)) -> Panel:
	var built: = _build_popup_shell(title, message)
	var popup: Panel = built.popup
	var vbox: VBoxContainer = built.vbox
	var cancel_btn: = Button.new()
	cancel_btn.text = cancel_text
	_style_popup_button(cancel_btn, false)
	cancel_btn.pressed.connect( func(): _close_popup(popup))
	var confirm_btn: = Button.new()
	confirm_btn.text = confirm_text
	_style_popup_button(confirm_btn, true)
	confirm_btn.pressed.connect( func():
		_close_popup(popup)
		if on_confirm.is_valid():
			on_confirm.call()
	)
	_add_button_row(vbox, [cancel_btn, confirm_btn])
	_attach_popup(parent, popup)
	return popup

static func style_button(btn: Button, is_confirm: bool = true) -> void :
	_style_popup_button(btn, is_confirm)

static func show_message(parent: Node, title: String, message: String, confirm_text: String = "确定", on_confirm: Callable = Callable()) -> Panel:
	var built: = _build_popup_shell(title, message)
	var popup: Panel = built.popup
	var vbox: VBoxContainer = built.vbox
	var ok_btn: = Button.new()
	ok_btn.text = confirm_text
	_style_popup_button(ok_btn, true)
	ok_btn.pressed.connect( func():
		_close_popup(popup)
		if on_confirm.is_valid():
			on_confirm.call()
	)
	_add_button_row(vbox, [ok_btn])
	_attach_popup(parent, popup)
	return popup
