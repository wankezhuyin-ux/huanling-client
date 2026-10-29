extends Control
class_name GangWarLogPanel

const UIStyle = preload("res://scripts/ui_style.gd")
const GangWarReport = preload("res://scripts/gang/gang_war_report.gd")

var log_container: VBoxContainer
var _scroll: ScrollContainer
var _scroll_gen: int = 0

func _init() -> void :
	var panel: = Panel.new()
	panel.add_theme_stylebox_override("panel", UIStyle.create_item_style())
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	var margin: = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	_scroll = ScrollContainer.new()
	_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	TouchScrollUtils.configure_scroll(_scroll)
	margin.add_child(_scroll)
	log_container = VBoxContainer.new()
	log_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_container.add_theme_constant_override("separation", 5)
	_scroll.add_child(log_container)
	TouchScrollUtils.bind_content_touch_scroll(_scroll, log_container)

func set_entries(entries: Array) -> void :
	for c in log_container.get_children():
		c.queue_free()
	for e in entries:
		if not e is Dictionary:
			continue
		var lbl: = Label.new()
		lbl.text = GangWarReport.activity_line_text(e)
		lbl.add_theme_color_override("font_color", GangWarReport.activity_line_color(e))
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.custom_minimum_size = Vector2(0, 0)
		lbl.add_theme_font_size_override("font_size", 14)
		log_container.add_child(lbl)
	TouchScrollUtils.enable_touch_drag_passthrough(log_container)
	_request_scroll_to_latest()

func _request_scroll_to_latest() -> void :
	_scroll_gen += 1
	if is_inside_tree():
		_scroll_to_latest_async(_scroll_gen)
	elif not tree_entered.is_connected(_on_tree_entered_scroll_latest):
		tree_entered.connect(_on_tree_entered_scroll_latest, CONNECT_ONE_SHOT)

func _on_tree_entered_scroll_latest() -> void :
	_scroll_to_latest_async(_scroll_gen)

func _scroll_to_latest_async(gen: int) -> void :
	if not is_inside_tree():
		return
	var tree: = get_tree()
	if tree == null:
		return
	await tree.process_frame
	if gen != _scroll_gen:
		return
	_apply_scroll_to_latest()
	await tree.process_frame
	if gen != _scroll_gen:
		return
	_apply_scroll_to_latest()

func _apply_scroll_to_latest() -> void :
	if not is_instance_valid(_scroll) or not is_instance_valid(log_container):
		return
	var last: Control = null
	for c in log_container.get_children():
		if c is Control and is_instance_valid(c) and not c.is_queued_for_deletion():
			last = c as Control
	if last == null:
		return
	_scroll.ensure_control_visible(last)
	var vbar: = _scroll.get_v_scroll_bar()
	if vbar:
		_scroll.scroll_vertical = int(vbar.max_value)
