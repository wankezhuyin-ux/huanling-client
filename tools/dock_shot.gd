extends SceneTree
# 底栏（BottomNav）单独预览脚本：不登录、不连服务器，只把底栏渲染出来截图。
# 用来核对底栏图标的字号 / 字体 / 与图标的垂直间距。
#
# 用法：
#   Godot --path . --resolution 720x1280 --script tools/dock_shot.gd -- --out=/tmp/dock.png

var _out := "/tmp/dock.png"


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out = a.substr(6)
	DisplayServer.window_set_size(Vector2i(720, 1280))
	await process_frame
	await process_frame

	var scene: PackedScene = load("res://ui/main_ui.tscn")
	if scene == null:
		printerr("[dock] 载入 ui/main_ui.tscn 失败")
		quit(1)
		return
	var n: Node = scene.instantiate()
	get_root().add_child(n)
	if n is Control:
		(n as Control).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	await process_frame
	n.call("_apply_ink_chrome")
	await process_frame
	await process_frame

	var dock: Control = n.get_node_or_null("BottomNav")
	if dock == null:
		printerr("[dock] 找不到 BottomNav")
		quit(1)
		return
	var r: Rect2 = dock.get_global_rect()
	print("[dock] global_rect=", r, "  viewport=", get_root().get_visible_rect().size)

	# 打印每一格的图标底边与文字顶边，方便量化"间距"
	for item in ["BattleContainer", "CharacterContainer", "CityContainer", "PetContainer", "BagContainer"]:
		var cont: Control = dock.get_node_or_null("MainButtons/" + item) as Control
		if cont == null:
			cont = dock.get_node_or_null(item) as Control
		if cont == null:
			continue
		var btn: Control = cont.get_node_or_null(item.replace("Container", "Btn")) as Control
		var lab: Control = cont.get_node_or_null(item.replace("Container", "Label")) as Control
		if btn != null and lab != null:
			var gap := lab.get_global_rect().position.y - btn.get_global_rect().end.y
			print("[dock] %-20s btn=%s label=%s gap=%.1f" % [
				item, str(btn.get_global_rect()), str(lab.get_global_rect()), gap])

	await process_frame
	var img := get_root().get_texture().get_image()
	if img == null:
		printerr("[dock] 拿不到画面")
		quit(2)
		return
	var rect := Rect2i(Vector2i(r.position), Vector2i(r.size))
	var clamped := rect.intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	var sub := img.get_region(clamped)
	sub.save_png(_out)
	print("[dock] 已保存 ", _out, "  ", sub.get_width(), "x", sub.get_height())
	quit(0)
