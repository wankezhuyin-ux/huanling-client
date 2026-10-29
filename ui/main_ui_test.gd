
extends Control

func _ready():
	print("[TEST] 测试脚本加载")

func show_test_popup(title: String, poem: String, result_text: String, callback: Callable):
	print("[TEST] show_test_popup 开始执行")


	var test_overlay = ColorRect.new()
	test_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	test_overlay.color = Color(1, 0, 0, 0.5)
	test_overlay.z_index = 9999

	var label = Label.new()
	label.text = "测试弹窗 - " + title
	label.add_theme_font_size_override("font_size", 30)
	label.set_anchors_preset(Control.PRESET_CENTER)
	test_overlay.add_child(label)

	get_tree().root.add_child(test_overlay)
	print("[TEST] 红色测试遮罩已添加")


	await get_tree().create_timer(3.0).timeout
	test_overlay.queue_free()
	print("[TEST] 测试遮罩已关闭")

	if callback.is_valid():
		callback.call()
