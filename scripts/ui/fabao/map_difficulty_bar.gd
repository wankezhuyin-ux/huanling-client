extends RefCounted
class_name MapDifficultyBar

const FabaoConfigRef = preload("res://scripts/fabao/fabao_config.gd")
const FabaoApiRef = preload("res://scripts/fabao/fabao_api.gd")


static func create(parent: Control) -> Control:
	var wrap: = VBoxContainer.new()
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.add_theme_constant_override("separation", 6)
	var title: = Label.new()
	title.text = "野外难度"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(title)
	var grid: = GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	wrap.add_child(grid)
	var style_n: = StyleBoxFlat.new()
	style_n.bg_color = Color(0.15, 0.18, 0.25, 0.95)
	style_n.set_corner_radius_all(8)
	style_n.set_border_width_all(1)
	style_n.border_color = Color(0.3, 0.4, 0.5, 0.8)
	var style_p: = StyleBoxFlat.new()
	style_p.bg_color = Color(0.28, 0.32, 0.18, 1)
	style_p.set_corner_radius_all(8)
	style_p.set_border_width_all(2)
	style_p.border_color = Color(1, 0.84, 0.25, 1)
	var style_d: = style_n.duplicate()
	style_d.bg_color = Color(0.12, 0.12, 0.14, 0.7)
	style_d.border_color = Color(0.25, 0.25, 0.28, 0.5)
	var grp: = ButtonGroup.new()
	var reinc: = 0
	var noble: = 0
	var cur: = "normal"
	if GameManager.instance and GameManager.instance.player:
		reinc = int(GameManager.instance.player.reincarnation)
	if GameManager.instance:
		noble = maxi(0, int(GameManager.instance.noble_level))
	if GameManager.instance and GameManager.instance.fabao_manager:
		cur = GameManager.instance.fabao_manager.current_difficulty
	var btns: Array = []
	for i in range(FabaoConfigRef.TIER_IDS.size()):
		var tid: String = FabaoConfigRef.TIER_IDS[i]
		var btn: = Button.new()
		var bonus: = FabaoConfigRef.map_exp_bonus_pct(tid)
		if bonus > 0:
			btn.text = "%s +%d%%" % [FabaoConfigRef.TIER_NAMES[i], bonus]
		else:
			btn.text = FabaoConfigRef.TIER_NAMES[i]
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(0, 40)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 15)
		btn.toggle_mode = true
		btn.button_group = grp
		var unlocked: = FabaoConfigRef.is_tier_unlocked(tid, reinc, noble)
		if unlocked:
			btn.add_theme_stylebox_override("normal", style_n)
			btn.add_theme_stylebox_override("hover", style_n)
			btn.add_theme_stylebox_override("pressed", style_p)
		else:
			btn.add_theme_stylebox_override("normal", style_d)
			btn.add_theme_stylebox_override("hover", style_d)
			btn.add_theme_stylebox_override("pressed", style_d)
		btn.set_meta("tier_id", tid)
		btn.set_meta("unlocked", unlocked)
		_paint_btn(btn, tid == cur, unlocked)
		var captured: = tid
		btn.pressed.connect( func():
			if not btn.button_pressed:
				return
			if not bool(btn.get_meta("unlocked", false)):
				var now: = "normal"
				if GameManager.instance and GameManager.instance.fabao_manager:
					now = GameManager.instance.fabao_manager.current_difficulty
				_sync_pressed(btns, now)
				_show_locked_tip(wrap, captured)
				return
			FabaoApiRef.set_difficulty(captured)
		)
		grid.add_child(btn)
		btns.append(btn)
	wrap.set_meta("diff_btns", btns)
	_sync_pressed(btns, cur)
	if GameManager.instance and GameManager.instance.fabao_manager:
		var fm = GameManager.instance.fabao_manager
		var on_diff: = func(tier_id: String):
			if not is_instance_valid(wrap):
				return
			_sync_pressed(btns, FabaoConfigRef.normalize_tier(tier_id))
		fm.difficulty_changed.connect(on_diff)
		wrap.tree_exiting.connect( func():
			if is_instance_valid(fm) and fm.difficulty_changed.is_connected(on_diff):
				fm.difficulty_changed.disconnect(on_diff)
		)
	parent.add_child(wrap)
	return wrap


static func _paint_btn(btn: Button, selected: bool, unlocked: bool) -> void :
	if not unlocked:
		btn.add_theme_color_override("font_color", Color(0.45, 0.45, 0.48))
		btn.add_theme_color_override("font_hover_color", Color(0.45, 0.45, 0.48))
		btn.add_theme_color_override("font_pressed_color", Color(0.45, 0.45, 0.48))
		return
	if selected:
		btn.add_theme_color_override("font_color", Color(1, 0.92, 0.45))
		btn.add_theme_color_override("font_hover_color", Color(1, 0.95, 0.6))
		btn.add_theme_color_override("font_pressed_color", Color(1, 0.95, 0.45))
	else:
		btn.add_theme_color_override("font_color", Color(0.82, 0.84, 0.88))
		btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
		btn.add_theme_color_override("font_pressed_color", Color(1, 0.92, 0.45))


static func _show_locked_tip(host: Control, tier_id: String) -> void :
	var msg: = FabaoConfigRef.unlock_hint(tier_id)
	var n: Node = host
	while n:
		if n.has_method("_show_simple_dialog"):
			n._show_simple_dialog("难度未解锁", msg)
			return
		n = n.get_parent()
	if GameManager.instance and GameManager.instance.fabao_manager:
		GameManager.instance.fabao_manager.request_failed.emit(msg)


static func _sync_pressed(btns: Array, cur: String) -> void :
	var tid: = FabaoConfigRef.normalize_tier(cur)
	for b in btns:
		if not (b is Button) or not is_instance_valid(b):
			continue
		var btn: Button = b
		var id: = str(btn.get_meta("tier_id", "normal"))
		var unlocked: = bool(btn.get_meta("unlocked", true))
		var sel: = id == tid
		if btn.toggle_mode:
			btn.set_pressed_no_signal(sel and unlocked)
		_paint_btn(btn, sel, unlocked)
