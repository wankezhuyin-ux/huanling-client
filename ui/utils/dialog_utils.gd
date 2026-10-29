extends Node
class_name DialogUtils

static func create_base_window(title: String, size: Vector2) -> Window:
	var window = Window.new()
	window.title = title
	window.size = size
	window.borderless = true
	window.transparent = true
	window.unresizable = true
	window.close_requested.connect( func(): window.queue_free())
	return window

static func create_panel() -> Panel:
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	return panel

static func create_vbox(margins: Vector4 = Vector4(20, 20, 20, 20)) -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = margins.x
	vbox.offset_top = margins.y
	vbox.offset_right = - margins.z
	vbox.offset_bottom = - margins.w
	return vbox

static func create_hbox(separation: int = 10) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", separation)
	return hbox

static func create_label(text: String, font_size: int = 16, color: Color = Color.WHITE) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	if color != Color.WHITE:
		label.add_theme_color_override("font_color", color)
	return label

static func create_title_label(text: String, font_size: int = 24) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

static func create_button(text: String, min_size: Vector2 = Vector2(100, 40), font_size: int = 16) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = min_size
	btn.add_theme_font_size_override("font_size", font_size)
	return btn

static func create_scroll_container() -> ScrollContainer:
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return scroll
