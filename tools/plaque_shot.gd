extends SceneTree
# 主城吊牌（plaque_*.png）预览脚本：不登录、不连服务器，只把水墨主城渲染出来截图。
# 用来核对「竖排字与上方小胶囊的间距」「各块牌子的字重是否统一」。
#
# 用法：
#   Godot --path . --resolution 720x1280 --script tools/plaque_shot.gd -- --out=/tmp/plaque_city.png

var _out := "/tmp/plaque_city.png"


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out = a.substr(6)
	DisplayServer.window_set_size(Vector2i(720, 1280))
	await process_frame
	await process_frame

	var scene: PackedScene = load("res://ui/main_ui.tscn")
	if scene == null:
		printerr("[plaque] 载入 ui/main_ui.tscn 失败")
		quit(1)
		return
	var n: Node = scene.instantiate()
	get_root().add_child(n)
	if n is Control:
		(n as Control).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	await process_frame
	n.call("_apply_ink_chrome")
	# 多等几帧：CityInkLayer 的 bind 是在 resized 里算的
	for i in range(6):
		await process_frame
	await create_timer(0.35).timeout

	var img := get_root().get_texture().get_image()
	if img == null:
		printerr("[plaque] 拿不到画面")
		quit(2)
		return
	img.save_png(_out)
	print("[plaque] 已保存 ", _out, "  ", img.get_width(), "x", img.get_height())
	quit(0)
