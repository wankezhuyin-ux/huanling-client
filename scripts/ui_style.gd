extends RefCounted

## 全局 UI 调色板（水墨皮）。原来整套是蓝灰/亮蓝，是所有"残留旧版控件"的源头：
## 面板、按钮、页签、道具底都从这里取色，改这里等于全项目一起换皮。
## 金 = 0.788/0.635/0.294，墨底 = 0.098/0.086/0.063（暖墨 #191610，对齐设计稿），纸白 = 0.925/0.898/0.840。
## 注：老墨底是冷青 0.047/0.058/0.062，实测与设计稿差 ×1.87 明度 + 色相偏青，已整体换暖。
const COLORS = {
	panel_bg = Color(0.098, 0.086, 0.063, 0.96),

	panel_border = Color(0.788, 0.635, 0.294, 0.55),

	title_color = Color(1.0, 0.85, 0.45),
	text_normal = Color(0.925, 0.898, 0.840),
	text_dim = Color(0.640, 0.615, 0.560),

	button_normal = Color(0.075, 0.066, 0.050, 0.85),
	button_hover = Color(0.135, 0.120, 0.095, 0.95),
	button_pressed = Color(0.788, 0.635, 0.294, 0.28),
	button_border = Color(0.788, 0.635, 0.294, 0.55),
	button_border_hover = Color(0.788, 0.635, 0.294, 0.95),

	tab_active = Color(0.788, 0.635, 0.294, 0.18),
	tab_inactive = Color(0.098, 0.086, 0.063, 0.60),
	tab_border_active = Color(0.788, 0.635, 0.294, 0.90),
	tab_border_inactive = Color(0.788, 0.635, 0.294, 0.25),

	rank_gold = Color(0.30, 0.25, 0.10, 0.80),
	rank_silver = Color(0.22, 0.22, 0.21, 0.80),
	rank_bronze = Color(0.24, 0.17, 0.11, 0.80),
	rank_normal = Color(0.070, 0.060, 0.045, 0.60),

	action_btn = Color(0.075, 0.066, 0.050, 0.72),
	action_btn_hover = Color(0.788, 0.635, 0.294, 0.26),
	action_btn_border = Color(0.788, 0.635, 0.294, 0.70),

	item_bg = Color(0.055, 0.047, 0.035, 0.66),
	item_border = Color(0.788, 0.635, 0.294, 0.26),
}

static func create_panel_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = COLORS.panel_bg
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = COLORS.panel_border
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	return style


const POPUP_BUTTON_SIZE: = Vector2(120, 44)

## 弹窗外壳：水墨宣纸语言 —— 墨底、1px 金线、直角、纯黑投影。
## 原版是蓝灰 3px 描边 + 15px 大圆角，和整包水墨皮不是一套东西。
## 这里改默认值就等于全项目弹窗一起换皮（31 处调用点都走这个工厂）。
static func create_popup_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.098, 0.086, 0.063, 0.96)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1

	style.border_color = Color(0.788, 0.635, 0.294, 0.62)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 12
	return style

## 金属包边弹窗的「底」：比 create_popup_style 更沉、更实、投影更重。
## 边框本身不靠这里画（1px 太细 = 用户说的"单薄"），由 ui/metal_frame.gd 叠一圈
## 4px 斜面 + 铆钉的金属框；这里只负责：
##   · 更深的墨底（0.062/0.052/0.038）—— 4px 金框压在 0.098 的暖墨上会显脏
##   · 1px 暗铁外描边，让金属框和背后的画面之间有一道硬边
##   · 投影 7px / 偏移 (0,3) / 黑 0.30，只做"离地"的暗示，不再糊一圈重黑边
## 注意：投影是画在面板矩形外面的，所以调用方必须把面板相对 Window 内缩（见 METAL_PAD），
## 否则投影会被 Window 边界裁掉，等于白加。
static func create_metal_popup_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	# 底板 70% 不透明：既压得住背后的水墨图保证文字可读，又能透出一点景深
	style.bg_color = Color(0.062, 0.052, 0.038, 0.70)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.075, 0.058, 0.032, 1.0)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	# 投影收薄：7px / 黑 0.30 / 下移 3，只做"离地一点"的暗示，不再糊一圈黑边
	style.shadow_color = Color(0, 0, 0, 0.30)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 3)
	return style


## 金属弹窗里的「内嵌信息板」：比面板底色更暗，1px 暗金细框，用来装等级/金币这类数据。
static func create_metal_inset_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.030, 0.026, 0.020, 0.55)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.596, 0.443, 0.169, 0.30)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	return style


static func create_popup_button_style(is_confirm: bool = true) -> StyleBoxFlat:
	# 确认键描金、取消键描灰（不带色彩倾向，避免和朱砂的"危险"撞车）
	var style = StyleBoxFlat.new()
	if is_confirm:
		style.bg_color = Color(0.055, 0.068, 0.072, 0.72)
		style.border_color = Color(0.788, 0.635, 0.294, 0.72)
	else:
		style.bg_color = Color(0.043, 0.052, 0.055, 0.60)
		style.border_color = Color(0.72, 0.70, 0.64, 0.34)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	return style


static func style_popup_button(btn: Button, is_confirm: bool = true, min_size: Vector2 = POPUP_BUTTON_SIZE) -> void :
	if btn == null:
		return
	btn.custom_minimum_size = min_size
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color(0.925, 0.898, 0.840))
	var normal: = create_popup_button_style(is_confirm)
	var hover: = normal.duplicate() as StyleBoxFlat
	hover.bg_color = normal.bg_color.lightened(0.08)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("disabled", create_popup_button_style(is_confirm))

static func create_button_style(is_hover: bool = false, is_pressed: bool = false) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	if is_pressed:
		style.bg_color = COLORS.button_pressed
		style.border_color = COLORS.button_border
	elif is_hover:
		style.bg_color = COLORS.button_hover
		style.border_color = COLORS.button_border_hover
	else:
		style.bg_color = COLORS.button_normal
		style.border_color = COLORS.button_border
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	return style

static func apply_button_style(btn: Button):
	var normal_style = create_button_style(false, false)
	var hover_style = create_button_style(true, false)
	var pressed_style = create_button_style(false, true)
	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", pressed_style)

static func create_tab_style(is_active: bool = false) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	if is_active:
		style.bg_color = COLORS.tab_active
		style.border_color = COLORS.tab_border_active
	else:
		style.bg_color = COLORS.tab_inactive
		style.border_color = COLORS.tab_border_inactive
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	return style

static func apply_tab_style(btn: Button, is_active: bool):
	var style = create_tab_style(is_active)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)

static func create_rank_style(rank: int) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	match rank:
		0: style.bg_color = COLORS.rank_gold
		1: style.bg_color = COLORS.rank_silver
		2: style.bg_color = COLORS.rank_bronze
		_: style.bg_color = COLORS.rank_normal
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style

static func create_action_button_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = COLORS.action_btn
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = COLORS.action_btn_border
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	return style

static func apply_action_button_style(btn: Button):
	var normal_style = create_action_button_style()
	var hover_style = create_action_button_style()
	hover_style.bg_color = COLORS.action_btn_hover
	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", hover_style)

## 主操作键（原橙色渐变块，全套二级页面 30+ 处调用）。
## 水墨里"主"是靠金线密度和墨底厚度表达的，不靠高饱和填充：
## 这里用比次级键更亮的金线（0.85）+ 极淡金底，扫一眼就知道是这一屏该按的键。
static func create_orange_action_button_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.072, 0.062, 0.045, 0.86)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.788, 0.635, 0.294, 0.85)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	return style

static func apply_orange_action_button_style(btn: Button):
	var normal_style = create_orange_action_button_style()
	var hover_style = create_orange_action_button_style()
	hover_style.bg_color = Color(0.788, 0.635, 0.294, 0.26)
	hover_style.border_color = Color(0.788, 0.635, 0.294, 1.0)
	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", hover_style)
	btn.add_theme_color_override("font_color", Color(0.960, 0.870, 0.660))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.945, 0.820))
	btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.945, 0.820))

static func create_muted_noble_claim_button_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.085, 0.088, 0.082, 0.80)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.62, 0.59, 0.52, 0.55)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	return style

static func apply_muted_noble_claim_button_style(btn: Button) -> void :
	var st: = create_muted_noble_claim_button_style()
	var st_hover = create_muted_noble_claim_button_style()
	st_hover.bg_color = Color(0.115, 0.120, 0.110, 0.92)
	btn.add_theme_stylebox_override("normal", st)
	btn.add_theme_stylebox_override("hover", st_hover)
	btn.add_theme_stylebox_override("pressed", st_hover)
	btn.add_theme_color_override("font_color", Color(0.78, 0.75, 0.68))
	btn.add_theme_color_override("font_hover_color", Color(0.90, 0.87, 0.79))
	btn.add_theme_color_override("font_pressed_color", Color(0.72, 0.69, 0.62))
	btn.add_theme_color_override("font_disabled_color", Color(0.50, 0.48, 0.43))

static func create_golden_button_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.092, 0.076, 0.044, 0.90)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.788, 0.635, 0.294, 0.92)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 2)
	return style

static func apply_golden_button_style(btn: Button):
	var normal_style = create_golden_button_style()
	var hover_style = create_golden_button_style()
	hover_style.bg_color = Color(0.788, 0.635, 0.294, 0.28)
	hover_style.border_color = Color(0.920, 0.780, 0.430, 1)
	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", hover_style)
	btn.add_theme_color_override("font_color", Color(0.960, 0.870, 0.660))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.945, 0.820))

static func create_item_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = COLORS.item_bg
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = COLORS.item_border
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	return style

static func create_selectable_item_style(is_selected: bool = false) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	if is_selected:
		style.bg_color = Color(0.105, 0.086, 0.047, 0.92)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.788, 0.635, 0.294, 0.95)
	else:
		style.bg_color = Color(0.040, 0.050, 0.052, 0.80)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.788, 0.635, 0.294, 0.24)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	return style

static func create_title_label(text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", COLORS.title_color)
	return label

static func create_close_button() -> Button:
	var btn = Button.new()
	btn.text = "关闭"
	btn.custom_minimum_size = Vector2(0, 40)
	btn.add_theme_font_size_override("font_size", 18)
	apply_button_style(btn)
	return btn

static func create_window(_parent: Node, size: Vector2 = Vector2(600, 700)) -> Window:
	var window = Window.new()
	window.title = ""
	window.size = size
	window.borderless = true
	window.transparent = true
	window.unresizable = true
	window.always_on_top = true

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", create_panel_style())
	window.add_child(panel)

	return window

static func create_base_vbox() -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 10)
	return vbox



static func animate_button_click(btn: Button):
	if not btn or not btn.is_inside_tree():
		return
	var tween = btn.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(btn, "scale", Vector2(0.95, 0.95), 0.05)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)

static func animate_window_popup(window: Window):
	if not window or not window.is_inside_tree():
		return
	var panel = window.get_child(0) as Control
	if panel:
		panel.modulate.a = 0.0
		panel.scale = Vector2(0.9, 0.9)
		var tween = panel.create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_parallel(true)
		tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.2)
		tween.tween_property(panel, "modulate:a", 1.0, 0.15)

static func animate_window_close(window: Window, callback: Callable = Callable()):
	if not window or not window.is_inside_tree():
		return
	var panel = window.get_child(0) as Control
	if panel:
		var tween = panel.create_tween()
		tween.set_ease(Tween.EASE_IN)
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_parallel(true)
		tween.tween_property(panel, "scale", Vector2(0.9, 0.9), 0.15)
		tween.tween_property(panel, "modulate:a", 0.0, 0.15)
		if callback.is_valid():
			tween.tween_callback(callback)
		else:
			tween.tween_callback(window.queue_free)
	else:
		if callback.is_valid():
			callback.call()
		else:
			window.queue_free()

static func animate_fade_in(control: Control, duration: float = 0.2):
	if not control or not control.is_inside_tree():
		return
	control.modulate.a = 0.0
	var tween = control.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(control, "modulate:a", 1.0, duration)

static func animate_fade_out(control: Control, duration: float = 0.2, callback: Callable = Callable()):
	if not control or not control.is_inside_tree():
		return
	var tween = control.create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(control, "modulate:a", 0.0, duration)
	if callback.is_valid():
		tween.tween_callback(callback)

static func animate_slide_in(control: Control, from_direction: String = "left", duration: float = 0.25):
	if not control or not control.is_inside_tree():
		return
	var original_pos = control.position
	var offset = 50.0
	match from_direction:
		"left":
			control.position.x -= offset
		"right":
			control.position.x += offset
		"top":
			control.position.y -= offset
		"bottom":
			control.position.y += offset
	control.modulate.a = 0.0
	var tween = control.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_parallel(true)
	tween.tween_property(control, "position", original_pos, duration)
	tween.tween_property(control, "modulate:a", 1.0, duration)

static func animate_scale_in(control: Control, duration: float = 0.2):
	if not control or not control.is_inside_tree():
		return
	control.scale = Vector2(0.5, 0.5)
	control.modulate.a = 0.0
	var tween = control.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_parallel(true)
	tween.tween_property(control, "scale", Vector2(1.0, 1.0), duration)
	tween.tween_property(control, "modulate:a", 1.0, duration * 0.5)

static func animate_pulse(control: Control, scale_amount: float = 1.1, duration: float = 0.3):
	if not control or not control.is_inside_tree():
		return
	var original_scale = control.scale
	var tween = control.create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(control, "scale", original_scale * scale_amount, duration * 0.5)
	tween.tween_property(control, "scale", original_scale, duration * 0.5)

static func animate_shake(control: Control, intensity: float = 5.0, duration: float = 0.3):
	if not control or not control.is_inside_tree():
		return
	var original_pos = control.position
	var tween = control.create_tween()
	var shake_count = 4
	var shake_duration = duration / shake_count
	for i in shake_count:
		var offset = Vector2(randf_range( - intensity, intensity), randf_range( - intensity, intensity))
		tween.tween_property(control, "position", original_pos + offset, shake_duration * 0.5)
		tween.tween_property(control, "position", original_pos, shake_duration * 0.5)

static func animate_number_label(label: Label, from_value: int, to_value: int, duration: float = 0.5, prefix: String = "", suffix: String = ""):
	if not label or not label.is_inside_tree():
		return
	var tween = label.create_tween()
	tween.tween_method(
		_update_number_label.bind(label, prefix, suffix), 
		from_value, to_value, duration
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

static func _update_number_label(val: float, label: Label, prefix: String, suffix: String):
	label.text = prefix + str(int(val)) + suffix

static func animate_item_appear(item: Control, delay: float = 0.0, duration: float = 0.25):
	if not item or not item.is_inside_tree():
		return
	item.modulate.a = 0.0
	item.scale = Vector2(0.9, 0.9)
	var tween = item.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	if delay > 0:
		tween.tween_interval(delay)
	tween.set_parallel(true)
	tween.tween_property(item, "modulate:a", 1.0, duration)
	tween.tween_property(item, "scale", Vector2(1.0, 1.0), duration)

static func setup_button_animation(btn: Button):
	if not btn:
		return
	btn.pressed.connect( func(): animate_button_click(btn))
