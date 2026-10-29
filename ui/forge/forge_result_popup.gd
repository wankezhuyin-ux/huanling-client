extends RefCounted
class_name ForgeResultPopup

const UIStyle = preload("res://scripts/ui_style.gd")
const ForgeConfig = preload("res://scripts/forge/forge_config.gd")

static func show_popup(parent: Control, result: Dictionary) -> Window:
	var popup = Window.new()
	popup.title = ""
	popup.borderless = true
	popup.transparent = true
	popup.unresizable = true
	popup.min_size = Vector2(400, 350)
	popup.size = Vector2(400, 350)

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	popup.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 15)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "✨ 锻造成功 ✨"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(title)

	var details = result.get("details", {})

	var transfer_label = Label.new()
	transfer_label.text = "%s +%d (%.1f%%)" % [
		ForgeConfig.get_attr_name(details.get("transfer_attr", "")), 
		details.get("transfer_value", 0), 
		details.get("transfer_rate", 0) * 100
	]
	transfer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	transfer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	transfer_label.add_theme_font_size_override("font_size", 20)
	transfer_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	vbox.add_child(transfer_label)

	var cost_label = Label.new()
	cost_label.text = "%s -%d (代价)" % [
		ForgeConfig.get_attr_name(details.get("cost_attr", "")), 
		details.get("cost_value", 0)
	]
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cost_label.add_theme_font_size_override("font_size", 18)
	cost_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.4))
	vbox.add_child(cost_label)

	var remaining_label = Label.new()
	remaining_label.text = "剩余空间: %d" % details.get("remaining_space", 0)
	remaining_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	remaining_label.add_theme_font_size_override("font_size", 16)
	remaining_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	vbox.add_child(remaining_label)

	var close_btn = Button.new()
	close_btn.text = "确定"
	close_btn.custom_minimum_size = Vector2(120, 45)
	UIStyle.apply_golden_button_style(close_btn)
	close_btn.pressed.connect( func(): popup.queue_free())
	vbox.add_child(close_btn)

	var scene_root = Engine.get_main_loop().current_scene
	if scene_root:
		scene_root.add_child(popup)
		popup.popup_centered()
	else:
		parent.add_child(popup)
		popup.popup_centered()

	return popup
