extends RefCounted
class_name TouchScrollUtils






const SCROLL_DEADZONE: = 20
const TAP_SLOP_PX: = 18.0


static func configure_scroll(scroll: ScrollContainer, disable_horizontal: bool = true) -> void :
	if scroll == null:
		return
	scroll.scroll_deadzone = SCROLL_DEADZONE
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	if disable_horizontal:
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED



static func enable_touch_drag_passthrough(root: Control) -> void :
	if root == null or not is_instance_valid(root):
		return
	var root_keep: = _touch_passthrough_keep_input(root)
	if not root_keep:
		root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in root.get_children():
		if not (child is Control):
			continue
		var c: = child as Control
		if not _touch_passthrough_keep_input(c):
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		enable_touch_drag_passthrough(c)


static func _touch_passthrough_keep_input(c: Control) -> bool:
	return (c is BaseButton) or (c is LineEdit) or (c is TextEdit) or (c is OptionButton) or (c is ScrollContainer) or (c is CheckBox)



static func bind_content_touch_scroll(scroll: ScrollContainer, content: Control) -> void :
	if scroll == null or content == null:
		return
	configure_scroll(scroll)
	content.mouse_filter = Control.MOUSE_FILTER_STOP
	content.focus_mode = Control.FOCUS_NONE
	if bool(content.get_meta("_tsu_scroll_bound", false)):
		return
	content.set_meta("_tsu_scroll_bound", true)
	content.set_meta("_tsu_pressing", false)
	content.set_meta("_tsu_dragged", false)
	content.set_meta("_tsu_press_global", Vector2.ZERO)
	content.gui_input.connect(_on_content_scroll_gui_input.bind(content, scroll))


static func _on_content_scroll_gui_input(event: InputEvent, content: Control, scroll: ScrollContainer) -> void :
	if not is_instance_valid(content) or not is_instance_valid(scroll):
		return
	var slop: = TAP_SLOP_PX

	if event is InputEventScreenTouch:
		var st: = event as InputEventScreenTouch
		if st.pressed:
			content.set_meta("_tsu_pressing", true)
			content.set_meta("_tsu_dragged", false)
			content.set_meta("_tsu_press_global", content.get_global_mouse_position())
		else:
			content.set_meta("_tsu_pressing", false)
		content.accept_event()
		return

	if event is InputEventScreenDrag:
		var sd: = event as InputEventScreenDrag
		_scroll_content_drag(content, scroll, sd.relative, slop)
		content.accept_event()
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mb: = event as InputEventMouseButton
		if mb.pressed:
			content.set_meta("_tsu_pressing", true)
			content.set_meta("_tsu_dragged", false)
			content.set_meta("_tsu_press_global", content.get_global_mouse_position())
		else:
			content.set_meta("_tsu_pressing", false)
		return

	if event is InputEventMouseMotion:
		var mm: = event as InputEventMouseMotion
		if bool(content.get_meta("_tsu_pressing", false)):
			_scroll_content_drag(content, scroll, mm.relative, slop)


static func _scroll_content_drag(content: Control, scroll: ScrollContainer, relative: Vector2, slop: float) -> void :
	if not bool(content.get_meta("_tsu_pressing", false)):
		return
	var press_pos: Vector2 = content.get_meta("_tsu_press_global", Vector2.ZERO)
	var now: = content.get_global_mouse_position()
	if not bool(content.get_meta("_tsu_dragged", false)):
		if press_pos.distance_to(now) <= slop:
			return
		content.set_meta("_tsu_dragged", true)
	scroll.scroll_vertical = scroll.scroll_vertical - int(round(relative.y))
	scroll.scroll_horizontal = scroll.scroll_horizontal - int(round(relative.x))



static func bind_tap(control: Control, on_tap: Callable) -> void :
	if control == null or not on_tap.is_valid():
		return
	control.mouse_filter = Control.MOUSE_FILTER_STOP
	control.set_meta("_tsu_pressing", false)
	control.set_meta("_tsu_dragged", false)
	control.set_meta("_tsu_press_global", Vector2.ZERO)
	control.set_meta("_tsu_on_tap", on_tap)
	if bool(control.get_meta("_tsu_bound", false)):
		return
	control.set_meta("_tsu_bound", true)
	control.gui_input.connect(_on_control_gui_input.bind(control))


static func _on_control_gui_input(event: InputEvent, control: Control) -> void :
	if not is_instance_valid(control):
		return
	var slop: = TAP_SLOP_PX

	if event is InputEventScreenTouch:
		var st: = event as InputEventScreenTouch
		if st.pressed:
			_begin_press(control, control.get_global_mouse_position())
		else:
			_end_press(control, control.get_global_mouse_position(), slop)
		return

	if event is InputEventScreenDrag:
		var sd: = event as InputEventScreenDrag
		_handle_drag(control, sd.position, sd.relative, slop)
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mb: = event as InputEventMouseButton
		if mb.pressed:
			_begin_press(control, control.get_global_mouse_position())
		else:
			_end_press(control, control.get_global_mouse_position(), slop)
		return

	if event is InputEventMouseMotion:
		var mm: = event as InputEventMouseMotion
		if bool(control.get_meta("_tsu_pressing", false)):
			_handle_drag(control, control.get_global_mouse_position(), mm.relative, slop)


static func _begin_press(control: Control, global_pos: Vector2) -> void :
	control.set_meta("_tsu_pressing", true)
	control.set_meta("_tsu_dragged", false)
	control.set_meta("_tsu_press_global", global_pos)


static func _end_press(control: Control, global_pos: Vector2, slop: float) -> void :
	if not bool(control.get_meta("_tsu_pressing", false)):
		return
	control.set_meta("_tsu_pressing", false)
	var dragged: = bool(control.get_meta("_tsu_dragged", false))
	var press_pos: Vector2 = control.get_meta("_tsu_press_global", global_pos)
	if not dragged and press_pos.distance_to(global_pos) <= slop:
		var on_tap: Callable = control.get_meta("_tsu_on_tap", Callable())
		if on_tap.is_valid():
			on_tap.call()


static func _handle_drag(control: Control, _local_or_global: Vector2, relative: Vector2, slop: float) -> void :
	if not bool(control.get_meta("_tsu_pressing", false)):
		return
	var press_pos: Vector2 = control.get_meta("_tsu_press_global", Vector2.ZERO)
	var now: = control.get_global_mouse_position()
	if not bool(control.get_meta("_tsu_dragged", false)):
		if press_pos.distance_to(now) <= slop:
			return
		control.set_meta("_tsu_dragged", true)
	var scroll: = find_parent_scroll(control)
	if scroll:
		scroll.scroll_vertical = scroll.scroll_vertical - int(round(relative.y))
		scroll.scroll_horizontal = scroll.scroll_horizontal - int(round(relative.x))
	control.accept_event()


static func find_parent_scroll(node: Node) -> ScrollContainer:
	var n: Node = node
	while n:
		if n is ScrollContainer:
			return n as ScrollContainer
		n = n.get_parent()
	return null
