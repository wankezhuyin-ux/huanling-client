extends RefCounted


const POPUP_CANVAS_LAYER: = 100

static func _resolve_popup_host(fallback_control: Control, tree: SceneTree = null) -> Node:
	var scene_tree: = tree
	if scene_tree == null and fallback_control != null and fallback_control.is_inside_tree():
		scene_tree = fallback_control.get_tree()
	if scene_tree == null or scene_tree.root == null:
		if fallback_control != null and fallback_control.is_inside_tree():
			return fallback_control.get_window()
		return null
	var existing = scene_tree.root.find_child("ModalCanvasLayer", true, false)
	if existing != null and is_instance_valid(existing):
		return existing
	var layer: = CanvasLayer.new()
	layer.name = "ModalCanvasLayer"
	layer.layer = POPUP_CANVAS_LAYER
	scene_tree.root.add_child(layer)
	return layer

static func attach_window_and_popup_centered(dialog: Window, fallback_control: Control) -> void :
	var host: Node = _resolve_popup_host(fallback_control)
	if host == null:
		push_error("[WindowHost] 无法挂载结果窗口：Control 不在树内或无 root")
		dialog.queue_free()
		return
	if dialog.get_parent():
		dialog.get_parent().remove_child(dialog)
	dialog.always_on_top = true
	host.add_child(dialog)
	dialog.call_deferred("popup_centered")
	if dialog.has_method("move_to_foreground"):
		dialog.call_deferred("move_to_foreground")



static func attach_window_to_scene_root(dialog: Window, tree: SceneTree) -> void :
	var host: Node = _resolve_popup_host(null, tree)
	if host == null:
		push_error("[WindowHost] attach_window_to_scene_root: 无效 SceneTree")
		dialog.queue_free()
		return
	if dialog.get_parent():
		dialog.get_parent().remove_child(dialog)
	dialog.always_on_top = true
	host.add_child(dialog)
	dialog.call_deferred("popup_centered")
	if dialog.has_method("move_to_foreground"):
		dialog.call_deferred("move_to_foreground")
