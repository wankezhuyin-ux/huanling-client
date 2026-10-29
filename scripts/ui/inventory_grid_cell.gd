extends RefCounted
class_name InventoryGridCell



# 格子底比面板再深一层（设计稿是"墨里挖的坑"，不是格子浮起来）
const CELL_BG: = Color(0.030, 0.026, 0.019, 0.80)
const CELL_BG_EMPTY: = Color(0.020, 0.018, 0.013, 0.52)
const CELL_BORDER_EMPTY: = Color(0.788, 0.635, 0.294, 0.30)
const CELL_BORDER_NORMAL: = Color(0.788, 0.635, 0.294, 0.34)

const EQUIP_SLOT_BORDER: = Color(0.92, 0.74, 0.28, 1.0)
const NAME_H: = 34
const CORNER: = 0
const FONT_NAME: = 16
const FONT_COUNT: = 18
const FONT_BADGE: = 13
const FONT_ENHANCE: = 17


static func make_empty(side: int, name_under: String = "", border_color: Color = CELL_BORDER_EMPTY) -> Control:
	var wrap: = VBoxContainer.new()
	_lock_cell_width(wrap, side, side + NAME_H)
	wrap.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_theme_constant_override("separation", 2)

	var btn: = Button.new()
	btn.custom_minimum_size = Vector2(side, side)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	btn.focus_mode = Control.FOCUS_NONE
	btn.text = ""
	btn.disabled = true
	btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_btn(btn, true, border_color)
	wrap.add_child(btn)

	var name_lbl: = Label.new()
	name_lbl.text = name_under
	name_lbl.add_theme_font_size_override("font_size", FONT_NAME)
	# 空槽位底下的名字（武器/头盔/防具…）原来偏冷灰、在墨底上几乎看不见
	name_lbl.add_theme_color_override("font_color", Color(0.66, 0.63, 0.56))
	wrap.add_child(_setup_cell_name_label(name_lbl, side))
	return wrap


static func make_filled(
		side: int, 
		tex: Texture2D, 
		display_name: String, 
		count: int, 
		border_color: Color, 
		on_tap: Callable, 
		icon_modulate: Color = Color.WHITE, 
		show_count: bool = true, 
		tooltip: String = "", 
		fill_tight: bool = false, 
		badge_text: String = "", 
		tr_badge_text: String = ""
	) -> Control:
	var wrap: = VBoxContainer.new()
	_lock_cell_width(wrap, side, side + NAME_H)
	wrap.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_theme_constant_override("separation", 2)

	var slot: = Control.new()
	slot.custom_minimum_size = Vector2(side, side)
	slot.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	slot.clip_contents = true
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(slot)

	var btn: = Button.new()
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.focus_mode = Control.FOCUS_NONE
	btn.text = ""
	_style_btn(btn, false, border_color)
	if not tooltip.is_empty():
		btn.tooltip_text = tooltip
	if on_tap.is_valid():
		TouchScrollUtils.bind_tap(btn, on_tap)
	slot.add_child(btn)

	if tex != null:
		var icon: = TextureRect.new()
		icon.texture = tex
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

		if fill_tight:
			icon.stretch_mode = TextureRect.STRETCH_SCALE
			icon.offset_left = 2
			icon.offset_top = 2
			icon.offset_right = -2
			icon.offset_bottom = -2
		else:
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.offset_left = 5
			icon.offset_top = 5
			icon.offset_right = -5
			icon.offset_bottom = -5
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.modulate = icon_modulate
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		slot.add_child(icon)


	slot.add_child(_make_border_overlay(border_color, 2))

	if not badge_text.is_empty():
		var badge: = Label.new()
		badge.text = badge_text
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_theme_font_size_override("font_size", FONT_BADGE)
		badge.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		badge.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		badge.add_theme_constant_override("outline_size", 2)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.position = Vector2(3, 3)
		badge.size = Vector2(22, 16)
		var badge_bg: = ColorRect.new()
		badge_bg.color = Color(0.05, 0.05, 0.08, 0.72)
		badge_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge_bg.position = Vector2(2, 2)
		badge_bg.size = Vector2(24, 18)
		slot.add_child(badge_bg)
		slot.add_child(badge)

	if not tr_badge_text.is_empty():
		var tr_w: = 36
		var tr_h: = 24
		var tr_badge_bg: = ColorRect.new()
		tr_badge_bg.color = Color(0.05, 0.05, 0.08, 0.72)
		tr_badge_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr_badge_bg.position = Vector2(side - tr_w - 2, 2)
		tr_badge_bg.size = Vector2(tr_w, tr_h)
		var tr_badge: = Label.new()
		tr_badge.text = tr_badge_text
		tr_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tr_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tr_badge.add_theme_font_size_override("font_size", FONT_ENHANCE)
		tr_badge.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		tr_badge.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
		tr_badge.add_theme_constant_override("outline_size", 3)
		tr_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr_badge.position = Vector2(side - tr_w - 1, 3)
		tr_badge.size = Vector2(tr_w - 2, tr_h - 2)
		slot.add_child(tr_badge_bg)
		slot.add_child(tr_badge)

	# 底部压暗：数量一般落在图案最花的地方，先垫一条渐变再写字，
	# 否则只靠描黑边会被亮橙色的物品图吃掉（设计稿的角标也是这么做的）
	if tex != null:
		slot.add_child(_make_bottom_scrim(side))

	if show_count and count > 0:
		var cnt: = Label.new()
		cnt.text = str(count)
		cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cnt.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		cnt.add_theme_font_size_override("font_size", FONT_COUNT)
		cnt.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		cnt.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		cnt.add_theme_constant_override("outline_size", 3)
		cnt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		cnt.offset_right = -4
		cnt.offset_bottom = -2
		cnt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(cnt)

	var name_lbl: = Label.new()
	name_lbl.text = InventoryIconHelper.short_name(display_name, 6)
	name_lbl.add_theme_font_size_override("font_size", FONT_NAME)
	name_lbl.add_theme_color_override("font_color", Color(0.92, 0.92, 0.95))
	wrap.add_child(_setup_cell_name_label(name_lbl, side))
	return wrap


## 格子底部 45% 的墨色渐变，给数量/角标垫底
static func _make_bottom_scrim(side: int) -> TextureRect:
	var g: = Gradient.new()
	g.set_color(0, Color(0.02, 0.018, 0.012, 0.0))
	g.set_color(1, Color(0.02, 0.018, 0.012, 0.62))
	g.add_point(0.55, Color(0.02, 0.018, 0.012, 0.22))
	var t: = GradientTexture2D.new()
	t.gradient = g
	t.width = 8
	t.height = 64
	t.fill_from = Vector2(0.0, 0.0)
	t.fill_to = Vector2(0.0, 1.0)
	var scrim: = TextureRect.new()
	scrim.texture = t
	scrim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scrim.stretch_mode = TextureRect.STRETCH_SCALE
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scrim.position = Vector2(0, side * 0.55)
	scrim.size = Vector2(side, side * 0.45)
	return scrim


static func _make_border_overlay(border_col: Color, border_w: int = 3) -> Panel:
	var frame: = Panel.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.z_index = 1
	var st: = StyleBoxFlat.new()
	st.bg_color = Color(0, 0, 0, 0)
	st.set_border_width_all(border_w)
	st.border_color = border_col
	st.set_corner_radius_all(CORNER)
	frame.add_theme_stylebox_override("panel", st)
	return frame


static func _style_btn(btn: Button, empty: bool, border_col: Color) -> void :
	# 墨底金线：直角、细边、极淡同色底。品质只靠边框色区分，不再发光，
	# 满屏格子一起发光会把整页糊成一团。
	var glow: = Color(border_col.r, border_col.g, border_col.b, 0.16)
	var bg: = CELL_BG_EMPTY if empty else CELL_BG.lerp(glow, 0.5)
	var s: = StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(1 if empty else 2)
	s.border_color = CELL_BORDER_EMPTY if empty else border_col
	s.set_corner_radius_all(CORNER)

	s.shadow_color = Color(border_col.r, border_col.g, border_col.b, 0.18) if not empty else Color(0, 0, 0, 0)
	s.shadow_size = 2 if not empty else 0
	s.content_margin_left = 0
	s.content_margin_top = 0
	s.content_margin_right = 0
	s.content_margin_bottom = 0
	btn.add_theme_stylebox_override("normal", s)
	var h: = s.duplicate() as StyleBoxFlat
	h.border_color = border_col.lightened(0.25) if not empty else Color(0.7, 0.75, 0.9)
	h.bg_color = bg.lightened(0.08)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", h)
	btn.add_theme_stylebox_override("disabled", s.duplicate())
	if empty:
		btn.add_theme_color_override("font_color", Color(0, 0, 0, 0))
		btn.add_theme_color_override("font_disabled_color", Color(0, 0, 0, 0))


static func _lock_cell_width(ctrl: Control, side: int, height: int) -> void :
	ctrl.custom_minimum_size = Vector2(side, height)
	ctrl.clip_contents = true


static func _setup_cell_name_label(name_lbl: Label, side: int) -> Control:

	var name_slot: = Control.new()
	name_slot.custom_minimum_size = Vector2(side, NAME_H - 2)
	name_slot.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	name_slot.clip_contents = true
	name_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.max_lines_visible = 1
	name_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_slot.add_child(name_lbl)
	return name_slot


static func calc_cell_side(available_width: float, cols: int, gap: float = 8.0, min_side: int = 56, max_side: int = 160) -> int:
	if cols <= 0:
		return min_side
	var usable: = available_width - float(cols - 1) * gap - 8.0
	var side: = int(usable / float(cols))
	if max_side > 0:
		return clampi(side, min_side, max_side)
	return maxi(side, min_side)



static func calc_bag_cell_side(available_width: float, cols: int = 6, gap: float = 8.0) -> int:
	return calc_cell_side(available_width, cols, gap, 56, 0)


static func make_grid(cols: int, gap: int = 8) -> GridContainer:
	var grid: = GridContainer.new()
	grid.columns = cols
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.add_theme_constant_override("h_separation", gap)
	grid.add_theme_constant_override("v_separation", gap)
	return grid
